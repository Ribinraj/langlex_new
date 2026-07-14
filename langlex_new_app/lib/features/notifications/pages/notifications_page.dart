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
  late Future<NotificationInbox> _future;

  AppLocalizations get t => AppLocalizations(widget.homeLanguage);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<NotificationInbox> _load() {
    return context.read<NotificationRepository>().fetchNotifications();
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.isRead) return;
    await context.read<NotificationRepository>().markRead(notification.id);
    _refresh();
  }

  Future<void> _markAllRead() async {
    await context.read<NotificationRepository>().markAllRead();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.kscreenWarmBackground,
      appBar: AppBar(
        title: Text(t.notifications),
        actions: [
          TextButton(onPressed: _markAllRead, child: Text(t.markAllRead)),
        ],
      ),
      body: FutureBuilder<NotificationInbox>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : t.couldNotLoadLearningContent;
            return _StatusPanel(message: message, action: _refresh, t: t);
          }

          final notifications = snapshot.data?.notifications ?? const [];
          if (notifications.isEmpty) {
            return _StatusPanel(
              message: t.noNotifications,
              action: _refresh,
              t: t,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: ResponsiveUtils.pagePadding(
                context,
                mobileHorizontalPercent: 6,
                tabletHorizontal: 42,
                desktopHorizontal: 56,
                top: 12,
                bottom: 34,
              ),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
                  t: t,
                  onTap: () => _markRead(notification),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemCount: notifications.length,
            ),
          );
        },
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
                      maxLines: 3,
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
