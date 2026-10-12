import 'package:flutter/material.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/core/widgets/app_shimmer.dart';

enum CatalogSkeleton {
  courses,
  stories,
  alphabets,
  quizzes,
  sounds,
  notifications,
}

/// Mirrors each catalogue's card geometry at the same responsive breakpoints.
class CatalogShimmer extends StatelessWidget {
  const CatalogShimmer({
    super.key,
    required this.kind,
    required this.label,
    this.itemCount = 4,
    this.showHeading = false,
  });

  final CatalogSkeleton kind;
  final String label;
  final int itemCount;
  final bool showHeading;

  @override
  Widget build(BuildContext context) => AppShimmer(
    label: label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeading) ...[
          const SkeletonLine(fraction: .55, height: 22),
          const SizedBox(height: 18),
        ],
        if (kind == CatalogSkeleton.alphabets)
          _AlphabetGrid(count: itemCount)
        else
          for (var i = 0; i < itemCount; i++) ...[
            switch (kind) {
              CatalogSkeleton.courses => const _CourseCard(),
              CatalogSkeleton.stories => const _StoryCard(),
              CatalogSkeleton.quizzes => const _QuizCard(),
              CatalogSkeleton.sounds => const _SoundCard(),
              CatalogSkeleton.notifications => const _NotificationCard(),
              CatalogSkeleton.alphabets => const SizedBox.shrink(),
            },
            if (i < itemCount - 1)
              SizedBox(
                height: switch (kind) {
                  CatalogSkeleton.stories ||
                  CatalogSkeleton.notifications => 12,
                  CatalogSkeleton.quizzes => 16,
                  _ => 14,
                },
              ),
          ],
      ],
    ),
  );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 430;
      return SkeletonCard(
        padding: compact
            ? const EdgeInsets.fromLTRB(22, 18, 14, 18)
            : const EdgeInsets.fromLTRB(28, 22, 20, 22),
        child: Row(
          children: [
            SkeletonBlock(
              width: compact ? 92 : 126,
              height: compact ? 106 : 142,
              radius: compact ? 20 : 24,
            ),
            SizedBox(width: compact ? 14 : 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLine(fraction: .85, height: 22),
                  const SizedBox(height: 8),
                  const SkeletonLine(fraction: .6),
                  SizedBox(height: compact ? 14 : 20),
                  Row(
                    children: [
                      const Expanded(
                        child: SkeletonLine(fraction: .8, height: 26),
                      ),
                      SkeletonBlock(
                        width: compact ? 40 : 50,
                        height: compact ? 40 : 50,
                        radius: 25,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _StoryCard extends StatelessWidget {
  const _StoryCard();

  @override
  Widget build(BuildContext context) => const SkeletonCard(
    radius: 20,
    padding: EdgeInsets.fromLTRB(13, 10, 14, 10),
    child: Row(
      children: [
        SkeletonBlock(width: 88, height: 88, radius: 16),
        SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(height: 22),
              SizedBox(height: 7),
              SkeletonLine(fraction: .8, height: 13),
            ],
          ),
        ),
        SizedBox(width: 10),
        SkeletonBlock(width: 58, height: 58, radius: 29),
      ],
    ),
  );
}

class _QuizCard extends StatelessWidget {
  const _QuizCard();

  @override
  Widget build(BuildContext context) => const SkeletonCard(
    radius: 26,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(width: 52, height: 52, radius: 17),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(fraction: .35, height: 12),
                  SizedBox(height: 5),
                  SkeletonLine(fraction: .8, height: 24),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 18),
        SkeletonLine(fraction: .35, height: 14),
        SizedBox(height: 16),
        SkeletonBlock(height: 50, radius: 16),
      ],
    ),
  );
}

class _SoundCard extends StatelessWidget {
  const _SoundCard();

  @override
  Widget build(BuildContext context) => SkeletonCard(
    radius: 22,
    child: LayoutBuilder(
      builder: (context, constraints) {
        const title = Row(
          children: [
            SkeletonBlock(width: 48, height: 48, radius: 15),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(fraction: .8, height: 24),
                  SizedBox(height: 6),
                  SkeletonLine(fraction: .5, height: 13),
                ],
              ),
            ),
          ],
        );
        final stacked =
            constraints.maxWidth < 460 ||
            MediaQuery.textScalerOf(context).scale(16) > 22;
        return stacked
            ? const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  SizedBox(height: 16),
                  SkeletonBlock(height: 48, radius: 14),
                ],
              )
            : const Row(
                children: [
                  Expanded(child: title),
                  SizedBox(width: 20),
                  SkeletonBlock(width: 112, height: 48, radius: 14),
                ],
              );
      },
    ),
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard();

  @override
  Widget build(BuildContext context) => const SkeletonCard(
    radius: 22,
    padding: EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBlock(width: 42, height: 42, radius: 15),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: SkeletonLine(fraction: .85, height: 17)),
                  SizedBox(width: 8),
                  SkeletonBlock(width: 40, height: 11),
                ],
              ),
              SizedBox(height: 6),
              SkeletonLine(),
              SizedBox(height: 6),
              SkeletonLine(fraction: .7),
              SizedBox(height: 10),
              SkeletonBlock(width: 64, height: 26, radius: 13),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AlphabetGrid extends StatelessWidget {
  const _AlphabetGrid({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(
        1.0,
        1.6,
      );
      final columns = ((constraints.maxWidth + 12) / (130 * scale + 12))
          .floor()
          .clamp(1, 4);
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < count; i++)
            SizedBox(
              width: (constraints.maxWidth - (columns - 1) * 12) / columns,
              child: SkeletonCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SkeletonBlock(height: 96, radius: 18),
                    const SizedBox(height: 12),
                    SkeletonBlock(height: 44 * scale),
                    const SizedBox(height: 8),
                    const SkeletonBlock(height: 48, radius: 14),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// Sized like the word PageView, including its artwork, term and audio control.
class LessonShimmer extends StatelessWidget {
  const LessonShimmer({
    super.key,
    required this.label,
    this.showControls = false,
  });
  final String label;
  final bool showControls;

  @override
  Widget build(BuildContext context) {
    final mobile = ResponsiveUtils.isMobile(context);
    return AppShimmer(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: mobile ? 440 : 500,
            child: SkeletonCard(
              radius: 22,
              padding: EdgeInsets.symmetric(
                horizontal: mobile ? 12 : 18,
                vertical: mobile ? 14 : 20,
              ),
              child: Column(
                children: [
                  const Expanded(
                    child: SkeletonBlock(height: double.infinity, radius: 18),
                  ),
                  const SizedBox(height: 16),
                  SkeletonLine(fraction: .55, height: mobile ? 40 : 52),
                  const SizedBox(height: 12),
                  const SkeletonLine(fraction: .8, height: 18),
                  const SizedBox(height: 20),
                  const SkeletonBlock(height: 56, radius: 24),
                ],
              ),
            ),
          ),
          if (showControls) ...[
            ResponsiveSizedBox.height(1),
            const SkeletonBlock(height: 64, radius: 22),
          ],
        ],
      ),
    );
  }
}

