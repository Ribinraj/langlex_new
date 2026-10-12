import 'package:langlex_new_app/features/progress/progress_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_bloc.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_state.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';

const _playfulCourseColors = [
  Appcolors.klearningPlayfulBlue,
  Appcolors.klearningPlayfulCoral,
  Appcolors.klearningPlayfulTeal,
  Appcolors.klearningPlayfulYellow,
  Appcolors.klearningPlayfulPurple,
  Appcolors.klearningPlayfulGreen,
];

Color _playfulCourseColor(LearningCourse course) {
  final index = course.id.abs() % _playfulCourseColors.length;
  return _playfulCourseColors[index];
}

class LearningSectionHeader extends StatelessWidget {
  const LearningSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ResponsiveText(
            title,
            fontSize: 18,
            weight: FontWeight.w800,
            color: Appcolors.ktextdark,
            overflow: TextOverflow.visible,
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class LearningFilterChip extends StatelessWidget {
  const LearningFilterChip({
    super.key,
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
      scale: selected && !motionDisabled(context) ? 1.04 : 1,
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          color: selected ? Appcolors.kwhitecolor : Appcolors.kdashboardNavText,
          fontWeight: FontWeight.w800,
        ),
        selectedColor: Appcolors.kprimarycolor,
        backgroundColor: Appcolors.kwhitecolor,
        side: BorderSide(
          color: selected ? Appcolors.kprimarycolor : Appcolors.kauthDivider,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        showCheckmark: false,
      ),
    );
  }
}

class LearningCourseCard extends StatelessWidget {
  const LearningCourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.homeLanguage = 'English',
  });

  final LearningCourse course;
  final VoidCallback? onTap;
  final String homeLanguage;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(homeLanguage);
    final playfulAccent = _playfulCourseColor(course);
    final resolvedAccent = course.accent == Appcolors.ktransparent
        ? playfulAccent
        : course.accent;
    final cardRadius = BorderRadius.circular(24);
    final cardSurface = Color.alphaBlend(
      resolvedAccent.withValues(alpha: 0.12),
      Appcolors.kscreenWarmBackground,
    );

    return PressableScale(
      enabled: onTap != null,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: cardRadius,
          boxShadow: [
            BoxShadow(
              color: Appcolors.kblackcolor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: resolvedAccent.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: cardSurface,
          borderRadius: cardRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    LearningAssetSound.playTap();
                    onTap!();
                  },
            borderRadius: cardRadius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cardSurface,
                borderRadius: cardRadius,
                border: Border.all(
                  color: resolvedAccent.withValues(alpha: 0.42),
                  width: 1.25,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 430;
                  final imageWidth = compact ? 92.0 : 126.0;
                  final imageHeight = compact ? 106.0 : 142.0;
                  final imageRadius = compact ? 20.0 : 24.0;
                  final contentPadding = compact
                      ? const EdgeInsets.fromLTRB(22, 18, 14, 18)
                      : const EdgeInsets.fromLTRB(28, 22, 20, 22);

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: 0,
                        bottom: 0,
                        width: compact ? 118 : 170,
                        height: compact ? 82 : 118,
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _CourseDecorPainter(color: resolvedAccent),
                          ),
                        ),
                      ),
                      Padding(
                        padding: contentPadding,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: imageWidth,
                              height: imageHeight,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: LearningMediaImage(
                                      path: course.imagePath,
                                      accent: resolvedAccent,
                                      width: imageWidth,
                                      height: imageHeight,
                                      borderRadius: imageRadius,
                                      fallbackIcon: course.icon,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: compact ? 14 : 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ResponsiveText(
                                          course.title,
                                          fontSize: compact ? 18 : 21,
                                          weight: FontWeight.w900,
                                          color: Appcolors.ktextdark,
                                          maxLines: 2,
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                      LearningAccessPill(
                                        access: course.access,
                                        homeLanguage: homeLanguage,
                                        leadingSpacing: compact ? 8 : 14,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: compact ? 7 : 8),
                                  ResponsiveText(
                                    '${course.language} • ${course.level}',
                                    fontSize: compact ? 12.5 : 14,
                                    weight: FontWeight.w700,
                                    color: Appcolors.kdashboardMutedText,
                                    maxLines: 1,
                                  ),
                                  TopicProgressBadge(
                                    type: 'course',
                                    contentKey: 'course-${course.id}',
                                    language: course.language,
                                  ),
                                  SizedBox(height: compact ? 14 : 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _CourseChipWrap(
                                          wordsLabel: course.wordCount == 0
                                              ? t.contentPending
                                              : t.wordsCount(course.wordCount),
                                          listenLabel: t.listen,
                                          wordsColor: resolvedAccent,
                                          listenColor: playfulAccent,
                                          compact: compact,
                                        ),
                                      ),
                                      SizedBox(width: compact ? 6 : 8),
                                      _CourseArrowButton(
                                        color: resolvedAccent,
                                        size: compact ? 40 : 50,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }
}

class _CourseDecorPainter extends CustomPainter {
  const _CourseDecorPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      Offset(size.width * 0.70, size.height * 1.02),
      size.width * 0.24,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.92),
      size.width * 0.24,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 1.04, size.height * 0.72),
      size.width * 0.30,
      cloudPaint,
    );

    final path = Path()
      ..moveTo(size.width * 0.02, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height * 0.48,
        size.width * 0.53,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.66,
        size.width * 0.98,
        size.height * 0.26,
      );
    _drawDashedPath(canvas, path, dashPaint);
    _drawLoop(
      canvas,
      Offset(size.width * 0.30, size.height * 0.58),
      size.width * 0.08,
      dashPaint,
    );
    _drawLoop(
      canvas,
      Offset(size.width * 0.70, size.height * 0.37),
      size.width * 0.09,
      dashPaint,
    );
  }

  void _drawLoop(Canvas canvas, Offset center, double radius, Paint paint) {
    final loop = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    _drawDashedPath(canvas, loop, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 7.0;
      const gap = 6.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CourseDecorPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _CourseArrowButton extends StatelessWidget {
  const _CourseArrowButton({required this.color, this.size = 54});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 2),
      ),
      alignment: Alignment.center,
      child: Container(
        width: size - 12,
        height: size - 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(
          Icons.chevron_right_rounded,
          color: Appcolors.kwhitecolor,
          size: size * 0.58,
        ),
      ),
    );
  }
}

