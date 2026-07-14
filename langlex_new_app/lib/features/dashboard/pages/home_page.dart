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
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/pages/course_detail_page.dart';
import 'package:langlex_new_app/features/learning/pages/learning_setup_page.dart';
import 'package:langlex_new_app/features/learning/pages/quiz_practice_page.dart';
import 'package:langlex_new_app/features/learning/widgets/learning_widgets.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';
import 'package:langlex_new_app/features/notifications/notification_repo.dart';
import 'package:langlex_new_app/features/notifications/pages/notifications_page.dart';
import 'package:langlex_new_app/features/payments/pages/payment_checkout_page.dart';

const _kidSunshine = Color(0xFFFFC857);
const _kidCoral = Color(0xFFFF6B6B);
const _kidBlue = Color(0xFF3A86FF);
const _kidGrape = Color(0xFF8B5CF6);

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
          return DashboardPageLayout(
            children: _buildLoadedContent(context, state.catalog),
          );
        }

        return DashboardPageLayout(
          children: [
            DashboardHeader(title: t.learn, subtitle: t.learnSubtitle),
            ResponsiveSizedBox.height(2.4),
            if (state is LearningLoading || state is LearningInitial)
              _CatalogStatusPanel(message: t.loadingLessons)
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
      ResponsiveSizedBox.height(1.6),
      _DailyGoalPanel(
        dailyGoal: catalog.dailyGoal,
        t: t,
        completedWords: completedWords,
        targetWords: dailyWordTarget,
        completedQuizzes: completedQuizzes,
        targetQuizzes: dailyQuizTarget,
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
              icon: Icons.play_arrow_rounded,
              title: t.dailyWords,
              subtitle: t.wordsProgress(completedWords, dailyWordTarget),
              accent: Appcolors.kprimarycolor,
              backgroundAsset: KidsLearningAssets.magicBooksImage,
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
              icon: Icons.quiz_rounded,
              title: t.quizTitle,
              subtitle: t.quizzesProgress(completedQuizzes, dailyQuizTarget),
              accent: Appcolors.kdashboardTeal,
              backgroundAsset: KidsLearningAssets.wordStarsImage,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF2B8), Color(0xFFE7FFF9), Color(0xFFF3E8FF)],
          stops: [0, 0.54, 1],
        ),
        image: DecorationImage(
          image: const AssetImage(KidsLearningAssets.schoolBackgroundImage),
          fit: BoxFit.cover,
          opacity: 0.58,
          alignment: Alignment.centerRight,
          onError: (_, _) {},
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Appcolors.kwhitecolor, width: 2),
        boxShadow: [
          BoxShadow(
            color: _kidGrape.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 18,
            top: 14,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: _kidSunshine.withValues(alpha: 0.58),
              size: 24,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          t.helloLearner(childName),
                          fontSize: 20,
                          weight: FontWeight.w900,
                          color: Appcolors.ktextdark,
                          overflow: TextOverflow.visible,
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            _SelectedFilterPill(
                              label: selectedLanguage,
                              icon: Icons.translate_rounded,
                              color: _kidBlue,
                            ),
                            _SelectedFilterPill(
                              label: selectedLevel,
                              icon: Icons.school_rounded,
                              color: _kidCoral,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _NotificationBell(
                    t: t,
                    onTap: () {
                      LearningAssetSound.playTap();
                      onNotificationTap();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      value: courseCount.toString(),
                      label: t.lessons,
                      icon: Icons.school_rounded,
                      color: _kidBlue,
                      surface: const Color(0xFFEAF3FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroMetric(
                      value: wordCount.toString(),
                      label: t.wordsTitle,
                      icon: Icons.translate_rounded,
                      color: _kidCoral,
                      surface: const Color(0xFFFFEEEE),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroMetric(
                      value: quizCount.toString(),
                      label: t.quizTitle,
                      icon: Icons.extension_rounded,
                      color: const Color(0xFF5FAE6D),
                      surface: const Color(0xFFEAF8EE),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onStartTap == null
                          ? null
                          : () {
                              LearningAssetSound.playTap();
                              onStartTap!();
                            },
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      label: Text(t.startFirstLesson),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kidGrape,
                        foregroundColor: Appcolors.kwhitecolor,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: () {
                      LearningAssetSound.playTap();
                      onSetupTap();
                    },
                    tooltip: t.updateSetup,
                    icon: const Icon(Icons.palette_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Appcolors.kwhitecolor.withValues(
                        alpha: 0.95,
                      ),
                      foregroundColor: _kidGrape,
                      side: BorderSide(
                        color: _kidGrape.withValues(alpha: 0.18),
                      ),
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ],
              ),
            ],
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
    required this.color,
    required this.surface,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.18), surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.34), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Appcolors.kwhitecolor.withValues(alpha: 0.78),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.20)),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResponsiveText(
                  value,
                  fontSize: 15,
                  weight: FontWeight.w900,
                  color: Appcolors.ktextdark,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ResponsiveText(
                    label,
                    fontSize: 10,
                    weight: FontWeight.w900,
                    color: Color.alphaBlend(
                      Appcolors.kblackcolor.withValues(alpha: 0.16),
                      color,
                    ),
                    maxLines: 1,
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

        return GentleFloat(
          distance: 3,
          child: Stack(
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
                      border: Border.all(
                        color: Appcolors.kwhitecolor,
                        width: 2,
                      ),
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
          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFB).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Appcolors.kmetricInventorySurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: Appcolors.kmetricInventory,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      isComplete ? t.goalComplete : t.todayGoal,
                      fontSize: 15,
                      weight: FontWeight.w900,
                      color: Appcolors.ktextdark,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 3),
                    ResponsiveText(
                      t.dailyGoalMinutesLabel(dailyGoal.dailyGoalMinutes),
                      fontSize: 11.5,
                      weight: FontWeight.w800,
                      color: Appcolors.kdashboardMutedText,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
              ResponsiveText(
                '${(contentProgress * 100).round()}%',
                fontSize: 15,
                weight: FontWeight.w900,
                color: Appcolors.kprimarycolor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: contentProgress,
              minHeight: 9,
              backgroundColor: Appcolors.ksoftPrimarySurface,
              valueColor: const AlwaysStoppedAnimation(Appcolors.kprimarycolor),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _GoalChip(
                icon: Icons.translate_rounded,
                label: t.wordsProgress(completedWords, targetWords),
              ),
              _GoalChip(
                icon: Icons.quiz_rounded,
                label: t.quizzesProgress(completedQuizzes, targetQuizzes),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Appcolors.ksoftPrimarySurface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Appcolors.kprimarycolor, size: 16),
          const SizedBox(width: 6),
          ResponsiveText(
            label,
            fontSize: 11,
            weight: FontWeight.w900,
            color: Appcolors.kprimarycolor,
          ),
        ],
      ),
    );
  }
}

class _QuickStartTile extends StatelessWidget {
  const _QuickStartTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.backgroundAsset,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;
  final String? backgroundAsset;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: onTap != null,
      child: Material(
        color: Appcolors.ktransparent,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  LearningAssetSound.playTap();
                  onTap!();
                },
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            height: 98,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: onTap == null ? 0.10 : 0.26),
                  Appcolors.kwhitecolor.withValues(alpha: 0.96),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (backgroundAsset != null)
                  Positioned(
                    right: -12,
                    bottom: -18,
                    top: -6,
                    child: Opacity(
                      opacity: onTap == null ? 0.10 : 0.24,
                      child: Image.asset(
                        backgroundAsset!,
                        width: 86,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    GentleFloat(
                      distance: 2,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Icon(icon, color: accent, size: 24),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ResponsiveText(
                            title,
                            fontSize: 13.2,
                            weight: FontWeight.w900,
                            color: Appcolors.ktextdark,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          ResponsiveText(
                            subtitle,
                            fontSize: 10.8,
                            weight: FontWeight.w700,
                            color: Appcolors.kdashboardMutedText,
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: onTap == null
                          ? Appcolors.kdashboardMutedIcon
                          : accent,
                      size: 22,
                    ),
                  ],
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
        color: Color.alphaBlend(
          color.withValues(alpha: 0.24),
          Appcolors.kwhitecolor.withValues(alpha: 0.92),
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
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
            fontSize: 11,
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
        color: const Color(0xFFFFFEFB),
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
