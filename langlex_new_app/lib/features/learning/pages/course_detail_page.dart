import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/widgets/learning_widgets.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({
    super.key,
    required this.course,
    required this.homeLanguage,
  });

  final LearningCourse course;
  final String homeLanguage;

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  late final PageController _pageController;
  final Set<String> _dailyRecordedWordKeys = {};
  int _selectedIndex = 0;

  LearningCourse get course => widget.course;
  String get _contentKey => 'course-${course.id}';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSavedProgress();
      _recordWordProgress(0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (course.words.isEmpty) return;
    final nextIndex = index.clamp(0, course.words.length - 1);
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _recordWordProgress(int index) {
    if (index < 0 || index >= course.words.length) return;
    final word = course.words[index];
    LearningAssetSound.play(
      index == course.words.length - 1
          ? KidsLearningAssets.successChimeSound
          : KidsLearningAssets.wordRevealSound,
    );
    final wordKey = word.id > 0
        ? 'content-${word.id}'
        : 'course-${course.id}-${word.term.toLowerCase()}-$index';
    if (_dailyRecordedWordKeys.add(wordKey)) {
      context.read<LearningBloc>().add(
        RecordDailyProgressEvent(
          activityType: 'word',
          activityKey: wordKey,
          estimatedMinutes: 1,
        ),
      );
    }

    context.read<LearningRepository>().recordContentItem(
      contentType: 'course',
      contentKey: _contentKey,
      itemKey: wordKey,
      position: index,
      totalItems: course.words.length,
      status: index == course.words.length - 1 ? 'completed' : 'in_progress',
    );
  }

  Future<void> _loadSavedProgress() async {
    if (course.words.isEmpty) return;
    try {
      final progress = await context
          .read<LearningRepository>()
          .getContentProgress(contentType: 'course', contentKey: _contentKey);
      if (!mounted || progress.position <= 0) return;
      final resumeIndex = progress.position.clamp(0, course.words.length - 1);
      setState(() => _selectedIndex = resumeIndex);
      _pageController.jumpToPage(resumeIndex);
      _recordWordProgress(resumeIndex);
    } catch (_) {
      // Resume should never block the lesson.
    }
  }

  Future<void> _restartPractice() async {
    try {
      await context.read<LearningRepository>().restartContentProgress(
        contentType: 'course',
        contentKey: _contentKey,
      );
    } catch (_) {
      // Local restart still works if the network is unavailable.
    }
    if (!mounted) return;
    setState(() => _selectedIndex = 0);
    _pageController.jumpToPage(0);
    _recordWordProgress(0);
  }

  @override
  Widget build(BuildContext context) {
    final words = course.words;
    final t = AppLocalizations(widget.homeLanguage);

    return Scaffold(
      backgroundColor: Appcolors.kscreenWarmBackground,
      appBar: AppBar(
        title: Text(course.title),
        actions: [
          IconButton(
            onPressed: course.words.isEmpty ? null : _restartPractice,
            tooltip: t.restartPractice,
            icon: const Icon(Icons.replay_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.pagePadding(
          context,
          mobileHorizontalPercent: 6,
          tabletHorizontal: 42,
          desktopHorizontal: 56,
          top: 10,
          bottom: 36,
        ),
        child: ResponsiveUtils.constrainWidth(
          context: context,
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CourseHeader(course: course, homeLanguage: widget.homeLanguage),
              ResponsiveSizedBox.height(2.4),
              LearningSectionHeader(
                title: words.isEmpty
                    ? t.lessonWords
                    : t.lessonWord(_selectedIndex + 1, words.length),
              ),
              ResponsiveSizedBox.height(1.2),
              if (words.isEmpty)
                _EmptyLessonCard(accent: course.accent, t: t)
              else ...[
                SizedBox(
                  height: ResponsiveUtils.isMobile(context) ? 470 : 540,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: words.length,
                    onPageChanged: (index) {
                      setState(() => _selectedIndex = index);
                      _recordWordProgress(index);
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _LargeWordCard(
                          word: words[index],
                          accent: course.accent,
                          t: t,
                        ),
                      );
                    },
                  ),
                ),
                ResponsiveSizedBox.height(1.4),
                _WordControls(
                  currentIndex: _selectedIndex,
                  itemCount: words.length,
                  accent: course.accent,
                  t: t,
                  onPrevious: () => _goTo(_selectedIndex - 1),
                  onNext: () => _goTo(_selectedIndex + 1),
                ),
              ],
              ResponsiveSizedBox.height(2.4),
              _PracticeHintPanel(accent: course.accent, t: t),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseHeader extends StatelessWidget {
  const _CourseHeader({required this.course, required this.homeLanguage});

  final LearningCourse course;
  final String homeLanguage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            course.accent.withValues(alpha: 0.18),
            Appcolors.kwhitecolor.withValues(alpha: 0.98),
            Appcolors.kmetricInventorySurface.withValues(alpha: 0.48),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: course.accent.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: course.accent.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          GentleFloat(
            distance: 4,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Appcolors.kwhitecolor.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: course.accent.withValues(alpha: 0.16),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: course.imagePath == null
                  ? LearningOptionalAssetImage(
                      assetPath: KidsLearningAssets.magicBooksImage,
                      accent: course.accent,
                      fallbackIcon: course.icon,
                    )
                  : LearningMediaImage(
                      path: course.imagePath,
                      accent: course.accent,
                      borderRadius: 22,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  course.title,
                  fontSize: 20,
                  weight: FontWeight.w900,
                  color: Appcolors.ktextdark,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 5),
                ResponsiveText(
                  '${course.language} • ${course.level}',
                  fontSize: 12.5,
                  weight: FontWeight.w800,
                  color: Appcolors.kdashboardMutedText,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
          LearningAccessPill(access: course.access, homeLanguage: homeLanguage),
        ],
      ),
    );
  }
}

class _LargeWordCard extends StatelessWidget {
  const _LargeWordCard({
    required this.word,
    required this.accent,
    required this.t,
  });

  final LearningWord word;
  final Color accent;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Appcolors.kwhitecolor, accent.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: Opacity(
              opacity: 0.82,
              child: LearningOptionalAssetImage(
                assetPath: KidsLearningAssets.wordStarsImage,
                accent: Appcolors.kmetricInventory,
                fallbackIcon: Icons.auto_awesome_rounded,
                width: 46,
                height: 46,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: GentleFloat(
                  distance: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: LearningMediaImage(
                      path: word.imagePath,
                      accent: accent,
                      width: double.infinity,
                      borderRadius: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: ResponsiveText(
                  word.term,
                  fontSize: isMobile ? 48 : 62,
                  weight: FontWeight.w900,
                  color: Appcolors.ktextdark,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Appcolors.kwhitecolor.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.14)),
                ),
                child: ResponsiveText(
                  word.meaning,
                  fontSize: 15,
                  weight: FontWeight.w800,
                  color: Appcolors.kdashboardMutedText,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                height: 62,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LearningAudioButton(
                      path: word.audioPath,
                      tooltip: t.playWord(word.term),
                      filled: true,
                    ),
                    const SizedBox(width: 10),
                    ResponsiveText(
                      t.listen,
                      fontSize: 16,
                      weight: FontWeight.w900,
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.hearing_rounded, color: accent, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WordControls extends StatelessWidget {
  const _WordControls({
    required this.currentIndex,
    required this.itemCount,
    required this.accent,
    required this.t,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentIndex;
  final int itemCount;
  final Color accent;
  final AppLocalizations t;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: currentIndex == 0
              ? null
              : () {
                  LearningAssetSound.playTap();
                  onPrevious();
                },
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: t.previousWord,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < itemCount; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: i == currentIndex ? 22 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i == currentIndex
                        ? accent
                        : Appcolors.kdashboardMutedIcon,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          onPressed: currentIndex == itemCount - 1
              ? null
              : () {
                  LearningAssetSound.playTap();
                  onNext();
                },
          icon: const Icon(Icons.arrow_forward_rounded),
          tooltip: t.nextWord,
        ),
      ],
    );
  }
}

class _PracticeHintPanel extends StatelessWidget {
  const _PracticeHintPanel({required this.accent, required this.t});

  final Color accent;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          GentleFloat(
            distance: 3,
            child: Icon(Icons.auto_awesome_rounded, color: accent, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ResponsiveText(
              t.practiceHint,
              fontSize: 13,
              weight: FontWeight.w800,
              color: Appcolors.ktextdark,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLessonCard extends StatelessWidget {
  const _EmptyLessonCard({required this.accent, required this.t});

  final AppLocalizations t;

  final Color accent;

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
      child: ResponsiveText(
        t.emptyLesson,
        fontSize: 15,
        weight: FontWeight.w900,
        color: accent,
        textAlign: TextAlign.center,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