class _CourseChipWrap extends StatelessWidget {
  const _CourseChipWrap({
    required this.wordsLabel,
    required this.listenLabel,
    required this.wordsColor,
    required this.listenColor,
    required this.compact,
  });

  final String wordsLabel;
  final String listenLabel;
  final Color wordsColor;
  final Color listenColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: _CourseInfoChip(
            icon: Icons.auto_stories_rounded,
            label: wordsLabel,
            color: wordsColor,
            compact: compact,
          ),
        ),
        SizedBox(width: compact ? 6 : 10),
        Expanded(
          flex: 5,
          child: _CourseInfoChip(
            icon: Icons.graphic_eq_rounded,
            label: listenLabel,
            color: listenColor,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

class _CourseInfoChip extends StatelessWidget {
  const _CourseInfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 30 : 34),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: compact ? 15 : 18),
          SizedBox(width: compact ? 4 : 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ResponsiveText(
                label,
                fontSize: compact ? 10.6 : 12,
                weight: FontWeight.w900,
                color: color,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LearningAccessPill extends StatelessWidget {
  const LearningAccessPill({
    super.key,
    required this.access,
    this.homeLanguage = 'English',
    this.leadingSpacing = 0,
  });

  final LearningAccess access;
  final String homeLanguage;
  final double leadingSpacing;

  @override
  Widget build(BuildContext context) {
    if (access == LearningAccess.login) {
      final authState = context.watch<AuthBloc?>()?.state;
      if (authState is AuthAuthenticated || authState is AuthOtpVerified) {
        return const SizedBox.shrink();
      }
    }

    final t = AppLocalizations(homeLanguage);
    final (label, icon, color, surface) = switch (access) {
      LearningAccess.free => (
        t.free,
        Icons.lock_open_rounded,
        Appcolors.kdashboardTeal,
        Appcolors.kauthSoftGreen,
      ),
      LearningAccess.login => (
        t.login,
        Icons.person_rounded,
        Appcolors.kprimarycolor,
        Appcolors.ksoftPrimarySurface,
      ),
      LearningAccess.premium => (
        t.premium,
        Icons.workspace_premium_rounded,
        Appcolors.kmetricInventory,
        Appcolors.kmetricInventorySurface,
      ),
    };

    return Container(
      margin: EdgeInsetsDirectional.only(start: leadingSpacing),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class LearningMetricTile extends StatelessWidget {
  const LearningMetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Appcolors.kwhitecolor.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Appcolors.kauthDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: double.tryParse(value) ?? 0),
              duration: AppMotion.slow,
              curve: AppMotion.standardCurve,
              builder: (context, animatedValue, _) {
                final display = int.tryParse(value) == null
                    ? value
                    : animatedValue.round().toString();
                return ResponsiveText(
                  display,
                  fontSize: 17,
                  weight: FontWeight.w900,
                  color: Appcolors.ktextdark,
                );
              },
            ),
            const SizedBox(height: 3),
            ResponsiveText(
              label,
              fontSize: 11.5,
              weight: FontWeight.w700,
              color: Appcolors.kdashboardMutedText,
              overflow: TextOverflow.visible,
            ),
          ],
        ),
      ),
    );
  }
}
