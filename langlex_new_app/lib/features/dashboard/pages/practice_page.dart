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
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/pages/phonics_practice_page.dart';
import 'package:langlex_new_app/features/learning/pages/quiz_practice_page.dart';
import 'package:langlex_new_app/features/learning/pages/story_reader_page.dart';
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
        .where(
          (item) =>
              item.language == selectedLanguage &&
              item.grade == catalog.setup.level,
        )
        .toList();
    final t = AppLocalizations(catalog.setup.primaryLanguage);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PracticeHeroSection(
            t: t,
            storiesCount: stories.length,
            questionsCount: quizQuestions.length,
          ),
          Transform.translate(
            offset: const Offset(0, -14),
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
                    _PracticeAlphabetHeader(title: t.alphabetPractice),
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
                            return _AlphabetCard(item: item, index: index);
                          },
                        ),
                      ),
                    ResponsiveSizedBox.height(2.6),
                    _PracticeModesHeader(title: t.practiceModes),
                    ResponsiveSizedBox.height(1.2),
                    _PracticeModeTile(
                      leadingAssetPath: 'assets/icons/man.svg',
                      artworkAssetPath: 'assets/icons/music.svg',
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
                    _PracticeModeTile(
                      leadingAssetPath: 'assets/icons/conversations.svg',
                      artworkAssetPath: 'assets/icons/quiz.svg',
                      title: t.quiz,
                      subtitle: t.quickQuestions(quizQuestions.length),
                      accent: Appcolors.kbottomNavActive,
                      surface: Appcolors.ksoftPrimarySurface,
                      onTap: quizQuestions.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).push(
                                playfulRoute(
                                  page: QuizPracticePage(
                                    questions: quizQuestions,
                                    homeLanguage: catalog.setup.primaryLanguage,
                                    contentKey:
                                        'practice-quiz-$selectedLanguage',
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeHeroSection extends StatelessWidget {
  const _PracticeHeroSection({
    required this.t,
    required this.storiesCount,
    required this.questionsCount,
  });

  final AppLocalizations t;
  final int storiesCount;
  final int questionsCount;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 390;
        final contentWidth = width > 680 ? 680.0 : width;
        final sideInset = ((width - contentWidth) / 2) + (compact ? 22 : 28);
        final heroHeight = topInset + (compact ? 238.0 : 256.0);
        final rainbowWidth = compact ? 106.0 : 132.0;
        final rainbowHeight = compact ? 92.0 : 112.0;

        return SizedBox(
          height: heroHeight,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Appcolors.klibrarySkyTop,
                        Appcolors.klibrarySkyMiddle,
                        Appcolors.klibrarySkyBottom,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -56,
                bottom: 102,
                child: _PracticeCloudAsset(width: 136, opacity: 0.96),
              ),
              Positioned(
                right: -54,
                bottom: 108,
                child: _PracticeCloudAsset(width: 142, opacity: 0.98),
              ),
              Positioned(
                right: sideInset + rainbowWidth + 8,
                top: topInset + 46,
                child: _PracticeCloudAsset(width: 56, opacity: 0.52),
              ),
              Positioned(
                right: sideInset - 6,
                top: topInset + 20,
                child: SvgPicture.asset(
                  KidsLearningAssets.rainbowIcon,
                  width: rainbowWidth,
                  height: rainbowHeight,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                right: sideInset - 8,
                top: topInset + 20,
                child: _PracticeSparkle(size: compact ? 12 : 14),
              ),
              Positioned(
                left: sideInset,
                top: topInset + 12,
                right: sideInset + rainbowWidth + 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        t.practice,
                        maxLines: 1,
                        style: GoogleFonts.montserrat(
                          fontSize: compact ? 28 : 34,
                          fontWeight: FontWeight.w900,
                          color: Appcolors.klibraryTitle,
                          height: 0.98,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ResponsiveText(
                      t.practiceSubtitle,
                      fontSize: compact ? 14.5 : 16,
                      weight: FontWeight.w600,
                      color: Appcolors.klibrarySubtitle,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                height: 98,
                child: CustomPaint(painter: _PracticeCloudBandPainter()),
              ),
              Positioned(
                left: sideInset - 10,
                right: sideInset - 10,
                bottom: 34,
                child: _PracticeHeroStatsPanel(
                  storiesCount: storiesCount,
                  questionsCount: questionsCount,
                  t: t,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -1,
                height: 42,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Appcolors.kscreenWarmBackground.withValues(alpha: 0),
                          Appcolors.kscreenWarmBackground,
                        ],
                      ),
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

class _PracticeCloudAsset extends StatelessWidget {
  const _PracticeCloudAsset({required this.width, required this.opacity});

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

class _PracticeSparkle extends StatelessWidget {
  const _PracticeSparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      size: size,
      color: Appcolors.klibrarySparkle.withValues(alpha: 0.92),
    );
  }
}

class _PracticeCloudBandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Appcolors.kscreenWarmBackground.withValues(alpha: 0.98);
    final path = Path()
      ..moveTo(0, size.height * 0.54)
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.08,
        size.width * 0.26,
        size.height * 0.78,
        size.width * 0.42,
        size.height * 0.38,
      )
      ..cubicTo(
        size.width * 0.55,
        size.height * 0.02,
        size.width * 0.68,
        size.height * 0.78,
        size.width * 0.82,
        size.height * 0.34,
      )
      ..cubicTo(
        size.width * 0.91,
        size.height * 0.06,
        size.width,
        size.height * 0.32,
        size.width,
        size.height * 0.18,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PracticeHeroStatsPanel extends StatelessWidget {
  const _PracticeHeroStatsPanel({
    required this.storiesCount,
    required this.questionsCount,
    required this.t,
  });

  final int storiesCount;
  final int questionsCount;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Row(
        children: [
          Expanded(
            child: _PracticeHeroCard(
              value: storiesCount.toString(),
              label: t.stories,
              assetPath: 'assets/icons/comic.svg',
              accent: Appcolors.kheroStartButtonBottom,
              surface: const Color(0xFFFFEDB2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _PracticeHeroCard(
              value: questionsCount.toString(),
              label: t.questions,
              assetPath: 'assets/icons/conversations.svg',
              accent: Appcolors.kbottomNavActive,
              surface: const Color(0xFFEADDFF),
              iconColor: Appcolors.kbottomNavActive,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeHeroCard extends StatelessWidget {
  const _PracticeHeroCard({
    required this.value,
    required this.label,
    required this.assetPath,
    required this.accent,
    required this.surface,
    this.iconColor,
  });

  final String value;
  final String label;
  final String assetPath;
  final Color accent;
  final Color surface;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Appcolors.kwhitecolor.withValues(alpha: 0.96),
            Color.alphaBlend(
              Appcolors.kwhitecolor.withValues(alpha: 0.18),
              surface,
            ),
            surface,
          ],
          stops: const [0, 0.48, 1],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.78), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.24),
            blurRadius: 10,
            spreadRadius: -3,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Appcolors.kblackcolor.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.34), width: 2),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -2,
            top: -5,
            child: Icon(Icons.auto_awesome_rounded, color: accent, size: 18),
          ),
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Appcolors.kwhitecolor.withValues(alpha: 0.42),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Appcolors.kwhitecolor.withValues(alpha: 0.54),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.09),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  assetPath,
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                  colorFilter: iconColor == null
                      ? null
                      : ColorFilter.mode(iconColor!, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      value,
                      fontSize: 25,
                      weight: FontWeight.w900,
                      color: Appcolors.kheroGreetingText,
                      maxLines: 1,
                    ),
                    ResponsiveText(
                      label,
                      fontSize: 12.5,
                      weight: FontWeight.w900,
                      color: Appcolors.kdashboardMutedText,
                      maxLines: 1,
                    ),
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

class _PracticeModesHeader extends StatelessWidget {
  const _PracticeModesHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/icons/rocket.svg',
          width: 36,
          height: 36,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: ResponsiveText(
            title,
            fontSize: 20,
            weight: FontWeight.w900,
            color: Appcolors.ktextdark,
            overflow: TextOverflow.visible,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _PracticeModeTile extends StatelessWidget {
  const _PracticeModeTile({
    required this.leadingAssetPath,
    required this.artworkAssetPath,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.surface,
    this.tileHeight = 82,
    this.onTap,
  });

  final String leadingAssetPath;
  final String artworkAssetPath;
  final String title;
  final String subtitle;
  final Color accent;
  final Color surface;
  final double tileHeight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.58,
      child: PressableScale(
        enabled: enabled,
        child: Material(
          color: Appcolors.ktransparent,
          child: InkWell(
            onTap: enabled
                ? () {
                    LearningAssetSound.playTap();
                    onTap?.call();
                  }
                : null,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              height: tileHeight,
              padding: const EdgeInsets.fromLTRB(13, 10, 12, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    surface,
                    Color.alphaBlend(
                      Appcolors.kwhitecolor.withValues(alpha: 0.38),
                      surface,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withValues(alpha: 0.30)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Appcolors.kwhitecolor.withValues(alpha: 0.70),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Appcolors.kwhitecolor.withValues(alpha: 0.75),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      leadingAssetPath,
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          title,
                          fontSize: 16,
                          weight: FontWeight.w900,
                          color: Appcolors.ktextdark,
                          overflow: TextOverflow.visible,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        ResponsiveText(
                          subtitle,
                          fontSize: 12.5,
                          weight: FontWeight.w800,
                          color: Appcolors.kdashboardMutedText,
                          overflow: TextOverflow.visible,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 78,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Positioned(
                          left: 0,
                          child: SvgPicture.asset(
                            artworkAssetPath,
                            width: 54,
                            height: 54,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Appcolors.kwhitecolor.withValues(
                                alpha: 0.78,
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.24),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            enabled
                                ? Icons.chevron_right_rounded
                                : Icons.lock_rounded,
                            color: Appcolors.kwhitecolor,
                            size: enabled ? 32 : 22,
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
      ),
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

  @override
  void didUpdateWidget(covariant _StoryPracticeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasSameStories(oldWidget.stories, widget.stories)) {
      _storyFuture = _nextStory();
    }
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
        return _PracticeModeTile(
          leadingAssetPath: KidsLearningAssets.openBookIcon,
          artworkAssetPath: 'assets/icons/fairy-tale.svg',
          title: widget.t.storyReader,
          subtitle: widget.t.storyReaderSubtitle,
          accent: Appcolors.kmetricInventory,
          surface: Appcolors.kmetricInventorySurface,
          tileHeight: 94,
          onTap: story == null
              ? null
              : () async {
                  await Navigator.of(context).push<bool>(
                    playfulRoute(
                      page: StoryReaderPage(
                        story: story,
                        homeLanguage: widget.homeLanguage,
                      ),
                    ),
                  );
                  if (!mounted) return;
                  setState(() {
                    _storyFuture = _nextStory();
                  });
                },
        );
      },
    );
  }

  bool _hasSameStories(List<StoryItem> first, List<StoryItem> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index].id != second[index].id ||
          first[index].title != second[index].title) {
        return false;
      }
    }
    return true;
  }
}

class _PracticeAlphabetHeader extends StatelessWidget {
  const _PracticeAlphabetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          KidsLearningAssets.starIcon,
          width: 30,
          height: 30,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ResponsiveText(
            title,
            fontSize: 20,
            weight: FontWeight.w900,
            color: Appcolors.ktextdark,
            overflow: TextOverflow.visible,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _AlphabetCard extends StatelessWidget {
  const _AlphabetCard({required this.item, required this.index});

  final AlphabetItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = _alphabetCardPalette(index);

    return Container(
      width: 112,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
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
                  color: palette.accent,
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
            color: palette.accent,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

({Color surface, Color border, Color accent}) _alphabetCardPalette(int index) {
  const palettes = [
    (
      surface: Color(0xFFEFFFF7),
      border: Color(0xFF91E8C6),
      accent: Color(0xFF18B76B),
    ),
    (
      surface: Color(0xFFEAF7FF),
      border: Color(0xFF93D9FF),
      accent: Color(0xFF1589D8),
    ),
    (
      surface: Color(0xFFFFEEF7),
      border: Color(0xFFFF9DCA),
      accent: Color(0xFFE93682),
    ),
    (
      surface: Color(0xFFF5EEFF),
      border: Color(0xFFC7A8FF),
      accent: Color(0xFF8B49FF),
    ),
  ];

  return palettes[index % palettes.length];
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
