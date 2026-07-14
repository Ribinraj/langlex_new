import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/features/dashboard/widgets/dashboard_page_layout.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/pages/phonics_practice_page.dart';
import 'package:langlex_new_app/features/learning/pages/quiz_practice_page.dart';
import 'package:langlex_new_app/features/learning/pages/story_reader_page.dart';
import 'package:langlex_new_app/features/learning/widgets/learning_widgets.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';

class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningBloc, LearningState>(
      builder: (context, state) {
        const fallback = AppLocalizations('English');
        if (state is LearningLoading || state is LearningInitial) {
          return DashboardPageLayout(
            children: [
              DashboardHeader(
                title: fallback.practice,
                subtitle: fallback.practiceSubtitle,
              ),
              const SizedBox(height: 24),
              _PracticeStatusPanel(message: fallback.loadingPracticeContent),
            ],
          );
        }

        if (state is LearningError) {
          return DashboardPageLayout(
            children: [
              DashboardHeader(
                title: fallback.practice,
                subtitle: fallback.practiceSubtitle,
              ),
              ResponsiveSizedBox.height(2.4),
              _PracticeStatusPanel(
                message: fallback.couldNotLoadLearningContent,
                actionLabel: fallback.retry,
                onAction: () => context.read<LearningBloc>().add(
                  const LoadLearningCatalogEvent(forceRefresh: true),
                ),
              ),
            ],
          );
        }

        return _buildPractice(context, (state as LearningLoaded).catalog);
      },
    );
  }

  Widget _buildPractice(BuildContext context, LearningCatalog catalog) {
    final selectedLanguage =
        catalog.languages.contains(catalog.setup.learningLanguage)
        ? catalog.setup.learningLanguage
        : catalog.languages.first;
    final alphabets = catalog.alphabets
        .where((item) => item.language == selectedLanguage)
        .toList();
    final phonics = catalog.phonics
        .where((item) => item.language == selectedLanguage)
        .toList();
    final quizQuestions = catalog.quizQuestions
        .where((item) => item.language == selectedLanguage)
        .toList();
    final stories = catalog.stories
        .where((item) => item.language == selectedLanguage)
        .toList();
    final t = AppLocalizations(catalog.setup.primaryLanguage);

    return DashboardPageLayout(
      children: [
        DashboardHeader(title: t.practice, subtitle: t.practiceSubtitle),
        ResponsiveSizedBox.height(2.4),
        Row(
          children: [
            LearningMetricTile(
              icon: Icons.auto_stories_rounded,
              value: stories.length.toString(),
              label: t.stories,
              color: Appcolors.kmetricInventory,
            ),
            const SizedBox(width: 12),
            LearningMetricTile(
              icon: Icons.quiz_rounded,
              value: quizQuestions.length.toString(),
              label: t.questions,
              color: Appcolors.kprimarycolor,
            ),
          ],
        ),
        ResponsiveSizedBox.height(2.6),
        LearningSectionHeader(title: t.alphabetPractice),
        ResponsiveSizedBox.height(1.2),
        if (alphabets.isEmpty)
          _PracticeStatusPanel(message: t.noAlphabetRows)
        else
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: alphabets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = alphabets[index];
                return _AlphabetCard(item: item);
              },
            ),
          ),
        ResponsiveSizedBox.height(2.6),
        LearningSectionHeader(title: t.practiceModes),
        ResponsiveSizedBox.height(1.2),
        DashboardActionTile(
          icon: Icons.record_voice_over_rounded,
          title: t.phonics,
          subtitle: t.soundCards(phonics.length),
          accent: Appcolors.kdashboardTeal,
          surface: Appcolors.kauthSoftGreen,
          onTap: phonics.isEmpty
              ? null
              : () {
                  Navigator.of(context).push(
                    playfulRoute(
                      page: PhonicsPracticePage(
                        phonics: phonics,
                        homeLanguage: catalog.setup.primaryLanguage,
                      ),
                    ),
                  );
                },
        ),
        ResponsiveSizedBox.height(1.4),
        DashboardActionTile(
          icon: Icons.quiz_rounded,
          title: t.quiz,
          subtitle: t.quickQuestions(quizQuestions.length),
          accent: Appcolors.kprimarycolor,
          surface: Appcolors.ksoftPrimarySurface,
          onTap: quizQuestions.isEmpty
              ? null
              : () {
                  Navigator.of(context).push(
                    playfulRoute(
                      page: QuizPracticePage(
                        questions: quizQuestions,
                        homeLanguage: catalog.setup.primaryLanguage,
                        contentKey: 'practice-quiz-$selectedLanguage',
                      ),
                    ),
                  );
                },
        ),
        ResponsiveSizedBox.height(1.4),
        _StoryPracticeTile(
          stories: stories,
          t: t,
          homeLanguage: catalog.setup.primaryLanguage,
        ),
      ],
    );
  }
}

class _StoryPracticeTile extends StatefulWidget {
  const _StoryPracticeTile({
    required this.stories,
    required this.t,
    required this.homeLanguage,
  });

  final List<StoryItem> stories;
  final AppLocalizations t;
  final String homeLanguage;

  @override
  State<_StoryPracticeTile> createState() => _StoryPracticeTileState();
}

class _StoryPracticeTileState extends State<_StoryPracticeTile> {
  Future<StoryItem?>? _storyFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storyFuture ??= _nextStory();
  }

  Future<StoryItem?> _nextStory() async {
    if (widget.stories.isEmpty) return null;

    for (final story in widget.stories) {
      final key = story.id > 0
          ? 'story-${story.id}'
          : 'story-${story.title.toLowerCase()}';
      try {
        final progress = await context
            .read<LearningRepository>()
            .getContentProgress(contentType: 'story', contentKey: key);
        if (!progress.isCompleted) return story;
      } catch (_) {
        return story;
      }
    }

    return widget.stories.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StoryItem?>(
      future: _storyFuture,
      builder: (context, snapshot) {
        final story = snapshot.data;
        return DashboardActionTile(
          icon: Icons.menu_book_rounded,
          title: widget.t.storyReader,
          subtitle: widget.t.storyReaderSubtitle,
          accent: Appcolors.kmetricInventory,
          surface: Appcolors.kmetricInventorySurface,
          onTap: story == null
              ? null
              : () {
                  Navigator.of(context).push(
                    playfulRoute(
                      page: StoryReaderPage(
                        story: story,
                        homeLanguage: widget.homeLanguage,
                      ),
                    ),
                  );
                },
        );
      },
    );
  }
}

class _AlphabetCard extends StatelessWidget {
  const _AlphabetCard({required this.item});

  final AlphabetItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Appcolors.kauthDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ResponsiveText(
                  item.letter,
                  fontSize: 31,
                  weight: FontWeight.w900,
                  color: Appcolors.kprimarycolor,
                ),
              ),
              LearningAudioButton(path: item.audioPath, tooltip: item.word),
            ],
          ),
          const Spacer(),
          ResponsiveText(
            item.word,
            fontSize: 13,
            weight: FontWeight.w900,
            color: Appcolors.ktextdark,
            maxLines: 1,
          ),
          const SizedBox(height: 3),
          ResponsiveText(
            item.type,
            fontSize: 10.5,
            weight: FontWeight.w700,
            color: Appcolors.kdashboardMutedText,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _PracticeStatusPanel extends StatelessWidget {
  const _PracticeStatusPanel({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Appcolors.kauthDivider),
      ),
      child: Column(
        children: [
          ResponsiveText(
            message,
            fontSize: 14,
            weight: FontWeight.w800,
            color: Appcolors.kdashboardMutedText,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
