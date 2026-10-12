import 'package:langlex_new_app/core/widgets/app_empty_state.dart';
import 'package:langlex_new_app/features/learning/widgets/content_shimmers.dart';
import 'package:langlex_new_app/core/app_toast.dart';
import 'package:langlex_new_app/features/dashboard/widgets/flow_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/api_exception.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/notifications/models/app_notification.dart';
import 'package:langlex_new_app/features/notifications/notification_repo.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.homeLanguage});

  final String homeLanguage;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _scroll = ScrollController();
  final _items = <AppNotification>[];
  int _page = 0;
  int _generation = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _marking = false;
  Object? _error;

  AppLocalizations get t => AppLocalizations(widget.homeLanguage);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_checkMore);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _checkMore() {
    if (_scroll.hasClients &&
        _scroll.position.extentAfter < 250 &&
        _error == null) {
      _load();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (!refresh && (_loading || !_hasMore)) return;
    final generation = refresh ? ++_generation : _generation;
    final next = refresh ? 1 : _page + 1;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final inbox = await context
          .read<NotificationRepository>()
          .fetchNotifications(page: next);
      if (!mounted || generation != _generation) return;
      setState(() {
        if (refresh) _items.clear();
        final ids = _items.map((item) => item.id).toSet();
        _items.addAll(inbox.notifications.where((item) => ids.add(item.id)));
        _page = next;
        _hasMore = inbox.hasMore && inbox.notifications.isNotEmpty;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkMore();
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await context.read<NotificationRepository>().markRead(notification.id);
      if (!mounted) return;
      setState(() {
        final index = _items.indexWhere((item) => item.id == notification.id);
        if (index >= 0) _items[index] = _items[index].copyWith(isRead: true);
      });
    } catch (_) {
      if (mounted) {
        AppToast.error(context, t.retry);
      }
    }
  }

  Future<void> _markAllRead() async {
    if (_marking) return;
    setState(() => _marking = true);
    try {
      await context.read<NotificationRepository>().markAllRead();
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _items.length; i++) {
          _items[i] = _items[i].copyWith(isRead: true);
        }
      });
    } catch (_) {
      if (mounted) {
        AppToast.error(context, t.retry);
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.kscreenWarmBackground,

      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: FlowScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          header: FlowPageHeader(
            title: t.notifications,
            footer: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _marking ? null : _markAllRead,
                child: Text(t.markAllRead),
              ),
            ),
          ),
          slivers: [
            SliverPadding(
              padding: ResponsiveUtils.pagePadding(
                context,
                mobileHorizontalPercent: 6,
                tabletHorizontal: 42,
                desktopHorizontal: 56,
                top: 12,
                bottom: 34,
              ),
              sliver: SliverList.separated(
                itemCount: _items.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index < _items.length) {
                    return _NotificationTile(
                      notification: _items[index],
                      t: t,
                      onTap: () => _markRead(_items[index]),
                    );
                  }
                  if (_loading) {
                    return CatalogShimmer(
                      kind: CatalogSkeleton.notifications,
                      label: t.loading,
                      itemCount: _items.isEmpty ? 5 : 2,
                    );
                  }
                  if (_error != null) {
                    return _StatusPanel(
                      message: _error is ApiException
                          ? (_error as ApiException).message
                          : t.couldNotLoadLearningContent,
                      action: () => _load(),
                      t: t,
                    );
                  }
                  if (_items.isEmpty) {
                    return AppEmptyState(
                      kind: EmptyStateKind.notifications,
                      title: t.allCaughtUp,
                      message: t.emptyNotificationsHint,
                      actionLabel: Navigator.of(context).canPop()
                          ? t.goBack
                          : null,
                      onAction: Navigator.of(context).canPop()
                          ? () => Navigator.of(context).maybePop()
                          : null,
                    );
                  }
                  return const SizedBox(height: 16);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.t,
    required this.onTap,
  });

  final AppNotification notification;
  final AppLocalizations t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = notification.isRead
        ? Appcolors.kdashboardMutedText
        : Appcolors.kprimarycolor;

    return Material(
      color: Appcolors.ktransparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: notification.isRead
                  ? Appcolors.kauthDivider
                  : Appcolors.kprimarycolor.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  notification.isRead
                      ? Icons.notifications_none_rounded
                      : Icons.notifications_active_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ResponsiveText(
                            notification.title,
                            fontSize: 14.5,
                            weight: FontWeight.w900,
                            color: Appcolors.ktextdark,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ResponsiveText(
                          _relativeTime(notification.createdAt, t),
                          fontSize: 10.5,
                          weight: FontWeight.w800,
                          color: Appcolors.kdashboardMutedText,
                          maxLines: 1,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ResponsiveText(
                      notification.body,
                      fontSize: 12.5,
                      weight: FontWeight.w700,
                      color: Appcolors.kdashboardMutedText,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 10),
                    _StatusChip(
                      label: notification.isRead ? t.read : t.unread,
                      color: accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime createdAt, AppLocalizations t) {
    final elapsed = DateTime.now().difference(createdAt);
    if (elapsed.inMinutes < 1) return t.justNow;
    if (elapsed.inHours < 1) return t.minutesAgo(elapsed.inMinutes);
    if (elapsed.inDays < 1) return t.hoursAgo(elapsed.inHours);
    return t.daysAgo(elapsed.inDays);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ResponsiveText(
        label,
        fontSize: 10.5,
        weight: FontWeight.w900,
        color: color,
        maxLines: 1,
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.message,
    required this.action,
    required this.t,
  });

  final String message;
  final VoidCallback action;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ResponsiveText(
              message,
              fontSize: 14,
              weight: FontWeight.w800,
              color: Appcolors.kdashboardMutedText,
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: action, child: Text(t.retry)),
          ],
        ),
      ),
    );
  }
}
