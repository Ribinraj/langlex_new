import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langlex_new_app/core/local_storage.dart';
import 'package:langlex_new_app/core/network_services.dart';
import 'package:langlex_new_app/core/urls.dart';
import 'progress_models.dart';

/// Account-scoped durable outbox. An accepted event can safely be sent again.
class ProgressStore extends ChangeNotifier with WidgetsBindingObserver {
  ProgressStore(this._dio) {
    WidgetsBinding.instance.addObserver(this);
  }
  final Dio _dio;
  LearningProgressOverview? overview;
  bool loading = false;
  String? error;
  int pending = 0;
  int needsAttention = 0;
  String? _language;
  int? _account;
  bool _disposed = false;
  Future<void> _work = Future.value();
  Future<void>? _refreshing;
  Timer? _retry;
  Timer? _expiry;
  final _sessions = <String, String>{};
  String _key(String type, String key) => '$type/$key';
  static String eventId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<T> _exclusive<T>(Future<T> Function() work) {
    final result = _work.then((_) => work());
    _work = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<int?> _owner() async => (await LocalStorage.getUser())?.id;
  Future<void> bindAccount() async {
    final id = await _owner();
    if (id == _account) return;
    _account = id;
    overview = null;
    error = null;
    pending = 0;
    needsAttention = 0;
    _language = null;
    _sessions.clear();
    if (id != null) {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('learning_progress_sessions_$id');
      if (saved != null) {
        _sessions.addAll(Map<String, String>.from(jsonDecode(saved) as Map));
      }
      for (final event in await _queue(id)) {
        final data = event['data'] as Map;
        final session = data['next_session_id'] ?? data['session_id'];
        if (session != null) {
          _sessions[_key('${data['content_type']}', '${data['content_key']}')] =
              '$session';
        }
      }
    }
    _retry?.cancel();
    _expiry?.cancel();
    _notify();
  }

  Future<void> rememberSession(
    String type,
    String key,
    Map<String, dynamic> data,
  ) async {
    final metadata = data['metadata'];
    if (metadata is Map && metadata['session_id'] != null) {
      _sessions[_key(type, key)] = '${metadata['session_id']}';
    }
    final id = _account;
    if (id != null) {
      final snapshot = jsonEncode(_sessions);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('learning_progress_sessions_$id', snapshot);
    }
  }

  // The JWT subject check prevents a token/user storage change from sending one
  // account's queued events with another account's credentials. The server still
  // verifies the token signature and authorizes every request.
  Future<String?> _tokenFor(int id) async {
    final token = await LocalStorage.getAccessToken();
    try {
      final claims =
          jsonDecode(
                utf8.decode(
                  base64Url.decode(base64Url.normalize(token.split('.')[1])),
                ),
              )
              as Map;
      if ('${claims['sub']}' != '$id' || await _owner() != id) return null;
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> readSession(String type, String key) =>
      _exclusive(() async {
        await bindAccount();
        final id = _account;
        if (id != null) await _flush(id, await _queue(id));
        final token = id == null ? null : await _tokenFor(id);
        if (id != null && token == null) throw StateError('Session changed');
        final response = await _dio.get<Map<String, dynamic>>(
          Endpoints.contentProgress,
          queryParameters: {'content_type': type, 'content_key': key},
          options: token == null
              ? null
              : Options(
                  headers: {'Authorization': 'Bearer $token'},
                  extra: {DioClient.skipAuthKey: true},
                ),
        );
        if (await _owner() != id || _disposed) {
          throw StateError('Session changed');
        }
        final result = Map<String, dynamic>.from(
          response.data?['progress'] as Map? ?? {},
        );
        await rememberSession(type, key, result);
        return result;
      });

  Future<List<Map<String, dynamic>>> _queue(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('learning_progress_outbox_$id');
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _saveQueue(int id, List<Map<String, dynamic>> queue) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      'learning_progress_outbox_$id',
      jsonEncode(queue),
    )) {
      throw StateError('Could not save progress on this device.');
    }
    if (_account == id) {
      pending = queue.length;
      needsAttention = queue.where((e) => e['blocked'] == true).length;
      _notify();
    }
  }

  Future<Map<String, dynamic>> submit(
    String path,
    String method,
    Map<String, dynamic> payload,
  ) async {
    final requestedOwner = await _owner();
    return _exclusive(() async {
      if (await _owner() != requestedOwner) throw StateError('Session changed');
      await bindAccount();
      final id = _account;
      final type = '${payload['content_type']}',
          key = '${payload['content_key']}';
      final data = <String, dynamic>{...payload, 'event_id': eventId()};
      if (path == Endpoints.contentProgressRestart) {
        data['next_session_id'] = eventId();
        _sessions[_key(type, key)] = '${data['next_session_id']}';
      } else {
        data['session_id'] = _sessions[_key(type, key)] ?? 'legacy';
      }
      // Without a local account there is no safe owner for an offline event.
      if (id == null) {
        final response = await _dio.request<Map<String, dynamic>>(
          path,
          data: data,
          options: Options(method: method),
        );
        final result = Map<String, dynamic>.from(
          response.data?['progress'] as Map? ?? {},
        );
        await rememberSession(type, key, result);
        return result;
      }
      final queue = await _queue(id);
      queue.add({'path': path, 'method': method, 'data': data});
      await _saveQueue(id, queue);
      final result = await _flush(id, queue, target: '${data['event_id']}');
      return result ??
          {
            'content_type': type,
            'content_key': key,
            'metadata': {'pending_sync': true},
          };
    });
  }

  Future<Map<String, dynamic>?> _flush(
    int id,
    List<Map<String, dynamic>> queue, {
    String? target,
  }) async {
    Map<String, dynamic>? result;
    for (final event in List<Map<String, dynamic>>.from(queue)) {
      if (await _owner() != id || _disposed) break;
      final token = await _tokenFor(id);
      if (token == null) break;
      try {
        final response = await _dio.request<Map<String, dynamic>>(
          '${event['path']}',
          data: event['data'],
          options: Options(
            method: '${event['method']}',
            headers: {'Authorization': 'Bearer $token'},
            extra: {DioClient.skipAuthKey: true},
          ),
        );
        final data = Map<String, dynamic>.from(
          response.data?['progress'] as Map? ?? {},
        );
        if ((event['data'] as Map)['event_id'] == target) result = data;
        // Only the newest queued session may become the local session.
        if (await _owner() == id &&
            _account == id &&
            !queue.any(
              (e) =>
                  e != event &&
                  e['path'] == Endpoints.contentProgressRestart &&
                  (e['data'] as Map)['content_key'] ==
                      (event['data'] as Map)['content_key'],
            )) {
          await rememberSession(
            '${(event['data'] as Map)['content_type']}',
            '${(event['data'] as Map)['content_key']}',
            data,
          );
        }
        queue.remove(event);
        await _saveQueue(id, queue);
      } on DioException catch (failure) {
        final code = failure.response?.statusCode;
        if (code != null &&
            code >= 400 &&
            code < 500 &&
            code != 401 &&
            code != 429) {
          event['blocked'] =
              true; // Keep rejected work visible and isolated from valid later events.
          await _saveQueue(id, queue);
          continue;
        }
        break;
      }
    }
    if (_account == id && !_disposed) {
      await _saveQueue(id, queue);
      _retry?.cancel();
      if (queue.any((event) => event['blocked'] != true)) {
        _retry = Timer(const Duration(seconds: 30), () {
          refresh(_language);
        });
      }
    }
    return result;
  }

  Future<void> refresh([String? language]) {
    if (_refreshing != null) {
      return _refreshing!.then((_) async {
        if (language != null && overview?.language != language && !_disposed) {
          await refresh(language);
        }
      });
    }
    final future = _refresh(language);
    _refreshing = future;
    return future.whenComplete(() => _refreshing = null);
  }

  Future<void> _refresh(String? language) async {
    await bindAccount();
    final owner = _account;
    final requested = language ?? _language;
    if (requested != _language) overview = null;
    _language = requested;
    loading = true;
    error = null;
    _notify();
    try {
      if (owner != null) {
        await _exclusive(() async => _flush(owner, await _queue(owner)));
      }
      final token = owner == null ? null : await _tokenFor(owner);
      if (owner != null && token == null) throw StateError('Session changed');
      final response = await _dio.get<Map<String, dynamic>>(
        Endpoints.learningProgress,
        options: token == null
            ? null
            : Options(
                headers: {'Authorization': 'Bearer $token'},
                extra: {DioClient.skipAuthKey: true},
              ),
        queryParameters: {'language': ?requested},
      );
      if (await _owner() != owner || _disposed) return;
      final raw = response.data?['progress'];
      if (raw is! Map || !raw.containsKey('total_items')) {
        throw const FormatException('Progress unavailable');
      }
      overview = LearningProgressOverview.fromJson(
        Map<String, dynamic>.from(raw),
      );
      _language = overview!.language;
      _expiry?.cancel();
      final expiry = DateTime.tryParse('${raw['expires_at']}');
      if (expiry != null && expiry.isAfter(DateTime.now())) {
        _expiry = Timer(
          expiry.difference(DateTime.now()) + const Duration(seconds: 1),
          () => refresh(_language),
        );
      }
    } catch (_) {
      if (owner == _account) {
        error = 'Could not update progress. Your saved work is safe.';
      }
    } finally {
      if (!_disposed) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> ensureLoaded(String language) async {
    await bindAccount();
    if (_account == null) return;
    if (overview?.language != language && !loading && error == null) {
      await refresh(language);
    }
  }

  void invalidate() {
    overview = null;
    error = null;
    _notify();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh(_language);
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _expiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
