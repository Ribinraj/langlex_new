import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/dashboard/widgets/dashboard_page_layout.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/pages/course_detail_page.dart';
import 'package:langlex_new_app/features/learning/pages/learning_setup_page.dart';
import 'package:langlex_new_app/features/learning/pages/quiz_practice_page.dart';
import 'package:langlex_new_app/features/learning/pages/story_reader_page.dart';
import 'package:langlex_new_app/features/learning/widgets/learning_widgets.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';
import 'package:langlex_new_app/features/notifications/notification_repo.dart';
import 'package:langlex_new_app/features/notifications/pages/notifications_page.dart';
import 'package:langlex_new_app/features/payments/pages/payment_checkout_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningBloc, LearningState>(
      builder: (context, state) {
        const t = AppLocalizations('English');
        if (state is LearningLoaded) {
          return _buildLoadedHome(context, state.catalog);
        }

        return DashboardPageLayout(
          children: [
            DashboardHeader(title: t.learn, subtitle: t.learnSubtitle),
            ResponsiveSizedBox.height(2.4),
            if (state is LearningLoading || state is LearningInitial)
              _HomeLoadingShimmer(message: t.loadingLessons)
            else if (state is LearningError)
              _CatalogStatusPanel(
                message: t.couldNotLoadLearningContent,
                actionLabel: t.retry,
                onAction: () => context.read<LearningBloc>().add(
                  const LoadLearningCatalogEvent(forceRefresh: true),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoadedHome(BuildContext context, LearningCatalog catalog) {
    final content = _buildLoadedContent(context, catalog);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredEntrance(index: 0, child: content.first),
          ResponsiveUtils.constrainWidth(
            context: context,
            maxWidth: 680,
            child: Padding(
              padding: ResponsiveUtils.pagePadding(
                context,
                mobileHorizontalPercent: 6,
                tabletHorizontal: 42,
                desktopHorizontal: 56,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 1; index < content.length; index++)
                    StaggeredEntrance(index: index, child: content[index]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLoadedContent(
    BuildContext context,
    LearningCatalog catalog,
  ) {
    final setupLanguage = catalog.setup.learningLanguage;
    final setupLevel = catalog.setup.level;
    final selectedLanguage = catalog.languages.contains(setupLanguage)
        ? setupLanguage
        : catalog.languages.first;
    final selectedLevel = catalog.levels.contains(setupLevel)
        ? setupLevel
        : catalog.levels.first;
    final selectedInterests = catalog.setup.interests.toSet();
    final courses = catalog.courses.where((course) {
      final languageMatches = course.language == selectedLanguage;
      final levelMatches = course.supportsLevel(selectedLevel);
      final interestMatches =
          selectedInterests.isEmpty ||
          selectedInterests.contains(course.category);

      return languageMatches && levelMatches && interestMatches;
    }).toList();
    final wordCount = courses.fold<int>(
      0,
      (sum, course) => sum + course.words.length,
    );
    final quizQuestions = catalog.quizQuestions
        .where((question) => question.language == selectedLanguage)
        .toList();
    final dailyWordTarget = _effectiveTarget(
      catalog.dailyGoal.targetWords,
      wordCount,
    );
    final dailyQuizTarget = _effectiveTarget(
      catalog.dailyGoal.targetQuizzes,
      quizQuestions.length,
    );
    final completedWords = _completedForTarget(
      catalog.dailyGoal.completedWords,
      dailyWordTarget,
    );
    final completedQuizzes = _completedForTarget(
      catalog.dailyGoal.completedQuizzes,
      dailyQuizTarget,
    );
    final t = AppLocalizations(catalog.setup.primaryLanguage);
    final dailyWordsCourse = _buildDailyWordsCourse(
      courses: courses,
      targetWords: dailyWordTarget,
      t: t,
    );
    final dailyQuizQuestions = quizQuestions.take(dailyQuizTarget).toList();
    final firstCourse = courses.isEmpty ? null : courses.first;

    return [
      _LearnHeroPanel(
        catalog: catalog,
        t: t,
        selectedLanguage: selectedLanguage,
        selectedLevel: selectedLevel,
        courseCount: courses.length,
        wordCount: wordCount,
        quizCount: quizQuestions.length,
        onSetupTap: () {
          Navigator.of(
            context,
          ).push(playfulRoute(page: LearningSetupPage(catalog: catalog)));
        },
        onNotificationTap: () async {
          await Navigator.of(context).push(
            playfulRoute(
              page: NotificationsPage(
                homeLanguage: catalog.setup.primaryLanguage,
              ),
            ),
          );
          if (mounted) setState(() {});
        },
        onStartTap: firstCourse == null
            ? null
            : () => _openCourse(
                context,
                firstCourse,
                catalog.plans,
                catalog.setup.primaryLanguage,
              ),
      ),
      _HeroOverlap(
        offset: 22,
        child: _DailyGoalPanel(
          dailyGoal: catalog.dailyGoal,
          t: t,
          completedWords: completedWords,
          targetWords: dailyWordTarget,
          completedQuizzes: completedQuizzes,
          targetQuizzes: dailyQuizTarget,
        ),
      ),
      ResponsiveSizedBox.height(1.8),
      if (!catalog.setup.isConfigured) ...[
        DashboardActionTile(
          icon: Icons.tune_rounded,
          title: t.setUpLearning,
          subtitle: t.setUpLearningSubtitle,
          accent: Appcolors.kdashboardTeal,
          surface: Appcolors.kauthSoftGreen,
          onTap: () {
            Navigator.of(
              context,
            ).push(playfulRoute(page: LearningSetupPage(catalog: catalog)));
          },
        ),
        ResponsiveSizedBox.height(2.2),
      ],
      LearningSectionHeader(title: t.quickStart),
      ResponsiveSizedBox.height(1),
      Row(
        children: [
          Expanded(
            child: _QuickStartTile(
              title: 'Daily Lesson',
              subtitle: t.wordsProgress(completedWords, dailyWordTarget),
              gradientColors: const [
                Appcolors.kquickStartDailyGradientStart,
                Appcolors.kquickStartDailyGradientEnd,
              ],
              leadingIcon: Icons.play_arrow_rounded,
              leadingIconColor: Appcolors.kquickStartDailyPlay,
              artworkAsset: KidsLearningAssets.pencilIcon,
              artworkSize: 96,
              artworkRight: -16,
              artworkBottom: -13,
              onTap: dailyWordsCourse == null
                  ? null
                  : () => _openDailyWords(
                      context,
                      dailyWordsCourse,
                      catalog.setup.primaryLanguage,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickStartTile(
              title: 'Quiz Time',
              subtitle: t.quizzesProgress(completedQuizzes, dailyQuizTarget),
              gradientColors: const [
                Appcolors.kquickStartQuizGradientStart,
                Appcolors.kquickStartQuizGradientEnd,
              ],
              leadingAsset: KidsLearningAssets.questionIcon,
              artworkAsset: KidsLearningAssets.mentalHealthIcon,
              artworkSize: 74,
              artworkRight: -1,
              artworkBottom: 4,
              onTap: dailyQuizQuestions.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).push(
                        playfulRoute(
                          page: QuizPracticePage(
                            questions: dailyQuizQuestions,
                            homeLanguage: catalog.setup.primaryLanguage,
                            contentKey:
                                'daily-quiz-$selectedLanguage-${catalog.dailyGoal.activityDate}',
                          ),
                        ),
                      );
                    },
            ),
          ),
        ],
      ),
      ResponsiveSizedBox.height(2),
      LearningSectionHeader(title: t.recommendedCourses(courses.length)),
      ResponsiveSizedBox.height(1.2),
      if (courses.isEmpty)
        _CatalogStatusPanel(message: t.noLessonsFound)
      else
        for (final course in courses) ...[
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
          ResponsiveSizedBox.height(1.5),
        ],
      ResponsiveSizedBox.height(0.4),
      _StoriesSection(
        stories: catalog.stories,
        t: t,
        onStoryTap: (story) => _openStory(
          context,
          story,
          catalog.plans,
          catalog.setup.primaryLanguage,
        ),
      ),
    ];
  }

  Future<void> _openCourse(
    BuildContext context,
    LearningCourse course,
    List<SubscriptionPlan> plans,
    String homeLanguage,
  ) async {
    if (course.access == LearningAccess.premium) {
      final unlocked = await Navigator.of(context).push<bool>(
        playfulRoute(
          page: PaymentCheckoutPage(plans: plans, homeLanguage: homeLanguage),
        ),
      );
      if (unlocked != true || !context.mounted) return;
    }

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).push(
      playfulRoute(
        page: CourseDetailPage(course: course, homeLanguage: homeLanguage),
      ),
    );
  }

  void _openDailyWords(
    BuildContext context,
    LearningCourse course,
    String homeLanguage,
  ) {
    Navigator.of(context).push(
      playfulRoute(
        page: CourseDetailPage(course: course, homeLanguage: homeLanguage),
      ),
    );
  }

  Future<void> _openStory(
    BuildContext context,
    StoryItem story,
    List<SubscriptionPlan> plans,
    String homeLanguage,
  ) async {
    if (story.access == LearningAccess.premium) {
      final unlocked = await Navigator.of(context).push<bool>(
        playfulRoute(
          page: PaymentCheckoutPage(plans: plans, homeLanguage: homeLanguage),
        ),
      );
      if (unlocked != true || !context.mounted) return;
    }

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).push(
      playfulRoute(
        page: StoryReaderPage(story: story, homeLanguage: homeLanguage),
      ),
    );
  }
}

class _HomeLoadingShimmer extends StatelessWidget {
  const _HomeLoadingShimmer({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: _ShimmerSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LoadingHeroBlock(),
              ResponsiveSizedBox.height(1.6),
              const _LoadingGoalBlock(),
              ResponsiveSizedBox.height(2.2),
              const _LoadingSectionTitle(width: 150),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: _LoadingQuickStartBlock()),
                  SizedBox(width: 12),
                  Expanded(child: _LoadingQuickStartBlock()),
                ],
              ),
              ResponsiveSizedBox.height(2.4),
              const _LoadingSectionTitle(width: 230),
              const SizedBox(height: 12),
              const _LoadingCourseBlock(),
              const SizedBox(height: 12),
              const _LoadingCourseBlock(),
              ResponsiveSizedBox.height(2.4),
              const _LoadingSectionTitle(width: 120),
              const SizedBox(height: 12),
              const _LoadingStoryBlock(),
              const SizedBox(height: 12),
              const _LoadingStoryBlock(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerSurface extends StatefulWidget {
  const _ShimmerSurface({required this.child});

  final Widget child;

  @override
  State<_ShimmerSurface> createState() => _ShimmerSurfaceState();
}

class _ShimmerSurfaceState extends State<_ShimmerSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (motionDisabled(context)) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final shimmerPosition = -1.2 + (_controller.value * 2.4);

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(shimmerPosition - 0.7, -0.45),
              end: Alignment(shimmerPosition + 0.7, 0.45),
              colors: [
                Appcolors.kdashboardSoftSurface.withValues(alpha: 0.62),
                Appcolors.kwhitecolor.withValues(alpha: 0.88),
                Appcolors.kdashboardSoftSurface.withValues(alpha: 0.62),
              ],
              stops: const [0.18, 0.5, 0.82],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _LoadingHeroBlock extends StatelessWidget {
  const _LoadingHeroBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF7FF), Color(0xFFF4EDFF), Color(0xFFEAF8EF)],
        ),
        border: Border.all(color: Appcolors.kdashboardDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SkeletonBox(width: 58, height: 58, radius: 29),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 190, height: 22, radius: 11),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        _SkeletonBox(width: 92, height: 28, radius: 14),
                        SizedBox(width: 8),
                        _SkeletonBox(width: 82, height: 28, radius: 14),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              _SkeletonBox(width: 48, height: 48, radius: 24),
            ],
          ),
          const Spacer(),
          const Row(
            children: [
              Expanded(child: _LoadingMetricBlock()),
              SizedBox(width: 10),
              Expanded(child: _LoadingMetricBlock()),
              SizedBox(width: 10),
              Expanded(child: _LoadingMetricBlock()),
            ],
          ),
          const SizedBox(height: 16),
          const Center(child: _SkeletonBox(width: 220, height: 58, radius: 29)),
        ],
      ),
    );
  }
}

