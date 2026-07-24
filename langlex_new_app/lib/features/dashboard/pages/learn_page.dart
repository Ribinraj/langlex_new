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
import 'package:langlex_new_app/features/learning/pages/story_reader_page.dart';
import 'package:langlex_new_app/features/learning/widgets/learning_widgets.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';
import 'package:langlex_new_app/features/payments/pages/payment_checkout_page.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  String _query = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningBloc, LearningState>(
      builder: (context, state) {
        const fallback = AppLocalizations('English');
        if (state is LearningLoading || state is LearningInitial) {
          return DashboardPageLayout(
            children: [
              DashboardHeader(
                title: fallback.library,
                subtitle: fallback.librarySubtitle,
              ),
              const SizedBox(height: 24),
              _LibraryStatusPanel(message: fallback.loadingLibrary),
            ],
          );
        }

        if (state is LearningError) {
          return DashboardPageLayout(
            children: [
              DashboardHeader(
                title: fallback.library,
                subtitle: fallback.librarySubtitle,
              ),
              ResponsiveSizedBox.height(2.4),
              _LibraryStatusPanel(
                message: fallback.couldNotLoadLearningContent,
                actionLabel: fallback.retry,
                onAction: () => context.read<LearningBloc>().add(
                  const LoadLearningCatalogEvent(forceRefresh: true),
                ),
              ),
            ],
          );
        }

        final catalog = (state as LearningLoaded).catalog;
        return _buildLoadedLibrary(context, catalog);
      },
    );
  }

  Widget _buildLoadedLibrary(BuildContext context, LearningCatalog catalog) {
    final t = AppLocalizations(catalog.setup.primaryLanguage);
    final lowerQuery = _query.trim().toLowerCase();
    final courses = catalog.courses.where((course) {
      final matchesQuery =
          lowerQuery.isEmpty ||
          course.title.toLowerCase().contains(lowerQuery) ||
          course.category.toLowerCase().contains(lowerQuery) ||
          course.language.toLowerCase().contains(lowerQuery);
      final matchesFilter =
          _selectedFilter == 'All' ||
          course.language == _selectedFilter ||
          course.category == _selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();
    final filters = [
      'All',
      ...catalog.languages,
      ...catalog.courses.map((course) => course.category).toSet(),
    ];
    final isMobile = ResponsiveUtils.isMobile(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LibraryHeroSection(
            t: t,
            filters: filters,
            selectedFilter: _selectedFilter,
            onQueryChanged: (value) => setState(() => _query = value),
            onFilterSelected: (filter) =>
                setState(() => _selectedFilter = filter),
          ),
          const SizedBox(height: 0),
          Padding(
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
                  _LibraryCoursesHeader(title: t.coursesTitle(courses.length)),
                  ResponsiveSizedBox.height(1.2),
                  if (courses.isEmpty)
                    _EmptyLibraryState(t: t)
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
                      ResponsiveSizedBox.height(1.4),
                    ],
                  ResponsiveSizedBox.height(1.4),
                  _StoriesHeader(title: t.stories),
                  ResponsiveSizedBox.height(1),
                  if (catalog.stories.isEmpty)
                    _LibraryStatusPanel(message: t.noStoriesAvailable)
                  else
                    for (
                      var index = 0;
                      index < catalog.stories.length;
                      index++
                    ) ...[
                      _StoryTile(
                        story: catalog.stories[index],
                        t: t,
                        accent: _storyAccent(index),
                        onTap: () => _openStory(
                          context,
                          catalog.stories[index],
                          catalog.plans,
                          catalog.setup.primaryLanguage,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  SizedBox(height: isMobile ? 4 : 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

class _LibraryHeroSection extends StatelessWidget {
  const _LibraryHeroSection({
    required this.t,
    required this.filters,
    required this.selectedFilter,
    required this.onQueryChanged,
    required this.onFilterSelected,
  });

  final AppLocalizations t;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 390;
        final contentWidth = width > 680 ? 680.0 : width;
        final sideInset = ((width - contentWidth) / 2) + (compact ? 22 : 28);
        final heroHeight = topInset + (compact ? 246.0 : 264.0);
        final pencilWidth = compact ? 88.0 : 108.0;

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
                child: _LibraryCloudAsset(width: 136, opacity: 0.96),
              ),
              Positioned(
                right: -54,
                bottom: 108,
                child: _LibraryCloudAsset(width: 142, opacity: 0.98),
              ),
              Positioned(
                right: sideInset + pencilWidth + 8,
                top: topInset + 46,
                child: _LibraryCloudAsset(width: 56, opacity: 0.52),
              ),
              Positioned(
                right: sideInset - 6,
                top: topInset + 20,
                child: SvgPicture.asset(
                  'assets/icons/animal.svg',
                  width: pencilWidth,
                  height: compact ? 108 : 130,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                right: sideInset - 8,
                top: topInset + 20,
                child: _LibrarySparkle(size: compact ? 12 : 14),
              ),
              Positioned(
                left: sideInset,
                top: topInset + 12,
                right: sideInset + pencilWidth + 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        t.library,
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
                      t.librarySubtitle,
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
                child: CustomPaint(painter: _LibraryCloudBandPainter()),
              ),
              Positioned(
                left: sideInset - 10,
                right: sideInset - 10,
                bottom: 28,
                child: _LibraryControlPanel(
                  t: t,
                  filters: filters,
                  selectedFilter: selectedFilter,
                  onQueryChanged: onQueryChanged,
                  onFilterSelected: onFilterSelected,
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

class _LibraryCloudAsset extends StatelessWidget {
  const _LibraryCloudAsset({required this.width, required this.opacity});

  final double width;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/cloud.svg',
      width: width,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(
        Appcolors.kwhitecolor.withValues(alpha: opacity),
        BlendMode.srcIn,
      ),
    );
  }
}

class _LibrarySparkle extends StatelessWidget {
  const _LibrarySparkle({required this.size});

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

class _LibraryCloudBandPainter extends CustomPainter {
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

class _LibraryControlPanel extends StatelessWidget {
  const _LibraryControlPanel({
    required this.t,
    required this.filters,
    required this.selectedFilter,
    required this.onQueryChanged,
    required this.onFilterSelected,
  });

  final AppLocalizations t;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LibrarySearchField(hintText: t.searchHint, onChanged: onQueryChanged),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in filters) ...[
                _LibraryFilterPill(
                  label: filter == 'All' ? t.all : filter,
                  selected: selectedFilter == filter,
                  onTap: () => onFilterSelected(filter),
                ),
                const SizedBox(width: 13),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LibrarySearchField extends StatelessWidget {
  const _LibrarySearchField({required this.hintText, required this.onChanged});

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

class _LibraryFilterPill extends StatelessWidget {
  const _LibraryFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: AppMotion.quick,
      curve: AppMotion.playfulCurve,
      scale: selected && !motionDisabled(context) ? 1.03 : 1,
      child: Material(
        color: Appcolors.ktransparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 78),
            child: Ink(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Appcolors.klibraryFilterSelectedTop,
                          Appcolors.klibraryFilterSelectedBottom,
                        ],
                      )
                    : null,
                color: selected ? null : Appcolors.kwhitecolor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? Appcolors.kwhitecolor.withValues(alpha: 0.36)
                      : Appcolors.klibraryFilterBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? Appcolors.klibraryFilterSelectedBottom.withValues(
                            alpha: 0.28,
                          )
                        : Appcolors.kblackcolor.withValues(alpha: 0.06),
                    blurRadius: selected ? 11 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: ResponsiveText(
                  label,
                  fontSize: 13.5,
                  weight: FontWeight.w900,
                  color: selected
                      ? Appcolors.kwhitecolor
                      : Appcolors.kdashboardText,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryCoursesHeader extends StatelessWidget {
  const _LibraryCoursesHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
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

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({required this.t});

  final AppLocalizations t;

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
          Icon(
            Icons.search_off_rounded,
            color: Appcolors.kdashboardMutedIcon,
            size: 34,
          ),
          SizedBox(height: 10),
          ResponsiveText(
            t.noMatchingLessons,
            fontSize: 15,
            weight: FontWeight.w900,
            color: Appcolors.ktextdark,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}
