import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/widgets/app_empty_state.dart';
import 'package:langlex_new_app/features/dashboard/widgets/flow_scroll_view.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/widgets/content_shimmers.dart';
import 'progress_models.dart';
import 'progress_widgets.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key, required this.language});
  final String language;
  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  String _kind = 'all', _status = 'all';
  late String _language;
  @override
  void initState() {
    super.initState();
    _language = widget.language;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LearningRepository>().progress.refresh(_language);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<LearningRepository>().progress;
    final t = AppLocalizations(_language);
    return Scaffold(
      backgroundColor: Appcolors.kscreenWarmBackground,
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final data = store.overview?.language == _language
              ? store.overview
              : null;
          final topics =
              data?.topics
                  .where(
                    (topic) =>
                        (_kind == 'all' || topic.type == _kind) &&
                        (_status == 'all' ||
                            (_status == 'locked'
                                ? !topic.accessible
                                : topic.accessible && topic.status == _status)),
                  )
                  .toList() ??
              <TopicProgress>[];
          return RefreshIndicator(
            onRefresh: () => store.refresh(_language),
            child: FlowScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              header: FlowPageHeader(
                title: t.yourProgress,
                subtitle: t.progressPageSubtitle,
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (data == null) ...[
                              if (store.error == null)
                                LearningProgressShimmer(label: t.loading)
                              else
                                ProgressUnavailable(
                                  t: t,
                                  onRetry: () => store.refresh(_language),
                                ),
                            ] else ...[
                              if (data.languages.length > 1) ...[
                                DropdownButtonFormField<String>(
                                  key: ValueKey(_language),
                                  initialValue: _language,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: t.languageLabel,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  items: [
                                    for (final language in data.languages)
                                      DropdownMenuItem(
                                        value: language,
                                        child: Text(language),
                                      ),
                                  ],
                                  onChanged: (language) {
                                    if (language == null ||
                                        language == _language) {
                                      return;
                                    }
                                    setState(() {
                                      _language = language;
                                      _kind = 'all';
                                      _status = 'all';
                                    });
                                    store.refresh(language);
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                              ProgressSummary(data: data, t: t),
                              if (store.pending > 0 || store.error != null)
                                ProgressSyncNotice(store: store, t: t),
                              const SizedBox(height: 18),
                              ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: Text(
                                  t.progressMethodTitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      t.progressMethodHint,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.6,
                                        color: Appcolors.kdashboardMutedText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (data.savedLocked > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    t.savedPremiumProgress(data.savedLocked),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                      color: Appcolors.klibraryTitle,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              Text(
                                t.topicProgress,
                                style: GoogleFonts.montserrat(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: Appcolors.ktextdark,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final item in [
                                    ('all', t.all),
                                    ('course', t.knowledge),
                                    ('alphabet', t.alphabets),
                                    ('phonics', t.sounds),
                                    ('quiz', t.quizzesHeading),
                                    ('story', t.stories),
                                  ])
                                    ChoiceChip(
                                      label: Text(item.$2),
                                      selected: _kind == item.$1,
                                      onSelected: (_) =>
                                          setState(() => _kind = item.$1),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _status,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: t.progressFilter,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                items: [
                                  for (final item in [
                                    ('all', t.all),
                                    ('in_progress', t.inProgress),
                                    ('completed', t.completedLabel),
                                    ('not_started', t.notStarted),
                                    ('locked', t.premiumLocked),
                                  ])
                                    DropdownMenuItem(
                                      value: item.$1,
                                      child: Text(item.$2),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _status = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 18),
                              if (topics.isEmpty)
                                AppEmptyState(
                                  title: t.nothingHereYet,
                                  message: t.progressEmptyHint,
                                  kind: EmptyStateKind.lessons,
                                  compact: true,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (data != null && topics.isNotEmpty)
                  SliverList.builder(
                    itemCount: topics.length,
                    itemBuilder: (context, index) => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: _TopicTile(topic: topics[index], t: t),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic, required this.t});
  final TopicProgress topic;
  final AppLocalizations t;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Appcolors.kwhitecolor,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Appcolors.kauthDivider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Appcolors.ksoftPrimarySurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                progressIcon(topic.type),
                color: Appcolors.klibraryTitle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                topic.title,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                  color: Appcolors.ktextdark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              !topic.accessible
                  ? Icons.lock_outline_rounded
                  : topic.status == 'completed'
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: topic.status == 'completed'
                  ? Appcolors.ksearchSelectedChip
                  : Appcolors.kdashboardMutedText,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          topic.total == 0
              ? t.contentPending
              : topic.accessible
              ? t.topicCompletion(topic.completed, topic.total)
              : t.savedTopicProgress(topic.completed, topic.total),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Appcolors.klibraryTitle,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: topic.fraction,
            minHeight: 7,
            color: Appcolors.ksearchSelectedChip,
            backgroundColor: Appcolors.ksoftPrimarySurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          !topic.accessible
              ? t.premiumLocked
              : topic.status == 'completed'
              ? t.completedLabel
              : topic.completed > 0
              ? t.inProgress
              : t.notStarted,
          style: const TextStyle(
            fontSize: 12,
            color: Appcolors.kdashboardMutedText,
          ),
        ),
        if (topic.type == 'quiz' && topic.completed > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              t.quizCorrectCount(topic.correct, topic.completed),
              style: const TextStyle(
                fontSize: 12,
                color: Appcolors.ksearchSelectedChip,
              ),
            ),
          ),
      ],
    ),
  );
}
