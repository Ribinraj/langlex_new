import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/pages/phonics_practice_page.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Completer<void>? pendingSource;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final name in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    await AudioPlayer.global.ensureInitialized();
  });

  setUp(() {
    calls.clear();
    pendingSource = null;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        calls.add(call);
        final id = call.arguments['playerId'];
        if (call.method == 'create') {
          messenger.setMockMethodCallHandler(
            MethodChannel('xyz.luan/audioplayers/events/$id'),
            (_) async => null,
          );
        }
        if (call.method == 'setSourceUrl') {
          await pendingSource?.future;
          messenger.handlePlatformMessage(
            'xyz.luan/audioplayers/events/$id',
            const StandardMethodCodec().encodeSuccessEnvelope({
              'event': 'audio.onPrepared',
              'value': true,
            }),
            (_) {},
          );
        }
        return null;
      },
    );
  });

  List<String> sources() => calls
      .where((call) => call.method == 'setSourceUrl')
      .map((call) => call.arguments['url'] as String)
      .toList();

  Widget button({bool active = true, String name = 'cat'}) => MaterialApp(
    home: Scaffold(
      body: LearningAudioButton(
        path: 'https://example.com/$name-sound.mp3',
        autoplayPath: 'https://example.com/$name-name.mp3',
        active: active,
      ),
    ),
  );

  // Playing audio schedules position updates every frame, so settling is not
  // appropriate while the mocked player remains active.
  Future<void> pumpAudio(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Widget storyClips({bool includeFirst = true}) => MaterialApp(
    home: Scaffold(
      body: Row(
        children: [
          if (includeFirst)
            const LearningAudioButton(
              key: ValueKey('first'),
              path: 'https://example.com/story-1.mp3',
              tooltip: 'Part one',
            ),
          const LearningAudioButton(
            key: ValueKey('second'),
            path: 'https://example.com/story-2.mp3',
            tooltip: 'Part two',
          ),
          const LearningAudioButton(
            key: ValueKey('third'),
            path: 'https://example.com/story-3.mp3',
            tooltip: 'Part three',
          ),
        ],
      ),
    ),
  );

  testWidgets(
    'starting the next story clip stops the old clip before playback',
    (tester) async {
      await tester.pumpWidget(storyClips());
      await tester.tap(find.byTooltip('Part one'));
      await pumpAudio(tester);
      final firstId = calls
          .singleWhere((c) => c.method == 'setSourceUrl')
          .arguments['playerId'];
      final firstResume = calls.indexWhere(
        (c) => c.method == 'resume' && c.arguments['playerId'] == firstId,
      );
      expect(firstResume, greaterThanOrEqualTo(0));
      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
      await tester.tap(find.byTooltip('Part two'));
      await pumpAudio(tester);
      final secondId = calls
          .lastWhere((c) => c.method == 'setSourceUrl')
          .arguments['playerId'];
      final oldStop = calls.lastIndexWhere(
        (c) => c.method == 'stop' && c.arguments['playerId'] == firstId,
      );
      final nextResume = calls.indexWhere(
        (c) => c.method == 'resume' && c.arguments['playerId'] == secondId,
      );
      expect(oldStop, greaterThan(firstResume));
      expect(nextResume, greaterThan(oldStop));
      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
      // Removing an older button must not interrupt the currently selected clip.
      final beforeRemoval = calls.length;
      await tester.pumpWidget(storyClips(includeFirst: false));
      await pumpAudio(tester);
      expect(
        calls
            .skip(beforeRemoval)
            .where(
              (c) => c.method == 'stop' && c.arguments['playerId'] == secondId,
            ),
        isEmpty,
      );
      messenger.handlePlatformMessage(
        'xyz.luan/audioplayers/events/$secondId',
        const StandardMethodCodec().encodeSuccessEnvelope({
          'event': 'audio.onComplete',
        }),
        (_) {},
      );
      await pumpAudio(tester);
      expect(find.byIcon(Icons.graphic_eq_rounded), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpAudio(tester);
      expect(
        calls.any(
          (c) => c.method == 'stop' && c.arguments['playerId'] == secondId,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'rapid story selections cannot revive an older slow-loading clip',
    (tester) async {
      await tester.pumpWidget(storyClips());
      final slowSource = Completer<void>();
      pendingSource = slowSource;
      await tester.tap(find.byTooltip('Part one'));
      await pumpAudio(tester);
      final firstId = calls
          .singleWhere((c) => c.method == 'setSourceUrl')
          .arguments['playerId'];
      pendingSource = null;
      await tester.tap(find.byTooltip('Part two'));
      await tester.tap(find.byTooltip('Part three'));
      await pumpAudio(tester);
      final thirdId = calls
          .lastWhere(
            (c) =>
                c.method == 'setSourceUrl' &&
                c.arguments['url'] == 'https://example.com/story-3.mp3',
          )
          .arguments['playerId'];
      expect(
        calls.where((c) => c.method == 'resume').last.arguments['playerId'],
        thirdId,
      );
      slowSource.complete();
      await pumpAudio(tester);
      expect(
        calls.where(
          (c) => c.method == 'resume' && c.arguments['playerId'] == firstId,
        ),
        isEmpty,
      );
      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpAudio(tester);
    },
  );

  testWidgets('muting app effects persists and leaves lesson audio playing', (
    tester,
  ) async {
    await LearningAssetSound.initialize();
    expect(LearningAssetSound.enabled.value, isTrue);
    await LearningAssetSound.setEnabled(false);
    await LearningAssetSound.playTap();
    await LearningAssetSound.playNavTab(0);
    await LearningAssetSound.playQuizCorrect();
    expect(calls, isEmpty);
    await LearningAssetSound.initialize();
    expect(LearningAssetSound.enabled.value, isFalse);
    await tester.pumpWidget(button());
    await pumpAudio(tester);
    expect(sources(), ['https://example.com/cat-name.mp3']);
    await tester.tap(find.byType(IconButton));
    await pumpAudio(tester);
    expect(sources().last, 'https://example.com/cat-sound.mp3');
    await LearningAssetSound.setEnabled(true);
    expect(LearningAssetSound.enabled.value, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('opening speaks the name and Listen replaces it with the sound', (
    tester,
  ) async {
    await tester.pumpWidget(button());
    await pumpAudio(tester);
    expect(sources(), ['https://example.com/cat-name.mp3']);
    await tester.tap(find.byType(IconButton));
    await pumpAudio(tester);
    expect(sources(), [
      'https://example.com/cat-name.mp3',
      'https://example.com/cat-sound.mp3',
    ]);
    final playbackCalls = calls
        .where((c) => ['stop', 'setSourceUrl', 'resume'].contains(c.method))
        .toList();
    final sourceIndex = playbackCalls.lastIndexWhere(
      (c) => c.method == 'setSourceUrl',
    );
    expect(playbackCalls[sourceIndex - 1].method, 'stop');
    await tester.pumpWidget(const SizedBox());
    await pumpAudio(tester);
    expect(calls.any((c) => c.method == 'release'), isTrue);
  });

  testWidgets('only active cards speak, including when revisiting a card', (
    tester,
  ) async {
    await tester.pumpWidget(button(active: false));
    await pumpAudio(tester);
    expect(sources(), isEmpty);
    await tester.pumpWidget(button());
    await pumpAudio(tester);
    expect(sources().length, 1);
    await tester.pumpWidget(button());
    await pumpAudio(tester);
    expect(sources().length, 1);
    await tester.pumpWidget(button(active: false));
    await pumpAudio(tester);
    expect(calls.where((c) => c.method == 'stop').length, 2);
    await tester.pumpWidget(button());
    await pumpAudio(tester);
    expect(sources().length, 2);
    await tester.pumpWidget(button(name: 'dog'));
    await pumpAudio(tester);
    expect(sources().last, 'https://example.com/dog-name.mp3');
    await tester.pumpWidget(const SizedBox());
    await pumpAudio(tester);
  });

  testWidgets('a hidden card cannot start after a delayed audio load', (
    tester,
  ) async {
    pendingSource = Completer<void>();
    await tester.pumpWidget(button());
    await pumpAudio(tester);
    expect(sources().length, 1);
    await tester.pumpWidget(button(active: false));
    pendingSource!.complete();
    await pumpAudio(tester);
    expect(calls.any((c) => c.method == 'resume'), isFalse);
    await tester.pumpWidget(const SizedBox());
    await pumpAudio(tester);
  });

  testWidgets('Sounds speaks the resumed word and each newly visible word', (
    tester,
  ) async {
    final progressReady = Completer<void>();
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) async {
          if (request.method == 'GET') await progressReady.future;
          handler.resolve(
            Response(
              requestOptions: request,
              data: {
                'progress': {'position': 1},
              },
            ),
          );
        },
      ),
    );
    await tester.pumpWidget(
      RepositoryProvider.value(
        value: LearningRepository(dio),
        child: MaterialApp(
          builder: (context, child) {
            ResponsiveUtils().init(context);
            return child!;
          },
          home: PhonicsPracticePage(
            homeLanguage: 'English',
            phonics: List.generate(
              3,
              (i) => PhonicsItem.fromJson({
                'id': i + 1,
                'word': 'Word $i',
                'word_audio': 'https://example.com/word-$i.mp3',
                'sentence_sound': 'https://example.com/sentence-$i.mp3',
              }),
            ),
          ),
        ),
      ),
    );
    await pumpAudio(tester);
    expect(sources(), isEmpty);
    progressReady.complete();
    await pumpAudio(tester);
    expect(sources(), ['https://example.com/word-1.mp3']);
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await pumpAudio(tester);
    expect(sources().last, 'https://example.com/word-2.mp3');
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await pumpAudio(tester);
    expect(sources(), [
      'https://example.com/word-1.mp3',
      'https://example.com/word-2.mp3',
      'https://example.com/word-1.mp3',
    ]);
    await tester.pumpWidget(const SizedBox());
    await pumpAudio(tester);
    expect(tester.takeException(), isNull);
  });
}
