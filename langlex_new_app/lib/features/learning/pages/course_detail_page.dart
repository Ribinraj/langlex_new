import 'package:langlex_new_app/core/widgets/app_empty_state.dart';
import 'package:langlex_new_app/features/learning/widgets/content_shimmers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
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
  final Set<String> _revealedWordKeys = {};
  final Map<int, LearningWord> _words = {};
  final Set<int> _loadingPages = {};
  final Set<int> _loadedPages = {};
  final Set<int> _failedPages = {};
  static const _pageSize = 20;
  int _selectedIndex = 0;
  late int _totalWords;
  bool _initializing = true;
  LearningCourse get course => widget.course;
  String get _contentKey => 'course-${course.id}';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _totalWords = course.wordCount;
    if (course.id < 0) {
      for (var i = 0; i < course.words.length; i++) {
        _words[i] = course.words[i];
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    var resume = 0;
    try {
      final progress = await context
          .read<LearningRepository>()
          .getContentProgress(contentType: 'course', contentKey: _contentKey);
      resume = progress.position;
    } catch (_) {
      /* A failed progress lookup must not block a lesson. */
    }
    if (!mounted) return;
    _selectedIndex = _totalWords > 0 ? resume.clamp(0, _totalWords - 1) : 0;
    await _loadPageFor(_selectedIndex);
    if (!mounted) return;
    setState(() => _initializing = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_selectedIndex);
      }
      _recordWordProgress(_selectedIndex);
    });
  }

  Future<void> _loadPageFor(int index) async {
    if (course.id < 0 || !mounted) return;
    final page = index ~/ _pageSize + 1;
    if (_loadingPages.contains(page) || _loadedPages.contains(page)) return;
    _loadingPages.add(page);
    _failedPages.remove(page);
    try {
      final result = await context.read<LearningRepository>().fetchPage(
        'content',
        LearningWord.fromContentJson,
        page: page,
        limit: _pageSize,
        filters: {'course': course.title, 'language': course.language},
      );
      if (!mounted) return;
      setState(() {
        _totalWords = result.total;
        _loadedPages.add(page);
        for (var i = 0; i < result.items.length; i++) {
          _words[(page - 1) * _pageSize + i] = result.items[i];
        }
      });
      if (_selectedIndex ~/ _pageSize + 1 == page && !_initializing) {
        _recordWordProgress(_selectedIndex);
      }
    } catch (_) {
      if (mounted) setState(() => _failedPages.add(page));
    } finally {
      _loadingPages.remove(page);
    }
  }

  void _goTo(int index) {
    if (_totalWords == 0 || !_pageController.hasClients) return;
    _pageController.animateToPage(
      index.clamp(0, _totalWords - 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _recordWordProgress(int index) {
    final word = _words[index];
    if (word == null) return;
    final wordKey = 'content-${word.id}';
    if (_revealedWordKeys.add(wordKey)) {
      if (word.audioPath.isEmpty) {
        LearningAssetSound.play(
          index == _totalWords - 1
              ? KidsLearningAssets.successChimeSound
              : KidsLearningAssets.wordRevealSound,
        );
      }
    }
    context
        .read<LearningRepository>()
        .recordContentItem(
          contentType: 'course',
          contentKey: _contentKey,
          itemKey: wordKey,
          position: index,
          totalItems: _totalWords,
          status: index == _totalWords - 1 ? 'completed' : 'in_progress',
        )
        .then<void>((_) {}, onError: (Object _) {});
  }

  Future<void> _restartPractice() async {
    try {
      await context.read<LearningRepository>().restartContentProgress(
        contentType: 'course',
        contentKey: _contentKey,
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() => _selectedIndex = 0);
    await _loadPageFor(0);
    if (!mounted) return;
    if (_pageController.hasClients) _pageController.jumpToPage(0);
    _recordWordProgress(0);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(widget.homeLanguage);
    return Scaffold(
      backgroundColor: Appcolors.kscreenWarmBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.pagePadding(
            context,
            mobileHorizontalPercent: 5,
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
                _LessonTopBar(
                  title: course.title,
                  t: t,
                  onBack: () => Navigator.of(context).maybePop(),
                  onRestart: _totalWords == 0 ? null : _restartPractice,
                ),
                ResponsiveSizedBox.height(1.2),
                _CourseHeader(
                  course: course,
                  homeLanguage: widget.homeLanguage,
                ),
                ResponsiveSizedBox.height(1.4),
                _LessonWordHeader(
                  title: _totalWords == 0
                      ? t.lessonWords
                      : t.lessonWord(_selectedIndex + 1, _totalWords),
                  accent: course.accent,
                ),
                ResponsiveSizedBox.height(0.8),
                if (_initializing)
                  LessonShimmer(label: t.loadingLessons, showControls: true)
                else if (_totalWords == 0 && _failedPages.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() => _initializing = true);
                      _initialize();
                    },
                    child: const Text('Could not load lesson. Retry'),
                  )
                else if (_totalWords == 0)
                  _EmptyLessonCard(t: t)
                else ...[
                  SizedBox(
                    height: ResponsiveUtils.isMobile(context) ? 440 : 500,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _totalWords,
                      onPageChanged: (index) {
                        setState(() => _selectedIndex = index);
                        _loadPageFor(index);
                        _recordWordProgress(index);
                      },
                      itemBuilder: (context, index) {
                        final word = _words[index];
                        if (word != null) {
                          return SingleChildScrollView(
                            key: PageStorageKey('word-card-$index'),
                            padding: const EdgeInsets.fromLTRB(2, 0, 2, 16),
                            child: _LargeWordCard(
                              word: word,
                              active: index == _selectedIndex,
                              accent: course.accent,
                              t: t,
                            ),
                          );
                        }
                        final page = index ~/ _pageSize + 1;
                        if (_failedPages.contains(page)) {
                          return Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() => _failedPages.remove(page));
                                _loadPageFor(index);
                              },
                              child: const Text('Could not load words. Retry'),
                            ),
                          );
                        }
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _loadPageFor(index),
                        );
                        return LessonShimmer(label: t.loadingLessons);
                      },
                    ),
                  ),
                  ResponsiveSizedBox.height(1),
                  _WordControls(
                    currentIndex: _selectedIndex,
                    itemCount: _totalWords,
                    accent: course.accent,
                    t: t,
                    onPrevious: () => _goTo(_selectedIndex - 1),
                    onNext: () => _goTo(_selectedIndex + 1),
                  ),
                ],
                ResponsiveSizedBox.height(1.4),
                _PracticeHintPanel(accent: course.accent, t: t),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonTopBar extends StatelessWidget {
  const _LessonTopBar({
    required this.title,
    required this.t,
    required this.onBack,
    required this.onRestart,
  });

  final String title;
  final AppLocalizations t;
  final VoidCallback onBack;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 36,
            bottom: 4,
            child: _LessonCloudAsset(width: 62, opacity: 0.55),
          ),
          Positioned(
            right: 48,
            bottom: 2,
            child: _LessonCloudAsset(width: 70, opacity: 0.52),
          ),
          Positioned(
            left: 44,
            top: 8,
            child: SvgPicture.asset(
              KidsLearningAssets.starIcon,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 78,
            top: 8,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Appcolors.kdashboardPink.withValues(alpha: 0.76),
              size: 15,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _RoundLessonButton(
              icon: Icons.arrow_back_rounded,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
              filled: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: GoogleFonts.montserrat(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: Appcolors.kheroGreetingText,
                  height: 1,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _RoundLessonButton(
              icon: Icons.restart_alt_rounded,
              tooltip: t.restartPractice,
              onPressed: onRestart,
              filled: false,
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Appcolors.kprimaryLightColor.withValues(alpha: 0.90),
            Appcolors.kwhitecolor.withValues(alpha: 0.94),
            Appcolors.kmetricInventorySurface.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: course.accent.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            color: course.accent.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 22,
            top: -6,
            child: _LessonCloudAsset(width: 70, opacity: 0.78),
          ),
          Positioned(
            right: 50,
            top: -3,
            child: SvgPicture.asset(
              KidsLearningAssets.starIcon,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 2,
            top: 20,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Appcolors.kgoalSparkle.withValues(alpha: 0.82),
              size: 14,
            ),
          ),
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: course.accent.withValues(alpha: 0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: course.imagePath == null
                      ? LearningOptionalAssetImage(
                          assetPath: KidsLearningAssets.magicBooksImage,
                          accent: course.accent,
                          fallbackIcon: course.icon,
                        )
                      : LearningMediaImage(
                          path: course.imagePath,
                          accent: course.accent,
                          borderRadius: 17,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 74),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        course.title,
                        fontSize: 19,
                        weight: FontWeight.w900,
                        color: Appcolors.kheroGreetingText,
                        overflow: TextOverflow.visible,
                        maxLines: 2,
                        height: 1.05,
                      ),
                      const SizedBox(height: 6),
                      ResponsiveText(
                        '${course.language} • ${course.level}',
                        fontSize: 12,
                        weight: FontWeight.w900,
                        color: Appcolors.kdashboardMutedText,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: _HeaderAccessBadge(
              access: course.access,
              homeLanguage: homeLanguage,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAccessBadge extends StatelessWidget {
  const _HeaderAccessBadge({required this.access, required this.homeLanguage});

  final LearningAccess access;
  final String homeLanguage;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(homeLanguage);
    final label = switch (access) {
      LearningAccess.free => t.free,
      LearningAccess.login => t.login,
      LearningAccess.premium => t.premium,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFDDFDD4),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Appcolors.klearningPlayfulGreen.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            access == LearningAccess.free
                ? Icons.lock_open_rounded
                : Icons.lock_rounded,
            color: Appcolors.kgreencolor,
            size: 15,
          ),
          const SizedBox(width: 4),
          ResponsiveText(
            label,
            fontSize: 11.5,
            weight: FontWeight.w900,
            color: Appcolors.kgreencolor,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _LessonWordHeader extends StatelessWidget {
  const _LessonWordHeader({required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: CustomPaint(painter: _BurstPainter(color: accent)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: _highlightFirstNumber(title, accent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  TextSpan _highlightFirstNumber(String value, Color accent) {
    final style = GoogleFonts.montserrat(
      fontSize: 20,
      fontWeight: FontWeight.w900,
      color: Appcolors.kheroGreetingText,
      height: 1,
    );
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) return TextSpan(text: value, style: style);

    return TextSpan(
      style: style,
      children: [
        TextSpan(text: value.substring(0, match.start)),
        TextSpan(
          text: value.substring(match.start, match.end),
          style: style.copyWith(color: accent),
        ),
        TextSpan(text: value.substring(match.end)),
      ],
    );
  }
}

class _LargeWordCard extends StatelessWidget {
  const _LargeWordCard({
    required this.word,
    required this.active,
    required this.accent,
    required this.t,
  });

  final LearningWord word;
  final bool active;
  final Color accent;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 18,
        isMobile ? 14 : 20,
        isMobile ? 12 : 18,
        isMobile ? 14 : 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Appcolors.kprimaryLightColor.withValues(alpha: 0.66),
            Appcolors.kwhitecolor.withValues(alpha: 0.86),
            Appcolors.kprimaryLightColor.withValues(alpha: 0.64),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: LearningMediaImage(
              path: word.imagePath,
              accent: accent,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          ResponsiveText(
            word.term,
            fontSize: isMobile ? 36 : 48,
            weight: FontWeight.w900,
            color: accent,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: 12),
          ResponsiveText(
            word.meaning,
            fontSize: 16,
            weight: FontWeight.w700,
            color: Appcolors.kheroGreetingText,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Appcolors.kauthSoftGreen,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LearningAudioButton(
                  path: word.listenAudioPath,
                  autoplayPath: word.audioPath,
                  active: active,
                  tooltip: t.listen,
                  filled: true,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: ResponsiveText(
                    t.listen,
                    fontSize: 16,
                    weight: FontWeight.w800,
                    color: Appcolors.kdashboardTeal,
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
        _RoundLessonButton(
          icon: Icons.arrow_back_rounded,
          onPressed: currentIndex == 0
              ? null
              : () {
                  LearningAssetSound.playTap();
                  onPrevious();
                },
          tooltip: t.previousWord,
          filled: false,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: (currentIndex + 1) / itemCount,
            semanticsLabel: t.lessonWord(currentIndex + 1, itemCount),
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
            color: accent,
            backgroundColor: Appcolors.kauthDivider,
          ),
        ),
        const SizedBox(width: 8),
        _RoundLessonButton(
          icon: Icons.arrow_forward_rounded,
          onPressed: currentIndex == itemCount - 1
              ? null
              : () {
                  LearningAssetSound.playTap();
                  onNext();
                },
          tooltip: t.nextWord,
          filled: true,
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Appcolors.kwhitecolor.withValues(alpha: 0.96),
            Appcolors.kdashboardPink.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Appcolors.kdashboardPink.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Appcolors.kdashboardPink.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Appcolors.kdashboardPink,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ResponsiveText(
              t.practiceHint,
              fontSize: 12.5,
              weight: FontWeight.w900,
              color: Appcolors.kheroGreetingText,
              overflow: TextOverflow.visible,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.mic_rounded,
            color: Appcolors.kdashboardPink,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _EmptyLessonCard extends StatelessWidget {
  const _EmptyLessonCard({required this.t});
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) => AppEmptyState(
    kind: EmptyStateKind.lessons,
    title: t.nothingHereYet,
    message: t.emptyLesson,
    actionLabel: Navigator.of(context).canPop() ? t.goBack : null,
    onAction: Navigator.of(context).canPop()
        ? () => Navigator.of(context).maybePop()
        : null,
  );
}

class _RoundLessonButton extends StatelessWidget {
  const _RoundLessonButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.filled,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Material(
      color: Appcolors.ktransparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? Appcolors.kbottomNavActive.withValues(
                      alpha: enabled ? 1 : 0.36,
                    )
                  : Appcolors.kwhitecolor.withValues(
                      alpha: enabled ? 0.95 : 0.62,
                    ),
              border: Border.all(
                color: filled
                    ? Appcolors.kbottomNavActive.withValues(alpha: 0.18)
                    : Appcolors.kprimarycolor.withValues(alpha: 0.22),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Appcolors.kprimarycolor.withValues(
                    alpha: enabled ? 0.10 : 0.04,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: filled
                  ? Appcolors.kwhitecolor
                  : Appcolors.kbottomNavActive.withValues(
                      alpha: enabled ? 1 : 0.42,
                    ),
              size: 25,
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonCloudAsset extends StatelessWidget {
  const _LessonCloudAsset({required this.width, required this.opacity});

  final double width;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      KidsLearningAssets.cloudIcon,
      width: width,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(
        Appcolors.kwhitecolor.withValues(alpha: opacity),
        BlendMode.srcIn,
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width * 0.72, size.height * 0.62);
    final rays = [
      (
        Offset(size.width * 0.15, size.height * 0.18),
        Offset(size.width * 0.02, 0),
      ),
      (
        Offset(size.width * 0.28, size.height * 0.34),
        Offset(size.width * 0.02, size.height * 0.28),
      ),
      (
        Offset(size.width * 0.40, size.height * 0.52),
        Offset(size.width * 0.12, size.height * 0.54),
      ),
    ];

    for (final ray in rays) {
      canvas.drawLine(ray.$1, ray.$2, paint);
    }

    canvas.drawCircle(center, 2.5, paint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
