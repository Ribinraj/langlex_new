import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/widgets/content_shimmers.dart';
import 'progress_models.dart';
import 'progress_store.dart';

IconData progressIcon(String type) => switch (type) {
  'course' => Icons.auto_stories_rounded,
  'quiz' => Icons.extension_rounded,
  'phonics' => Icons.graphic_eq_rounded,
  'alphabet' => Icons.abc_rounded,
  'story' => Icons.menu_book_rounded,
  _ => Icons.school_rounded,
};

class ProgressOverviewCard extends StatefulWidget {
  const ProgressOverviewCard({
    super.key,
    required this.language,
    required this.onDetails,
  });
  final String language;
  final VoidCallback onDetails;
  @override
  State<ProgressOverviewCard> createState() => _ProgressOverviewCardState();
}

class _ProgressOverviewCardState extends State<ProgressOverviewCard> {
  bool _visible = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible && !_visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<LearningRepository>().progress.refresh(widget.language);
        }
      });
    }
    _visible = visible;
  }

  @override
  void didUpdateWidget(covariant ProgressOverviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<LearningRepository>().progress.refresh(widget.language);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<LearningRepository>().progress;
    final t = AppLocalizations(widget.language);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final data = store.overview?.language == widget.language
            ? store.overview
            : null;
        if (data == null && store.error == null) {
          return LearningProgressShimmer(label: t.loading);
        }
        if (data == null) {
          return ProgressUnavailable(
            t: t,
            onRetry: () => store.refresh(widget.language),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProgressSummary(data: data, t: t, onDetails: widget.onDetails),
            if (store.pending > 0 || store.error != null)
              ProgressSyncNotice(store: store, t: t),
          ],
        );
      },
    );
  }
}

class ProgressSummary extends StatelessWidget {
  const ProgressSummary({
    super.key,
    required this.data,
    required this.t,
    this.onDetails,
  });
  final LearningProgressOverview data;
  final AppLocalizations t;
  final VoidCallback? onDetails;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Appcolors.kwhitecolor,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Appcolors.kprimarycolor.withValues(alpha: .16)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.insights_rounded, color: Appcolors.klibraryTitle),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t.yourProgress,
                style: GoogleFonts.montserrat(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Appcolors.ktextdark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${data.language} · ${data.level}',
          style: const TextStyle(
            color: Appcolors.kdashboardMutedText,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, c) {
            final ring = Semantics(
              label: t.progressPercent(data.percent),
              child: SizedBox.square(
                dimension: 106,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 96,
                      child: CircularProgressIndicator(
                        value: data.fraction,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Appcolors.ksoftPrimarySurface,
                        color: Appcolors.ksearchSelectedChip,
                      ),
                    ),
                    Text(
                      '${data.percent}%',
                      textScaler: TextScaler.noScaling,
                      style: GoogleFonts.montserrat(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: Appcolors.klibraryTitle,
                      ),
                    ),
                  ],
                ),
              ),
            );
            final detail = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.stepsCompleted(data.completed, data.total),
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                    color: Appcolors.ktextdark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.topicsCompleted(data.completedTopics, data.totalTopics),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Appcolors.kdashboardMutedText,
                  ),
                ),
              ],
            );
            if (c.maxWidth < 280 ||
                MediaQuery.textScalerOf(context).scale(16) > 23) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [ring, const SizedBox(height: 16), detail],
              );
            }
            return Row(
              children: [
                ring,
                const SizedBox(width: 18),
                Expanded(child: detail),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ProgressChip(
              icon: data.premium
                  ? Icons.workspace_premium_rounded
                  : Icons.lock_open_rounded,
              label: data.premium ? t.premium : t.free,
            ),
            if (data.lockedTopics > 0)
              _ProgressChip(
                icon: Icons.lock_outline_rounded,
                label: t.lockedTopicCount(data.lockedTopics),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          t.progressScopeHint,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Appcolors.kdashboardMutedText,
          ),
        ),
        if (onDetails != null) ...[
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onDetails,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              foregroundColor: Appcolors.klibraryTitle,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(t.viewTopicProgress, textAlign: TextAlign.center),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _ProgressChip extends StatelessWidget {
  const _ProgressChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Appcolors.ksoftPrimarySurface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Appcolors.klibraryTitle),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Appcolors.klibraryTitle,
            ),
          ),
        ),
      ],
    ),
  );
}

class TopicProgressBadge extends StatefulWidget {
  const TopicProgressBadge({
    super.key,
    required this.type,
    required this.contentKey,
    required this.language,
  });
  final String type, contentKey, language;
  @override
  State<TopicProgressBadge> createState() => _TopicProgressBadgeState();
}

class _TopicProgressBadgeState extends State<TopicProgressBadge> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LearningRepository?>()?.progress.ensureLoaded(
          widget.language,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<LearningRepository?>()?.progress;
    if (store == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final topic = store.overview?.language == widget.language
            ? store.overview?.topic(widget.type, widget.contentKey)
            : null;
        if (topic == null || topic.total == 0) return const SizedBox.shrink();
        final t = AppLocalizations(widget.language);
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                topic.accessible
                    ? t.topicCompletion(topic.completed, topic.total)
                    : t.savedTopicProgress(topic.completed, topic.total),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Appcolors.klibraryTitle,
                ),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: topic.fraction,
                  minHeight: 5,
                  color: Appcolors.ksearchSelectedChip,
                  backgroundColor: Appcolors.ksoftPrimarySurface,
                  semanticsLabel: t.yourProgress,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProgressUnavailable extends StatelessWidget {
  const ProgressUnavailable({
    super.key,
    required this.t,
    required this.onRetry,
  });
  final AppLocalizations t;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          size: 32,
          color: Appcolors.klibraryTitle,
        ),
        const SizedBox(height: 12),
        Text(t.progressUnavailable, textAlign: TextAlign.center),
        TextButton(onPressed: onRetry, child: Text(t.retry)),
      ],
    ),
  );
}

class ProgressSyncNotice extends StatelessWidget {
  const ProgressSyncNotice({super.key, required this.store, required this.t});
  final ProgressStore store;
  final AppLocalizations t;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          store.needsAttention > 0
              ? t.progressNeedsAttention
              : store.pending > 0
              ? t.progressPending(store.pending)
              : t.progressUnavailable,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Appcolors.kdashboardMutedText,
          ),
        ),
        TextButton.icon(
          onPressed: () => store.refresh(),
          icon: const Icon(Icons.sync_rounded, size: 18),
          label: Text(t.syncProgress),
        ),
      ],
    ),
  );
}