class _LoadingMetricBlock extends StatelessWidget {
  const _LoadingMetricBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Appcolors.kwhitecolor.withValues(alpha: 0.9)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SkeletonBox(width: 36, height: 36, radius: 18),
          SizedBox(height: 8),
          _SkeletonBox(width: 42, height: 18, radius: 9),
          SizedBox(height: 7),
          _SkeletonBox(width: double.infinity, height: 7, radius: 4),
        ],
      ),
    );
  }
}

class _LoadingGoalBlock extends StatelessWidget {
  const _LoadingGoalBlock();

  @override
  Widget build(BuildContext context) {
    return _SkeletonPanel(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
      child: const Column(
        children: [
          Row(
            children: [
              _SkeletonBox(width: 50, height: 50, radius: 17),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 160, height: 18, radius: 9),
                    SizedBox(height: 8),
                    _SkeletonBox(width: 105, height: 13, radius: 7),
                  ],
                ),
              ),
              _SkeletonBox(width: 48, height: 24, radius: 12),
            ],
          ),
          SizedBox(height: 13),
          _SkeletonBox(width: double.infinity, height: 9, radius: 5),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 56, radius: 18)),
              SizedBox(width: 9),
              Expanded(child: _SkeletonBox(height: 56, radius: 18)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingQuickStartBlock extends StatelessWidget {
  const _LoadingQuickStartBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Appcolors.kdashboardDivider),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 47, height: 47, radius: 17),
          Spacer(),
          _SkeletonBox(width: 92, height: 15, radius: 8),
          SizedBox(height: 7),
          _SkeletonBox(width: 72, height: 11, radius: 6),
        ],
      ),
    );
  }
}

