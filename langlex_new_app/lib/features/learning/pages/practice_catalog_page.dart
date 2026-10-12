import 'package:langlex_new_app/core/widgets/app_empty_state.dart';
import 'package:langlex_new_app/features/dashboard/widgets/dashboard_destination.dart';
import 'package:langlex_new_app/features/learning/widgets/content_shimmers.dart';
import 'package:langlex_new_app/features/learning/widgets/practice_catalog_header.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';
import 'package:langlex_new_app/features/dashboard/widgets/flow_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/features/learning/widgets/alphabet_catalog_widgets.dart';
import 'package:langlex_new_app/features/learning/widgets/quiz_catalog_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/features/learning/widgets/sound_category_card.dart';
import 'package:langlex_new_app/features/learning/widgets/paged_learning_list.dart';

class PracticeCatalogPage extends StatelessWidget {
  const PracticeCatalogPage({
    super.key,
    required this.resource,
    required this.language,
    required this.homeLanguage,
  });
  final String resource;
  final String language;
  final String homeLanguage;
  Widget _quizCatalog(BuildContext context) {
    final t = AppLocalizations(homeLanguage);
    return Scaffold(
      backgroundColor: Appcolors.kscreenWarmBackground,
      body: FlowScrollView(
        header: PracticeCatalogHeader(
          title: t.quizzesHeading,
          subtitle: t.playAndDiscover,
          artwork: KidsLearningAssets.trophyIcon,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: PagedLearningList<Map<String, dynamic>>(
                key: ValueKey('quiz-sets-$language'),
                emptyState: AppEmptyState(
                  kind: EmptyStateKind.quizzes,
                  title: t.nothingHereYet,
                  message: t.noQuizQuestions,
                  actionLabel: Navigator.of(context).canPop() ? t.goBack : null,
                  onAction: Navigator.of(context).canPop()
                      ? () => Navigator.of(context).maybePop()
                      : null,
                ),
                loadingIndicator: CatalogShimmer(
                  kind: CatalogSkeleton.quizzes,
                  label: t.loadingPracticeContent,
                  showHeading: true,
                  itemCount: 4,
                ),
                load: (page) => context
                    .read<LearningRepository>()
                    .fetchQuizTopics(language: language, page: page),
                builder: (context, page) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Choose a quiz',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Appcolors.kheroGreetingText,
                          ),
                        ),
                        Text(
                          '${page.total} topics',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Appcolors.ktextgreycolor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    for (final (index, topic) in page.items.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: QuizSetCard(
                          key: ValueKey(topic['id']),
                          topic: topic,
                          homeLanguage: homeLanguage,
                          index: index,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _alphabetCatalog(BuildContext context) {
    final t = AppLocalizations(homeLanguage);
    return Scaffold(
      backgroundColor: Appcolors.kscreenWarmBackground,
      body: FlowScrollView(
        header: PracticeCatalogHeader(
          title: t.alphabets,
          subtitle: t.letterSounds,
          artwork: 'assets/icons/fairy-tale.svg',
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: PagedLearningList<Map<String, dynamic>>(
                key: ValueKey('alphabet-$language'),
                emptyState: AppEmptyState(
                  kind: EmptyStateKind.alphabets,
                  title: t.nothingHereYet,
                  message: t.noAlphabetRows,
                  actionLabel: Navigator.of(context).canPop() ? t.goBack : null,
                  onAction: Navigator.of(context).canPop()
                      ? () => Navigator.of(context).maybePop()
                      : null,
                ),
                loadingIndicator: CatalogShimmer(
                  kind: CatalogSkeleton.alphabets,
                  label: t.loadingPracticeContent,
                  showHeading: true,
                  itemCount: 6,
                ),
                load: (page) => context.read<LearningRepository>().fetchPage(
                  'alphabets',
                  (row) => row,
                  page: page,
                  filters: {'language': language, 'view': 'letters'},
                ),
                builder: (context, page) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Choose a letter',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Appcolors.kheroGreetingText,
                          ),
                        ),
                        Text(
                          '${page.total} letter forms',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Appcolors.ktextgreycolor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AlphabetGroups(rows: page.items),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (resource == 'quizzes') return _quizCatalog(context);
    if (resource == 'alphabets') return _alphabetCatalog(context);
    final t = AppLocalizations(homeLanguage);
    return DashboardDestination(
      title: t.sounds,
      backgroundGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0, .32, .62, 1],
        colors: [
          Appcolors.ksearchBackgroundTop,
          Appcolors.khomeBackgroundTop,
          Appcolors.khomeBackgroundMiddle,
          Appcolors.khomeBackgroundBottom,
        ],
      ),
      child: FlowScrollView(
        header: PracticeCatalogHeader(
          title: t.sounds,
          subtitle: t.listenAndSay,
          artwork: 'assets/icons/music.svg',
          usePageBackground: true,
          maxWidth: 720,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: PagedLearningList<Map<String, dynamic>>(
                key: ValueKey('sound-categories-$language'),
                emptyState: AppEmptyState(
                  kind: EmptyStateKind.sounds,
                  title: t.nothingHereYet,
                  message: t.noPhonics,
                  actionLabel: Navigator.of(context).canPop() ? t.goBack : null,
                  onAction: Navigator.of(context).canPop()
                      ? () => Navigator.of(context).maybePop()
                      : null,
                ),
                loadingIndicator: CatalogShimmer(
                  kind: CatalogSkeleton.sounds,
                  label: t.loadingPracticeContent,
                  showHeading: true,
                  itemCount: 4,
                ),
                load: (page) => context
                    .read<LearningRepository>()
                    .fetchSoundCategories(language: language, page: page),
                builder: (context, page) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (page.items.isNotEmpty) ...[
                      Text(
                        t.exploreTopics,
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Appcolors.kheroGreetingText,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    for (var index = 0; index < page.items.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: SoundCategoryCard(
                          key: ValueKey(
                            'sound-category-${page.items[index]['id']}',
                          ),
                          category: page.items[index],
                          language: language,
                          homeLanguage: homeLanguage,
                          index: index,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
