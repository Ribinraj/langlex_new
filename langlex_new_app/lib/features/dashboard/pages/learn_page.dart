import 'package:langlex_new_app/core/app_toast.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_bloc.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_state.dart';
import 'package:langlex_new_app/features/progress/progress_widgets.dart';
import 'package:langlex_new_app/core/widgets/app_empty_state.dart';
import 'package:langlex_new_app/core/widgets/app_shimmer.dart';
import 'package:langlex_new_app/features/learning/widgets/content_shimmers.dart';
import 'package:langlex_new_app/features/learning/widgets/practice_catalog_header.dart';
import 'package:langlex_new_app/features/dashboard/widgets/flow_scroll_view.dart';
import 'dart:async';
import 'package:langlex_new_app/features/learning/widgets/alphabet_catalog_widgets.dart';
import 'package:langlex_new_app/features/learning/widgets/quiz_catalog_widgets.dart';
import 'package:flutter/material.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/widgets/paged_learning_list.dart';
import 'package:langlex_new_app/features/dashboard/widgets/search_results_shimmer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/pages/course_detail_page.dart';
import 'package:langlex_new_app/features/learning/pages/practice_catalog_page.dart';
import 'package:langlex_new_app/features/dashboard/widgets/dashboard_destination.dart';
import 'package:langlex_new_app/features/learning/pages/story_reader_page.dart';
import 'package:langlex_new_app/features/learning/widgets/learning_widgets.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';
import 'package:langlex_new_app/features/payments/pages/payment_checkout_page.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({
    super.key,
    this.storiesOnly = false,
    this.searchMode = false,
  });

  final bool storiesOnly;
  final bool searchMode;

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _resource = 'courses';
  bool get _showStories =>
      widget.storiesOnly || (widget.searchMode && _resource == 'stories');
  bool get _showCourses =>
      !widget.storiesOnly && (!widget.searchMode || _resource == 'courses');
  String _title(AppLocalizations t) => widget.searchMode
      ? t.search
      : _showStories
      ? t.stories
      : t.knowledge;
  Timer? _searchDebounce;
  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _search(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() => _query = '');
  }

  Widget _emptyLibrary(AppLocalizations t) {
    final searching = _query.trim().isNotEmpty;
    final canGoBack = Navigator.of(context).canPop();
    return AppEmptyState(
      kind: searching
          ? EmptyStateKind.search
          : _showStories
          ? EmptyStateKind.stories
          : _resource == 'alphabets'
          ? EmptyStateKind.alphabets
          : _resource == 'quizzes'
          ? EmptyStateKind.quizzes
          : EmptyStateKind.lessons,
      title: searching ? t.noResultsTitle : t.nothingHereYet,
      message: searching
          ? t.emptySearchHint
          : _showStories
          ? t.noStoriesAvailable
          : _resource == 'alphabets'
          ? t.noAlphabetRows
          : _resource == 'quizzes'
          ? t.noQuizQuestions
          : t.noLessonsFound,
      actionLabel: searching
          ? t.clearSearch
          : canGoBack
          ? t.goBack
          : null,
      onAction: searching
          ? _clearSearch
          : canGoBack
          ? () => Navigator.of(context).maybePop()
          : null,
      actionIcon: searching
          ? Icons.restart_alt_rounded
          : Icons.arrow_back_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LearningBloc>().state;
    final t = AppLocalizations(
      state is LearningLoaded ? state.catalog.setup.primaryLanguage : 'English',
    );
    return DashboardDestination(
      title: _title(t),
      backgroundGradient: widget.searchMode || !widget.storiesOnly
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .32, .62, 1],
              colors: [
                Appcolors.ksearchBackgroundTop,
                Appcolors.khomeBackgroundTop,
                Appcolors.khomeBackgroundMiddle,
                Appcolors.khomeBackgroundBottom,
              ],
            )
          : null,
      child: BlocBuilder<LearningBloc, LearningState>(
        builder: (context, state) {
          const fallback = AppLocalizations('English');
          if (state is LearningLoading || state is LearningInitial) {
            return FlowScrollView(
              header: _libraryHeader(t),
              padding: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: ResponsiveUtils.pagePadding(
                  context,
                  mobileHorizontalPercent: 6,
                  tabletHorizontal: 42,
                  desktopHorizontal: 56,
                ).copyWith(top: 0),
                child: ResponsiveUtils.constrainWidth(
                  context: context,
                  maxWidth: 680,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_showCourses && !widget.searchMode) ...[
                        AppShimmer(
                          label: fallback.loadingLibrary,
                          child: const PracticeModeShimmerCard(),
                        ),
                        const SizedBox(height: 24),
                      ],
                      CatalogShimmer(
                        label: fallback.loadingLibrary,
                        kind: _showStories
                            ? CatalogSkeleton.stories
                            : _resource == 'alphabets'
                            ? CatalogSkeleton.alphabets
                            : _resource == 'quizzes'
                            ? CatalogSkeleton.quizzes
                            : CatalogSkeleton.courses,
                        showHeading: _showCourses,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (state is LearningError) {
            return FlowScrollView(
              header: widget.searchMode
                  ? FlowPageHeader(title: _title(t), showBack: false)
                  : PracticeCatalogHeader(
                      title: _title(t),
                      subtitle: widget.storiesOnly
                          ? t.chooseStory
                          : t.playAndDiscover,
                      artwork: widget.storiesOnly
                          ? 'assets/icons/animal.svg'
                          : 'assets/images/knowledge-fox.png',
                      usePageBackground: !widget.storiesOnly,
                      maxWidth: 720,
                    ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ResponsiveSizedBox.height(2.4),
                  _LibraryStatusPanel(
                    message: fallback.couldNotLoadLearningContent,
                    actionLabel: fallback.retry,
                    onAction: () => context.read<LearningBloc>().add(
                      const LoadLearningCatalogEvent(forceRefresh: true),
                    ),
                  ),
                ],
              ),
            );
          }

          final catalog = (state as LearningLoaded).catalog;
          return _buildLoadedLibrary(context, catalog);
        },
      ),
    );
  }

  Widget _buildLoadedLibrary(BuildContext context, LearningCatalog catalog) {
    final t = AppLocalizations(catalog.setup.primaryLanguage);
    final selectedLanguage = catalog.setup.learningLanguage;
    final selectedLevel = catalog.setup.level;
    final repository = context.read<LearningRepository>();
    final query = <String, dynamic>{
      'search': _query,
      'language': selectedLanguage,
      if (_showCourses) 'level': selectedLevel,
    };
    final isMobile = ResponsiveUtils.isMobile(context);

    return FlowScrollView(
      header: _libraryHeader(t),
      padding: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: ResponsiveUtils.pagePadding(
          context,
          mobileHorizontalPercent: 6,
          tabletHorizontal: 42,
          desktopHorizontal: 56,
        ).copyWith(top: 0),
        child: ResponsiveUtils.constrainWidth(
          context: context,
          maxWidth: 680,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showCourses && !widget.searchMode && _query.isEmpty) ...[
                _SoundsPracticeCard(
                  title: t.sounds,
                  subtitle: t.listenAndSay,
                  onTap: () => _openPractice(catalog, 'phonics'),
                ),
                const SizedBox(height: 24),
              ],
              if (_showCourses)
                PagedLearningList<LearningCourse>(
                  emptyState: _emptyLibrary(t),
                  loadingIndicator: CatalogShimmer(
                    label: t.loadingLibrary,
                    kind: CatalogSkeleton.courses,
                    showHeading: true,
                  ),
                  key: ValueKey(
                    'courses-$_query-$selectedLanguage-$selectedLevel',
                  ),
                  load: (page) => repository.fetchPage(
                    'courses',
                    (row) => LearningCourse.fromCourseJson(
                      row,
                      [],
                      alphabets: [],
                      phonics: [],
                    ),
                    page: page,
                    limit: 12,
                    filters: query,
                  ),
                  builder: (context, page) => Column(
                    children: [
                      _LibraryCoursesHeader(
                        title: t.exploreTopics,
                        compact: widget.searchMode,
                      ),
                      ResponsiveSizedBox.height(1.2),
                      for (final course in page.items) ...[
                        LearningCourseCard(
                          course: course,
                          homeLanguage: catalog.setup.primaryLanguage,
                          onTap: () => _openCourse(
                            context,
                            course,
                            catalog.plans,
                            catalog.setup.primaryLanguage,
                          ),
                        ),
                        ResponsiveSizedBox.height(1.4),
                      ],
                    ],
                  ),
                ),
              if (_showStories) ...[
                PagedLearningList<StoryItem>(
                  emptyState: _emptyLibrary(t),
                  loadingIndicator: CatalogShimmer(
                    label: t.loadingLibrary,
                    kind: CatalogSkeleton.stories,
                  ),
                  key: ValueKey(
                    'stories-$_query-$selectedLanguage-$selectedLevel',
                  ),
                  load: (page) => repository.fetchPage(
                    'stories',
                    StoryItem.fromJson,
                    page: page,
                    limit: 6,
                    filters: query,
                  ),
                  builder: (context, page) => Column(
                    children: [
                      for (
                        var index = 0;
                        index < page.items.length;
                        index++
                      ) ...[
                        _StoryTile(
                          story: page.items[index],
                          t: t,
                          accent: _storyAccent(index),
                          onTap: () => _openStory(
                            context,
                            page.items[index],
                            catalog.plans,
                            catalog.setup.primaryLanguage,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ],
              if (widget.searchMode && !_showCourses && !_showStories)
                PagedLearningList<Map<String, dynamic>>(
                  emptyState: _emptyLibrary(t),
                  loadingIndicator: SearchResultsShimmer(
                    label: t.loadingLibrary,
                    alphabetGrid: _resource == 'alphabets',
                    kind: CatalogSkeleton.quizzes,
                  ),
                  key: ValueKey('search-$_resource-$_query-$selectedLanguage'),
                  load: (page) => _resource == 'quizzes'
                      ? repository.fetchQuizTopics(
                          language: selectedLanguage,
                          search: _query,
                          page: page,
                        )
                      : repository.fetchPage(
                          _resource,
                          (row) => row,
                          page: page,
                          limit: 12,
                          filters: {
                            ...query,
                            if (_resource == 'alphabets') 'view': 'letters',
                          },
                        ),
                  builder: (context, page) {
                    if (_resource == 'alphabets') {
                      return AlphabetSearchResults(
                        rows: page.items,
                        total: page.total,
                        language: catalog.setup.primaryLanguage,
                      );
                    }
                    return Column(
                      children: [
                        for (final (index, topic) in page.items.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: QuizSetCard(
                              key: ValueKey(topic['id']),
                              topic: topic,
                              homeLanguage: catalog.setup.primaryLanguage,
                              index: index,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              SizedBox(height: isMobile ? 4 : 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _libraryHeader(AppLocalizations t) => _LibraryHeroSection(
    searchController: _searchController,
    searchHint: widget.searchMode
        ? (_resource == 'alphabets' ? t.searchLetters : t.searchLearning)
        : _showStories
        ? t.searchStories
        : t.searchTopics,
    showBack: !widget.searchMode,
    compact: widget.searchMode || !widget.storiesOnly,
    mascotAsset: !widget.searchMode && !widget.storiesOnly
        ? 'assets/images/knowledge-fox.png'
        : null,
    categories: widget.searchMode
        ? SingleChildScrollView(
            key: const PageStorageKey('search-category-chips'),
            scrollDirection: Axis.horizontal,
            primary: false,
            child: Row(
              children: [
                for (final category in [
                  ('courses', t.knowledge),
                  ('alphabets', t.alphabets),
                  ('stories', t.stories),
                  ('quizzes', t.quizzesHeading),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category.$2, maxLines: 1),
                      labelStyle: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _resource == category.$1
                            ? Appcolors.kwhitecolor
                            : Appcolors.klibrarySubtitle,
                      ),
                      selectedColor: Appcolors.ksearchSelectedChip,
                      backgroundColor: Appcolors.kwhitecolor.withValues(
                        alpha: .65,
                      ),
                      checkmarkColor: Appcolors.kwhitecolor,
                      side: BorderSide(
                        color: _resource == category.$1
                            ? Appcolors.ksearchSelectedChip
                            : Appcolors.kwhitecolor.withValues(alpha: .8),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      selected: _resource == category.$1,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _resource = category.$1);
                        }
                      },
                    ),
                  ),
              ],
            ),
          )
        : null,
    title: _title(t),
    subtitle: _showStories ? t.chooseStory : t.playAndDiscover,
    onQueryChanged: _search,
  );

  void _openPractice(LearningCatalog catalog, String resource) {
    Navigator.of(context).push(
      playfulRoute(
        page: PracticeCatalogPage(
          resource: resource,
          language: catalog.setup.learningLanguage,
          homeLanguage: catalog.setup.primaryLanguage,
        ),
      ),
    );
  }

  Future<bool> _canOpenPremium(
    BuildContext context,
    List<SubscriptionPlan> plans,
    String language,
  ) async {
    try {
      if (await context.read<LearningRepository>().hasPremiumAccess()) {
        return context.mounted;
      }
      if (!context.mounted) return false;
      final unlocked = await Navigator.of(context).push<bool>(
        playfulRoute(
          page: PaymentCheckoutPage(plans: plans, homeLanguage: language),
        ),
      );
      return unlocked == true && context.mounted;
    } catch (_) {
      if (context.mounted) {
        AppToast.error(
          context,
          AppLocalizations(language).couldNotLoadLearningContent,
        );
      }
      return false;
    }
  }

  Future<void> _openCourse(
    BuildContext context,
    LearningCourse course,
    List<SubscriptionPlan> plans,
    String homeLanguage,
  ) async {
    if (course.access == LearningAccess.premium &&
        !await _canOpenPremium(context, plans, homeLanguage)) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      playfulRoute(
        page: CourseDetailPage(course: course, homeLanguage: homeLanguage),
      ),
    );
    if (context.mounted) {
      context.read<LearningRepository>().progress.refresh(homeLanguage);
    }
  }

  Future<void> _openStory(
    BuildContext context,
    StoryItem story,
    List<SubscriptionPlan> plans,
    String homeLanguage,
  ) async {
    if (story.access == LearningAccess.premium &&
        !await _canOpenPremium(context, plans, homeLanguage)) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    StoryItem readableStory;
    try {
      readableStory = await context.read<LearningRepository>().openStory(story);
    } catch (_) {
      if (context.mounted) {
        AppToast.error(
          context,
          AppLocalizations(homeLanguage).couldNotLoadLearningContent,
        );
      }
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      playfulRoute(
        page: StoryReaderPage(story: readableStory, homeLanguage: homeLanguage),
      ),
    );
    if (context.mounted) {
      context.read<LearningRepository>().progress.refresh(homeLanguage);
    }
  }
}

class _SoundsPracticeCard extends StatelessWidget {
  const _SoundsPracticeCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: Appcolors.kauthSoftGreen,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Appcolors.khomeBackgroundBottom,
              Appcolors.khomeBackgroundMiddle,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Appcolors.kwhitecolor.withValues(alpha: .8),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 52,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Appcolors.ksearchSelectedChip,
                          Appcolors.khomeKnowledgeInk,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Appcolors.kwhitecolor,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 19,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: Appcolors.khomeKnowledgeInk,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: Appcolors.klibrarySubtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const ExcludeSemantics(
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Appcolors.ksearchSelectedChip,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _LibraryHeroSection extends StatelessWidget {
  const _LibraryHeroSection({
    required this.searchController,
    required this.searchHint,
    required this.title,
    required this.subtitle,
    required this.onQueryChanged,
    this.showBack = true,
    this.categories,
    this.compact = false,
    this.mascotAsset,
  });
  final TextEditingController searchController;
  final String? mascotAsset;
  final String searchHint;
  final String title;
  final String subtitle;
  final ValueChanged<String> onQueryChanged;
  final bool showBack;
  final Widget? categories;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (showBack) {
      return PracticeCatalogHeader(
        title: title,
        subtitle: subtitle,
        artwork: mascotAsset ?? 'assets/icons/animal.svg',
        artworkAboveFooter: true,
        usePageBackground: compact,
        maxWidth: 720,
        footer: _LibrarySearchField(
          controller: searchController,
          hintText: searchHint,
          onChanged: onQueryChanged,
        ),
      );
    }

    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  _LibrarySearchField(
                    controller: searchController,
                    hintText: searchHint,
                    onChanged: onQueryChanged,
                  ),
                ],
              ),
              Positioned(
                bottom: 46,
                right: 18,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: SvgPicture.asset(
                      'assets/icons/animal.svg',
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          _LibrarySearchField(
            controller: searchController,
            hintText: searchHint,
            onChanged: onQueryChanged,
          ),
        if (categories != null) ...[const SizedBox(height: 10), categories!],
      ],
    );
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                // Match the Profile page's title insets and alignment.
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          maxLines: 1,
                          style: GoogleFonts.montserrat(
                            fontSize: 26,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            color: Appcolors.klibraryTitle,
                          ),
                        ),
                      ),
                    ),
                    // Keep the title clear of the owl perched below it.
                    const SizedBox(width: 100),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: ResponsiveUtils.pagePadding(
              context,
              mobileHorizontalPercent: 6,
              tabletHorizontal: 42,
              desktopHorizontal: 56,
            ).copyWith(top: 0, bottom: 16),
            child: ResponsiveUtils.constrainWidth(
              context: context,
              maxWidth: 680,
              child: controls,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibrarySearchField extends StatelessWidget {
  const _LibrarySearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Appcolors.kwhitecolor.withValues(alpha: 0.86),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Appcolors.klibrarySoftShadow.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.montserrat(
          color: Appcolors.ktextdark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.montserrat(
            color: Appcolors.klibrarySearchHint,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Appcolors.klibrarySearchIcon,
            size: 30,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 56,
            minHeight: 54,
          ),
          filled: true,
          fillColor: Appcolors.ktransparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(0, 16, 18, 16),
        ),
      ),
    );
  }
}

class _LibraryCoursesHeader extends StatelessWidget {
  const _LibraryCoursesHeader({required this.title, this.compact = false});

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        children: [
          SvgPicture.asset(
            'assets/icons/online-course.svg',
            width: 28,
            height: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Appcolors.ktextdark,
              ),
            ),
          ),
        ],
      );
    }
    return SizedBox(
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Appcolors.klibraryCoursesIconSurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/online-course.svg',
                      width: 42,
                      height: 42,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ResponsiveText(
                    title,
                    fontSize: 24,
                    weight: FontWeight.w900,
                    color: Appcolors.ktextdark,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryStatusPanel extends StatelessWidget {
  const _LibraryStatusPanel({
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

const _storyAccentColors = [
  Appcolors.klearningPlayfulCoral,
  Appcolors.kheroStartButtonBottom,
  Appcolors.kdashboardBlue,
  Appcolors.klearningPlayfulGreen,
  Appcolors.klearningPlayfulPurple,
  Appcolors.kdashboardPink,
  Appcolors.klearningPlayfulTeal,
];

Color _storyAccent(int index) {
  return _storyAccentColors[index % _storyAccentColors.length];
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({
    required this.story,
    required this.t,
    required this.accent,
    required this.onTap,
  });

  final StoryItem story;
  final AppLocalizations t;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: Material(
        color: Appcolors.ktransparent,
        child: InkWell(
          onTap: () {
            LearningAssetSound.playTap();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(13, 10, 14, 10),
            decoration: BoxDecoration(
              color: Appcolors.kwhitecolor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Appcolors.kdashboardDivider.withValues(alpha: 0.92),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Appcolors.kblackcolor.withValues(alpha: 0.045),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _StoryImageBadge(story: story, accent: accent),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ResponsiveText(
                        story.title,
                        fontSize: 20,
                        weight: FontWeight.w900,
                        color: Appcolors.ktextdark,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 7),
                      ResponsiveText(
                        '${story.language} • ${story.grade} • ${story.minutes} ${t.minutesShort}',
                        fontSize: 13.2,
                        weight: FontWeight.w800,
                        color: Appcolors.kdashboardMutedText,
                        maxLines: 1,
                      ),
                      TopicProgressBadge(
                        type: 'story',
                        contentKey: 'story-${story.id}',
                        language: story.language,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Builder(
                  builder: (context) {
                    final store = context.read<LearningRepository?>()?.progress;
                    final auth = context.watch<AuthBloc?>()?.state;
                    final signedIn =
                        auth is AuthAuthenticated || auth is AuthOtpVerified;
                    Widget button() => _StoryGoButton(
                      accent: accent,
                      locked: story.access == LearningAccess.premium
                          ? store?.overview?.premium != true
                          : story.access == LearningAccess.login && !signedIn,
                    );
                    return store == null
                        ? button()
                        : AnimatedBuilder(
                            animation: store,
                            builder: (context, _) => button(),
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryImageBadge extends StatelessWidget {
  const _StoryImageBadge({required this.story, required this.accent});

  final StoryItem story;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: LearningMediaImage(
              path: story.imagePath,
              accent: accent,
              width: 88,
              height: 88,
              borderRadius: 16,
              fallbackIcon: Icons.auto_stories_rounded,
            ),
          ),
          Positioned(
            left: -3,
            top: -3,
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                KidsLearningAssets.openBookIcon,
                width: 16,
                height: 16,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Appcolors.kmetricInventory,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryGoButton extends StatelessWidget {
  const _StoryGoButton({required this.accent, required this.locked});

  final Color accent;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 66,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: SvgPicture.asset(
              KidsLearningAssets.starIcon,
              width: 17,
              height: 17,
              colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Icon(
              locked ? Icons.lock_rounded : Icons.chevron_right_rounded,
              color: accent,
              size: locked ? 22 : 34,
            ),
          ),
        ],
      ),
    );
  }
}