class _LoadingCourseBlock extends StatelessWidget {
  const _LoadingCourseBlock();

  @override
  Widget build(BuildContext context) {
    return _SkeletonPanel(
      padding: const EdgeInsets.all(13),
      child: const Row(
        children: [
          _SkeletonBox(width: 82, height: 82, radius: 18),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: double.infinity, height: 18, radius: 9),
                SizedBox(height: 9),
                _SkeletonBox(width: 180, height: 13, radius: 7),
                SizedBox(height: 14),
                _SkeletonBox(width: double.infinity, height: 8, radius: 4),
              ],
            ),
          ),
          SizedBox(width: 12),
          _SkeletonBox(width: 44, height: 44, radius: 22),
        ],
      ),
    );
  }
}

class _LoadingStoryBlock extends StatelessWidget {
  const _LoadingStoryBlock();

  @override
  Widget build(BuildContext context) {
    return _SkeletonPanel(
      padding: const EdgeInsets.fromLTRB(13, 10, 14, 10),
      child: const Row(
        children: [
          _SkeletonBox(width: 88, height: 88, radius: 16),
          SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: double.infinity, height: 19, radius: 10),
                SizedBox(height: 9),
                _SkeletonBox(width: 150, height: 13, radius: 7),
              ],
            ),
          ),
          SizedBox(width: 12),
          _SkeletonBox(width: 48, height: 48, radius: 24),
        ],
      ),
    );
  }
}