class LearningProgressShimmer extends StatelessWidget {
  const LearningProgressShimmer({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => AppShimmer(
    label: label,
    child: const SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLine(fraction: .6, height: 22),
          SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SkeletonBlock(width: 140, height: 30, radius: 15),
              SkeletonBlock(width: 110, height: 30, radius: 15),
              SkeletonBlock(width: 90, height: 30, radius: 15),
            ],
          ),
          SizedBox(height: 20),
          SkeletonLine(fraction: .5, height: 18),
          SizedBox(height: 12),
          SkeletonBlock(height: 10),
          SizedBox(height: 16),
          SkeletonLine(fraction: .75),
        ],
      ),
    ),
  );
}

class PracticeShimmer extends StatelessWidget {
  const PracticeShimmer({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => AppShimmer(
    label: label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SkeletonLine(fraction: .6, height: 24),
        const SizedBox(height: 12),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => const SizedBox(
              width: 112,
              child: SkeletonCard(
                padding: EdgeInsets.all(14),
                radius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(width: 42, height: 40),
                    Spacer(),
                    SkeletonLine(height: 14),
                    SizedBox(height: 6),
                    SkeletonLine(fraction: .6, height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const SkeletonBlock(height: 82, radius: 22),
        const SizedBox(height: 26),
        const SkeletonLine(fraction: .5, height: 22),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++) ...[
          const PracticeModeShimmerCard(),
          if (i < 2) const SizedBox(height: 14),
        ],
      ],
    ),
  );
}

class PracticeModeShimmerCard extends StatelessWidget {
  const PracticeModeShimmerCard({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonCard(
    padding: EdgeInsets.all(18),
    child: Row(
      children: [
        SkeletonBlock(width: 58, height: 58, radius: 29),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(fraction: .85, height: 18),
              SizedBox(height: 8),
              SkeletonLine(fraction: .65, height: 13),
            ],
          ),
        ),
        SizedBox(width: 14),
        SkeletonBlock(width: 46, height: 46, radius: 23),
      ],
    ),
  );
}
