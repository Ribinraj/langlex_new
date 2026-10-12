import 'package:langlex_new_app/core/widgets/app_shimmer.dart';
import 'package:langlex_new_app/features/dashboard/widgets/home_language_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/features/dashboard/pages/learn_page.dart';
import 'dart:math' as math;
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/pages/practice_catalog_page.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LearningBloc, LearningState>(
    builder: (context, state) {
      final catalog = state is LearningLoaded ? state.catalog : null;
      final t = AppLocalizations(catalog?.setup.primaryLanguage ?? 'English');
      final name = catalog?.setup.childName.trim() ?? '';
      return LayoutBuilder(
        builder: (context, viewport) {
          final bottom = MediaQuery.paddingOf(context).bottom;
          final availableHeight = viewport.maxHeight - bottom;
          final top = MediaQuery.paddingOf(context).top;
          final heroHeight = math.min(
            top + (viewport.maxWidth * .8).clamp(290.0, 420.0),
            availableHeight * .39,
          );
          final wide =
              viewport.maxWidth >= 680 ||
              viewport.maxWidth > viewport.maxHeight;
          final contentHeight = math.max(
            availableHeight,
            heroHeight + 48 + (wide ? 180 : 360) + 18,
          );
          return ColoredBox(
            color: Appcolors.khomeBackgroundTop,
            child: SingleChildScrollView(
              key: const PageStorageKey('home-scroll'),
              child: Container(
                padding: EdgeInsets.only(bottom: bottom),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      Appcolors.khomeBackgroundTop,
                      Appcolors.khomeBackgroundTop,
                      Appcolors.khomeBackgroundMiddle,
                      Appcolors.khomeBackgroundBottom,
                    ],
                    stops: [0, heroHeight / (contentHeight + bottom), .75, 1],
                  ),
                ),
                child: SizedBox(
                  height: contentHeight,
                  child: Column(
                    children: [
                      _HomeHero(
                        t: t,
                        name: name,
                        isLoading: catalog == null && state is! LearningError,
                        height: heroHeight,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: catalog == null
                                  ? Center(
                                      child: state is LearningError
                                          ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  t.couldNotLoadLearningContent,
                                                  textAlign: TextAlign.center,
                                                ),
                                                TextButton(
                                                  onPressed: () => context
                                                      .read<LearningBloc>()
                                                      .add(
                                                        const LoadLearningCatalogEvent(
                                                          forceRefresh: true,
                                                        ),
                                                      ),
                                                  child: Text(t.retry),
                                                ),
                                              ],
                                            )
                                          : _HomeLoadingShimmer(
                                              wide: wide,
                                              label: t.loadingLessons,
                                            ),
                                    )
                                  : LayoutBuilder(
                                      builder: (context, constraints) {
                                        final columns =
                                            constraints.maxWidth >= 640 ||
                                                viewport.maxWidth >
                                                    viewport.maxHeight
                                            ? 4
                                            : 2;
                                        final choices = [
                                          (
                                            title: t.knowledge,
                                            subtitle: t.knowledgeSubtitle,
                                            artwork: 'assets/icons/animal.svg',
                                            accent: Appcolors.khomeKnowledgeInk,
                                            surface:
                                                Appcolors.khomeKnowledgeTop,
                                            endColor:
                                                Appcolors.khomeKnowledgeBottom,
                                            page: const LearnPage(),
                                          ),
                                          (
                                            title: t.alphabets,
                                            subtitle: t.letterSounds,
                                            artwork:
                                                'assets/icons/alphabet-blocks.svg',
                                            accent: Appcolors.khomeAlphabetInk,
                                            surface: Appcolors.khomeAlphabetTop,
                                            endColor:
                                                Appcolors.khomeAlphabetBottom,
                                            page: PracticeCatalogPage(
                                              resource: 'alphabets',
                                              language: catalog
                                                  .setup
                                                  .learningLanguage,
                                              homeLanguage:
                                                  catalog.setup.primaryLanguage,
                                            ),
                                          ),
                                          (
                                            title: t.stories,
                                            subtitle: t.readAndListen,
                                            artwork:
                                                'assets/icons/fairy-tale.svg',
                                            accent: Appcolors.khomeStoryInk,
                                            surface: Appcolors.khomeStoryTop,
                                            endColor:
                                                Appcolors.khomeStoryBottom,
                                            page: const LearnPage(
                                              storiesOnly: true,
                                            ),
                                          ),
                                          (
                                            title: t.quizzesHeading,
                                            subtitle: t.playAndDiscover,
                                            artwork:
                                                KidsLearningAssets.trophyIcon,
                                            accent: Appcolors.khomeQuizInk,
                                            surface: Appcolors.khomeQuizTop,
                                            endColor: Appcolors.khomeQuizBottom,
                                            page: PracticeCatalogPage(
                                              resource: 'quizzes',
                                              language: catalog
                                                  .setup
                                                  .learningLanguage,
                                              homeLanguage:
                                                  catalog.setup.primaryLanguage,
                                            ),
                                          ),
                                        ];
                                        final tiles = [
                                          for (
                                            var i = 0;
                                            i < choices.length;
                                            i++
                                          )
                                            StaggeredEntrance(
                                              index: i,
                                              duration: AppMotion.normal,
                                              child: _HomeChoice(
                                                title: choices[i].title,
                                                subtitle: choices[i].subtitle,
                                                artwork: choices[i].artwork,
                                                accent: choices[i].accent,
                                                surface: choices[i].surface,
                                                endColor: choices[i].endColor,
                                                horizontal: false,
                                                onTap: () =>
                                                    Navigator.of(context).push(
                                                      playfulRoute(
                                                        page: choices[i].page,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                        ];
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            SizedBox(
                                              height:
                                                  constraints.maxHeight < 240
                                                  ? 36
                                                  : 48,
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        t.letsExplore,
                                                        maxLines: 1,
                                                        style: GoogleFonts.montserrat(
                                                          fontSize: 23,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color: Appcolors
                                                              .kheroGreetingText,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  ExcludeSemantics(
                                                    child: SvgPicture.asset(
                                                      KidsLearningAssets
                                                          .rainbowIcon,
                                                      width: 56,
                                                      height: 40,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: LayoutBuilder(
                                                builder: (context, grid) =>
                                                    Align(
                                                      alignment:
                                                          Alignment.topCenter,
                                                      child: SizedBox(
                                                        height: math.min(
                                                          grid.maxHeight,
                                                          400,
                                                        ),
                                                        child: _HomeCardGrid(
                                                          wide: columns == 4,
                                                          tiles: tiles,
                                                        ),
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _HomeCardGrid extends StatelessWidget {
  const _HomeCardGrid({required this.wide, required this.tiles});

  final bool wide;
  final List<Widget> tiles;

  Widget _row(List<Widget> children) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(width: 14),
        Expanded(child: children[i]),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) => wide
      ? _row(tiles)
      : Column(
          children: [
            Expanded(child: _row(tiles.sublist(0, 2))),
            const SizedBox(height: 12),
            Expanded(child: _row(tiles.sublist(2, 4))),
          ],
        );
}

class _HomeLoadingShimmer extends StatelessWidget {
  const _HomeLoadingShimmer({required this.wide, required this.label});

  final bool wide;
  final String label;

  @override
  Widget build(BuildContext context) {
    final skeleton = LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: constraints.maxHeight < 240 ? 36 : 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: .55,
                child: Container(
                  height: 22,
                  decoration: BoxDecoration(
                    color: Appcolors.kprimarycolor.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, grid) => Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: math.min(grid.maxHeight, 400),
                  child: _HomeCardGrid(
                    wide:
                        constraints.maxWidth >= 640 ||
                        MediaQuery.sizeOf(context).width >
                            MediaQuery.sizeOf(context).height,
                    tiles: const [
                      _HomeSkeletonCard(),
                      _HomeSkeletonCard(),
                      _HomeSkeletonCard(),
                      _HomeSkeletonCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      label: label,
      liveRegion: true,
      excludeSemantics: true,
      child: AppShimmer(child: skeleton),
    );
  }
}

class _HomeSkeletonCard extends StatelessWidget {
  const _HomeSkeletonCard();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Appcolors.kprimarycolor.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Appcolors.kwhitecolor, width: 2),
    ),
    padding: const EdgeInsets.all(18),
    child: Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Appcolors.kprimarycolor.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FractionallySizedBox(
          widthFactor: .75,
          child: Container(
            height: 18,
            decoration: BoxDecoration(
              color: Appcolors.kprimarycolor.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    ),
  );
}

class _HomeChoice extends StatelessWidget {
  const _HomeChoice({
    required this.title,
    required this.subtitle,
    required this.artwork,
    required this.accent,
    required this.surface,
    required this.endColor,
    required this.horizontal,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String artwork;
  final Color accent;
  final Color surface;
  final Color endColor;
  final bool horizontal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(18) / 18;
      final compact = constraints.maxHeight < 205;
      final showSubtitle =
          scale <= 1.35 && constraints.maxHeight >= (horizontal ? 108 : 230);
      final footerHeight = showSubtitle ? 89.0 : (compact ? 49.0 : 60.0);
      final label = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: horizontal
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: GoogleFonts.montserrat(
                fontSize: horizontal ? 21 : 19,
                height: 1.15,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ),
          if (showSubtitle) ...[
            const SizedBox(height: 5),
            SizedBox(
              height: horizontal ? null : 34,
              child: Text(
                subtitle,
                maxLines: 2,
                textAlign: horizontal ? TextAlign.start : TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 11.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
          ],
        ],
      );
      final illustration = ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, bounds) {
            final size = math.min(bounds.maxWidth, bounds.maxHeight);
            return Center(
              child: SizedBox.square(
                dimension: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: -.15,
                      child: Container(
                        width: size * .83,
                        height: size * .72,
                        decoration: BoxDecoration(
                          color: Appcolors.kwhitecolor.withValues(alpha: .24),
                          borderRadius: BorderRadius.circular(size * .3),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: size * .02,
                      left: size * .12,
                      right: size * .12,
                      child: Container(
                        height: size * .1,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .13),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                    SvgPicture.asset(
                      artwork,
                      width: size * .9,
                      height: size * .9,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      return Semantics(
        button: true,
        child: PressableScale(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: endColor.withValues(alpha: .55),
                  offset: const Offset(0, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: surface,
              borderRadius: BorderRadius.circular(26),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [surface, endColor],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Appcolors.kwhitecolor, width: 2),
                ),
                child: InkWell(
                  onTap: onTap,
                  splashColor: Appcolors.kwhitecolor.withValues(alpha: .3),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ExcludeSemantics(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _ActivityBackdrop(
                                footerHeight: horizontal ? 0 : footerHeight,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (horizontal)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: math.min(
                                  constraints.maxHeight - 16,
                                  104,
                                ),
                                child: illustration,
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: label),
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                          child: Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: compact ? 5 : 9,
                                  ),
                                  child: illustration,
                                ),
                              ),
                              SizedBox(
                                height: footerHeight,
                                width: double.infinity,
                                child: Center(child: label),
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
        ),
      );
    },
  );
}

/// Decorative scenery stays behind the artwork and outside the label area.
class _ActivityBackdrop extends CustomPainter {
  const _ActivityBackdrop({required this.footerHeight, required this.color});
  final double footerHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = Appcolors.kwhitecolor.withValues(alpha: .25);
    canvas.drawCircle(
      Offset(size.width * .05, size.height * .1),
      size.width * .2,
      white,
    );
    canvas.drawCircle(
      Offset(size.width * .98, size.height * .53),
      size.width * .23,
      white,
    );
    final dot = Paint()..color = Appcolors.kwhitecolor.withValues(alpha: .8);
    for (final point in [
      const Offset(.16, .25),
      const Offset(.8, .33),
      const Offset(.24, .54),
    ]) {
      canvas.drawCircle(
        Offset(size.width * point.dx, size.height * point.dy),
        2.5,
        dot,
      );
    }
    final star = Paint()..color = Appcolors.kheroStartButtonTop;
    for (final point in [const Offset(.16, .12), const Offset(.85, .58)]) {
      final center = Offset(size.width * point.dx, size.height * point.dy);
      final path = Path()
        ..moveTo(center.dx, center.dy - 6)
        ..quadraticBezierTo(
          center.dx + 1,
          center.dy - 1,
          center.dx + 6,
          center.dy,
        )
        ..quadraticBezierTo(
          center.dx + 1,
          center.dy + 1,
          center.dx,
          center.dy + 6,
        )
        ..quadraticBezierTo(
          center.dx - 1,
          center.dy + 1,
          center.dx - 6,
          center.dy,
        )
        ..quadraticBezierTo(
          center.dx - 1,
          center.dy - 1,
          center.dx,
          center.dy - 6,
        );
      canvas.drawPath(path, star);
    }
    if (footerHeight > 0) {
      final y = size.height - footerHeight;
      final path = Path()
        ..moveTo(0, y + 4)
        ..quadraticBezierTo(size.width * .24, y - 16, size.width * .53, y - 5)
        ..quadraticBezierTo(size.width * .8, y + 6, size.width, y - 5)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = Color.lerp(Appcolors.kwhitecolor, color, .035)!,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityBackdrop oldDelegate) =>
      footerHeight != oldDelegate.footerHeight || color != oldDelegate.color;
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.t,
    required this.name,
    required this.height,
    required this.isLoading,
  });
  final bool isLoading;
  final double height;
  final AppLocalizations t;
  final String name;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      height: height,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage(KidsLearningAssets.kidsImage),
          fit: BoxFit.cover,
          alignment: width > 760
              ? const Alignment(0, -.65)
              : Alignment.topCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 72,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Appcolors.khomeBackgroundTop.withValues(alpha: 0),
                    Appcolors.khomeBackgroundTop,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 12,
            left: 16,
            right: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).openAppDrawerTooltip,
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      style: IconButton.styleFrom(
                        backgroundColor: Appcolors.klanguageAccent,
                        side: BorderSide(
                          color: Appcolors.kwhitecolor.withValues(alpha: .65),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.all(9),
                        iconSize: 26,
                      ),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Appcolors.kwhitecolor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: isLoading
                            ? AppShimmer(
                                child: Container(
                                  key: const ValueKey('home-name-shimmer'),
                                  width: 132,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Appcolors.klanguageSurface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              )
                            : name.isEmpty
                            ? const SizedBox.shrink()
                            : Tooltip(
                                message: t.helloLearner(name),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Appcolors.khomeHeaderEnd,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text.rich(
                                    _helloLearnerTextSpan(t, name),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 124),
                      child: const HomeLanguageSwitcher(),
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

TextSpan _helloLearnerTextSpan(AppLocalizations t, String childName) {
  final greeting = t.helloLearner(childName);
  final nameStart = greeting.indexOf(childName);
  final baseStyle = GoogleFonts.montserrat(
    fontSize: 14,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: Appcolors.ktextgreycolor,
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
        style: baseStyle.copyWith(
          color: Appcolors.klibraryTitle,
          fontWeight: FontWeight.w800,
        ),
      ),
      TextSpan(text: greeting.substring(nameEnd)),
    ],
  );
}