class _LoadingSectionTitle extends StatelessWidget {
  const _LoadingSectionTitle({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return _SkeletonBox(width: width, height: 24, radius: 12);
  }
}

class _SkeletonPanel extends StatelessWidget {
  const _SkeletonPanel({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Appcolors.kdashboardDivider),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kprimarycolor.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, required this.height, required this.radius});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Appcolors.kdashboardSoftSurface,
        borderRadius: BorderRadius.circular(radius),
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

class _StoriesSection extends StatelessWidget {
  const _StoriesSection({
    required this.stories,
    required this.t,
    required this.onStoryTap,
  });

  final List<StoryItem> stories;
  final AppLocalizations t;
  final ValueChanged<StoryItem> onStoryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StoriesHeader(title: t.stories),
        ResponsiveSizedBox.height(1),
        if (stories.isEmpty)
          _CatalogStatusPanel(message: t.noStoriesAvailable)
        else
          for (var index = 0; index < stories.length; index++) ...[
            _LearnStoryCard(
              story: stories[index],
              t: t,
              accent: _storyAccent(index),
              onTap: () => onStoryTap(stories[index]),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _StoriesHeader extends StatelessWidget {
  const _StoriesHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 9,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 84,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Appcolors.ksoftCoralSurface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                Positioned(
                  left: -2,
                  top: -9,
                  child: SvgPicture.asset(
                    KidsLearningAssets.openBookIcon,
                    width: 78,
                    height: 58,
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(
                      Appcolors.kmetricInventory,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: -5,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Appcolors.kheroStartButtonBottom,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 104,
            right: 132,
            top: 19,
            child: ResponsiveText(
              title,
              fontSize: 25,
              weight: FontWeight.w900,
              color: Appcolors.ktextdark,
              maxLines: 1,
            ),
          ),
          Positioned(
            right: -4,
            top: 2,
            child: SizedBox(
              width: 118,
              height: 76,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: 0,
                    child: SvgPicture.asset(
                      KidsLearningAssets.cloudIcon,
                      width: 118,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: SvgPicture.asset(
                      KidsLearningAssets.starIcon,
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnStoryCard extends StatelessWidget {
  const _LearnStoryCard({
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
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StoryGoButton(
                  accent: accent,
                  locked: story.access != LearningAccess.free,
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

class _HeroOverlap extends StatelessWidget {
  const _HeroOverlap({required this.child, required this.offset});

  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [Positioned(top: -offset, left: 0, right: 0, child: child)],
      ),
    );
  }
}

int _effectiveTarget(int target, int available) {
  if (available <= 0) return 0;
  if (target <= 0) return available;
  return target > available ? available : target;
}

int _completedForTarget(int completed, int target) {
  if (target <= 0) return 0;
  return completed.clamp(0, target).toInt();
}

LearningCourse? _buildDailyWordsCourse({
  required List<LearningCourse> courses,
  required int targetWords,
  required AppLocalizations t,
}) {
  if (targetWords <= 0) return null;

  final availableCourses = courses
      .where(
        (course) =>
            course.access == LearningAccess.free && course.words.isNotEmpty,
      )
      .toList();
  if (availableCourses.isEmpty) return null;

  final words = <LearningWord>[];
  for (final course in availableCourses) {
    for (final word in course.words) {
      words.add(word);
      if (words.length >= targetWords) break;
    }
    if (words.length >= targetWords) break;
  }

  if (words.isEmpty) return null;

  final firstCourse = availableCourses.first;
  return LearningCourse(
    id: -100,
    title: t.dailyWords,
    language: firstCourse.language,
    levels: firstCourse.levels,
    category: firstCourse.category,
    description: t.wordsProgress(words.length, targetWords),
    access: LearningAccess.free,
    icon: Icons.translate_rounded,
    accent: Appcolors.kprimarycolor,
    words: words,
    progress: 0,
    imagePath: firstCourse.imagePath,
  );
}

class _LearnHeroPanel extends StatelessWidget {
  const _LearnHeroPanel({
    required this.catalog,
    required this.t,
    required this.selectedLanguage,
    required this.selectedLevel,
    required this.courseCount,
    required this.wordCount,
    required this.quizCount,
    required this.onSetupTap,
    required this.onNotificationTap,
    required this.onStartTap,
  });

  final LearningCatalog catalog;
  final AppLocalizations t;
  final String selectedLanguage;
  final String selectedLevel;
  final int courseCount;
  final int wordCount;
  final int quizCount;
  final VoidCallback onSetupTap;
  final VoidCallback onNotificationTap;
  final VoidCallback? onStartTap;

  @override
  Widget build(BuildContext context) {
    final childName = catalog.setup.childName.trim().isEmpty
        ? t.langLexLearner
        : catalog.setup.childName.trim();
    final lessonsProgress = courseCount <= 0
        ? 0.0
        : (courseCount / 10).clamp(0.16, 1.0).toDouble();
    final wordsProgress = wordCount <= 0
        ? 0.0
        : (wordCount / 30).clamp(0.16, 1.0).toDouble();
    final quizProgress = quizCount <= 0
        ? 0.0
        : (quizCount / 15).clamp(0.16, 1.0).toDouble();
    final toolbarTop = MediaQuery.paddingOf(context).top + 4;

    return Container(
      width: double.infinity,
      height: 505,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(KidsLearningAssets.kidsImage),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.high,
          onError: _ignoreImageError,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 18,
            right: 18,
            top: toolbarTop - 9,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroProfileIcon(onTap: onSetupTap),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        _helloLearnerTextSpan(t, childName),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          _SelectedFilterPill(
                            label: selectedLanguage,
                            icon: Icons.translate_rounded,
                            color: Appcolors.kdashboardBlue,
                          ),
                          _SelectedFilterPill(
                            label: selectedLevel,
                            icon: Icons.school_rounded,
                            color: Appcolors.kdashboardPink,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _NotificationBell(
                  t: t,
                  onTap: () {
                    LearningAssetSound.playTap();
                    onNotificationTap();
                  },
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 86,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Appcolors.kscreenWarmBackground.withValues(alpha: 0),
                      Appcolors.kscreenWarmBackground.withValues(alpha: 0.72),
                      Appcolors.kscreenWarmBackground,
                    ],
                    stops: const [0, 0.62, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 112,
            child: Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    value: courseCount.toString(),
                    label: t.lessons,
                    icon: Icons.school_rounded,
                    iconAssetPath: 'assets/icons/open-book.svg',
                    color: Appcolors.kheroLessonsMetric,
                    surface: Appcolors.kheroLessonsMetricSurface,
                    progress: lessonsProgress,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroMetric(
                    value: wordCount.toString(),
                    label: t.wordsTitle,
                    icon: Icons.menu_book_rounded,
                    iconAssetPath: 'assets/icons/learn (1).svg',
                    color: Appcolors.kheroWordsMetric,
                    surface: Appcolors.kheroWordsMetricSurface,
                    progress: wordsProgress,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroMetric(
                    value: quizCount.toString(),
                    label: t.quizTitle,
                    icon: Icons.extension_rounded,
                    iconAssetPath: 'assets/icons/best-practice.svg',
                    color: Appcolors.kheroQuizMetric,
                    surface: Appcolors.kheroQuizMetricSurface,
                    progress: quizProgress,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 54,
            right: 54,
            bottom: 36,
            child: _HeroStartButton(
              label: t.startFirstLesson,
              enabled: onStartTap != null,
              onTap: () {
                LearningAssetSound.playTap();
                onStartTap?.call();
              },
            ),
          ),
        ],
      ),
    );
  }
}

void _ignoreImageError(Object exception, StackTrace? stackTrace) {}

TextSpan _helloLearnerTextSpan(AppLocalizations t, String childName) {
  final greeting = t.helloLearner(childName);
  final nameStart = greeting.indexOf(childName);
  final baseStyle = GoogleFonts.montserrat(
    fontSize: 25,
    fontWeight: FontWeight.w900,
    color: Appcolors.kheroGreetingText,
  );

  if (nameStart < 0) {
    return TextSpan(text: greeting, style: baseStyle);
  }

  final nameEnd = nameStart + childName.length;
  return TextSpan(
    style: baseStyle,
    children: [
      TextSpan(text: greeting.substring(0, nameStart)),
      TextSpan(
        text: greeting.substring(nameStart, nameEnd),
        style: baseStyle.copyWith(color: Appcolors.kredcolor),
      ),
      TextSpan(text: greeting.substring(nameEnd)),
    ],
  );
}

class _HeroProfileIcon extends StatelessWidget {
  const _HeroProfileIcon({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Appcolors.ktransparent,
      child: InkWell(
        onTap: () {
          LearningAssetSound.playTap();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Appcolors.kwhitecolor,
            shape: BoxShape.circle,
            border: Border.all(color: Appcolors.kwhitecolor, width: 3),
            boxShadow: [
              BoxShadow(
                color: Appcolors.kblackcolor.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.face_rounded,
            color: Appcolors.kdashboardBlue,
            size: 35,
          ),
        ),
      ),
    );
  }
}

class _HeroStartButton extends StatelessWidget {
  const _HeroStartButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: enabled,
      child: Material(
        color: Appcolors.ktransparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: enabled
                    ? const [
                        Appcolors.kheroStartButtonTop,
                        Appcolors.kheroStartButtonBottom,
                      ]
                    : const [
                        Appcolors.kheroStartButtonDisabledTop,
                        Appcolors.kheroStartButtonDisabledBottom,
                      ],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Appcolors.kwhitecolor.withValues(alpha: 0.82),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Appcolors.kheroStartButtonBottom.withValues(
                    alpha: enabled ? 0.35 : 0.10,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Appcolors.kdashboardPink,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Appcolors.kwhitecolor.withValues(alpha: 0.65),
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Appcolors.kwhitecolor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: ResponsiveText(
                    label,
                    fontSize: 18,
                    weight: FontWeight.w900,
                    color: Appcolors.kheroStartButtonText,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedFilterPill extends StatelessWidget {
  const _SelectedFilterPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          ResponsiveText(
            label,
            fontSize: 10.6,
            weight: FontWeight.w900,
            color: Color.alphaBlend(
              Appcolors.kblackcolor.withValues(alpha: 0.18),
              color,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.value,
    required this.label,
    required this.icon,
    this.iconAssetPath,
    required this.color,
    required this.surface,
    required this.progress,
  });

  final String value;
  final String label;
  final IconData icon;
  final String? iconAssetPath;
  final Color color;
  final Color surface;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 134,
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surface,
            Color.alphaBlend(
              Appcolors.kwhitecolor.withValues(alpha: 0.16),
              surface,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Appcolors.kwhitecolor.withValues(alpha: 0.78),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _HeroMetricIcon(icon: icon, assetPath: iconAssetPath, color: color),
          const SizedBox(height: 2),
          ResponsiveText(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: Appcolors.kwhitecolor,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Appcolors.kheroMetricTextShadow,
                  offset: Offset(0, 2),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          ResponsiveText(
            label,
            fontSize: 11,
            weight: FontWeight.w900,
            color: Appcolors.kwhitecolor,
            maxLines: 1,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final safeProgress = progress.clamp(0.0, 1.0).toDouble();

                return Stack(
                  children: [
                    Container(
                      height: 7,
                      color: Appcolors.kwhitecolor.withValues(alpha: 0.52),
                    ),
                    AnimatedContainer(
                      duration: AppMotion.normal,
                      curve: AppMotion.playfulCurve,
                      width: constraints.maxWidth * safeProgress,
                      height: 7,
                      color: Appcolors.kwhitecolor.withValues(alpha: 0.92),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricIcon extends StatelessWidget {
  const _HeroMetricIcon({
    required this.icon,
    required this.assetPath,
    required this.color,
  });

  final IconData icon;
  final String? assetPath;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(2, 3),
            child: _HeroMetricGlyph(
              icon: icon,
              assetPath: assetPath,
              color: Appcolors.kblackcolor.withValues(alpha: 0.20),
              size: 37,
            ),
          ),
          Transform.translate(
            offset: const Offset(-1, -1),
            child: _HeroMetricGlyph(
              icon: icon,
              assetPath: assetPath,
              color: Appcolors.kwhitecolor.withValues(alpha: 0.72),
              size: 35,
            ),
          ),
          _HeroMetricGlyph(
            icon: icon,
            assetPath: assetPath,
            color: color,
            size: 38,
          ),
        ],
      ),
    );
  }
}

class _HeroMetricGlyph extends StatelessWidget {
  const _HeroMetricGlyph({
    required this.icon,
    required this.assetPath,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final String? assetPath;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path != null) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    return Icon(icon, color: color, size: size);
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.t, required this.onTap});

  final AppLocalizations t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: context.read<NotificationRepository>().getUnreadCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filled(
              onPressed: onTap,
              tooltip: t.openNotifications,
              icon: const Icon(Icons.notifications_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Appcolors.ksoftPrimarySurface,
                foregroundColor: Appcolors.kprimarycolor,
                minimumSize: const Size(48, 48),
              ),
            ),
            if (count > 0)
              Positioned(
                right: -1,
                top: -3,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 19,
                    minHeight: 19,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: Appcolors.kredcolor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Appcolors.kwhitecolor, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 9 ? '9+' : count.toString(),
                    style: const TextStyle(
                      color: Appcolors.kwhitecolor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DailyGoalPanel extends StatelessWidget {
  const _DailyGoalPanel({
    required this.dailyGoal,
    required this.t,
    required this.completedWords,
    required this.targetWords,
    required this.completedQuizzes,
    required this.targetQuizzes,
  });

  final DailyGoal dailyGoal;
  final AppLocalizations t;
  final int completedWords;
  final int targetWords;
  final int completedQuizzes;
  final int targetQuizzes;

  double get _contentProgress {
    final progressValues = <double>[
      if (targetWords > 0) completedWords / targetWords,
      if (targetQuizzes > 0) completedQuizzes / targetQuizzes,
    ];
    if (progressValues.isEmpty) return 0;
    final average =
        progressValues.reduce((sum, value) => sum + value) /
        progressValues.length;
    return average.clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final contentProgress = _contentProgress;
    final isComplete = contentProgress >= 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Appcolors.kprimarycolor.withValues(alpha: 0.16),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kprimarycolor.withValues(alpha: 0.13),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Appcolors.kgoalIconGradientStart,
                      Appcolors.kgoalIconGradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: Appcolors.kredcolor.withValues(alpha: 0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: Appcolors.kgoalIcon,
                  size: 29,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      isComplete ? t.goalComplete : t.todayGoal,
                      fontSize: 16,
                      weight: FontWeight.w900,
                      color: Appcolors.kgoalTitle,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 3),
                    ResponsiveText(
                      t.dailyGoalMinutesLabel(dailyGoal.dailyGoalMinutes),
                      fontSize: 11.2,
                      weight: FontWeight.w800,
                      color: Appcolors.kdashboardPink,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
              ResponsiveText(
                '${(contentProgress * 100).round()}%',
                fontSize: 21,
                weight: FontWeight.w900,
                color: Appcolors.kgoalProgressText,
              ),
            ],
          ),
          const SizedBox(height: 11),
          _GoalProgressBar(value: contentProgress),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _GoalChip(
                  icon: Icons.menu_book_rounded,
                  label: t.wordsProgress(completedWords, targetWords),
                  color: Appcolors.kdashboardBlue,
                  surface: Appcolors.kgoalChipBlueSurface,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _GoalChip(
                  icon: Icons.emoji_events_rounded,
                  label: t.quizzesProgress(completedQuizzes, targetQuizzes),
                  color: Appcolors.kmetricInventory,
                  surface: Appcolors.kgoalChipGoldSurface,
                  trailingIcon: Icons.auto_awesome_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalProgressBar extends StatelessWidget {
  const _GoalProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(height: 9, color: Appcolors.kgoalProgressTrack),
              AnimatedContainer(
                duration: AppMotion.normal,
                curve: AppMotion.playfulCurve,
                width: constraints.maxWidth * safeValue,
                height: 9,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Appcolors.kgoalProgressGradientStart,
                      Appcolors.kgoalProgressGradientEnd,
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.surface,
    this.trailingIcon,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color surface;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Appcolors.kwhitecolor.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ResponsiveText(
              label,
              fontSize: 11.8,
              weight: FontWeight.w900,
              color: color,
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 4),
            Icon(trailingIcon, color: Appcolors.kgoalSparkle, size: 17),
          ],
        ],
      ),
    );
  }
}

class _QuickStartTile extends StatelessWidget {
  const _QuickStartTile({
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.artworkAsset,
    required this.onTap,
    this.leadingIcon,
    this.leadingAsset,
    this.leadingIconColor,
    this.artworkSize = 80,
    this.artworkRight = 0,
    this.artworkBottom = 0,
  });

  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final String artworkAsset;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final String? leadingAsset;
  final Color? leadingIconColor;
  final double artworkSize;
  final double artworkRight;
  final double artworkBottom;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final primaryColor = gradientColors.last;

    return PressableScale(
      enabled: enabled,
      child: Material(
        color: Appcolors.ktransparent,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  LearningAssetSound.playTap();
                  onTap!();
                },
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 102,
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: enabled
                    ? gradientColors
                    : gradientColors
                          .map(
                            (color) => Color.alphaBlend(
                              Appcolors.kwhitecolor.withValues(alpha: 0.48),
                              color,
                            ),
                          )
                          .toList(),
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Appcolors.kwhitecolor.withValues(alpha: 0.55),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: enabled ? 0.22 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: artworkRight,
                  bottom: artworkBottom,
                  child: Opacity(
                    opacity: enabled ? 1 : 0.56,
                    child: SvgPicture.asset(
                      artworkAsset,
                      width: artworkSize,
                      height: artworkSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 47,
                    height: 47,
                    decoration: BoxDecoration(
                      color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: [
                        BoxShadow(
                          color: Appcolors.kblackcolor.withValues(alpha: 0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _QuickStartBadgeIcon(
                      icon: leadingIcon,
                      asset: leadingAsset,
                      color: leadingIconColor ?? primaryColor,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 38,
                  bottom: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          maxLines: 1,
                          style: GoogleFonts.montserrat(
                            fontSize: 14.6,
                            fontWeight: FontWeight.w900,
                            color: Appcolors.kwhitecolor,
                            height: 0.96,
                            shadows: const [
                              Shadow(
                                color: Appcolors.kquickStartTextShadow,
                                offset: Offset(0, 1.3),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w900,
                          color: Appcolors.kwhitecolor,
                          height: 1,
                          shadows: const [
                            Shadow(
                              color: Appcolors.kquickStartSubtitleShadow,
                              offset: Offset(0, 1),
                              blurRadius: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickStartBadgeIcon extends StatelessWidget {
  const _QuickStartBadgeIcon({this.icon, this.asset, required this.color});

  final IconData? icon;
  final String? asset;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (asset != null) {
      return Center(
        child: SvgPicture.asset(
          asset!,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        ),
      );
    }

    return Icon(icon, color: color, size: 29);
  }
}

class _CatalogStatusPanel extends StatelessWidget {
  const _CatalogStatusPanel({
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
        color: Appcolors.kbackgroundWhitePanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Appcolors.kprimarycolor.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kprimarycolor.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
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
