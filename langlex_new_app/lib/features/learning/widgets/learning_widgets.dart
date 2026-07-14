import 'package:flutter/material.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';

const _playfulCourseColors = [
  Color(0xFF3A86FF),
  Color(0xFFFF6B6B),
  Color(0xFF2EC4B6),
  Color(0xFFFFC857),
  Color(0xFF8B5CF6),
  Color(0xFF5FAE6D),
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
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  playfulAccent.withValues(alpha: 0.15),
                  Appcolors.kwhitecolor.withValues(alpha: 0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: playfulAccent.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: playfulAccent.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GentleFloat(
                      distance: 3,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Appcolors.kwhitecolor.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: playfulAccent.withValues(alpha: 0.16),
                          ),
                        ),
                        child: course.imagePath == null
                            ? Icon(course.icon, color: resolvedAccent, size: 28)
                            : LearningMediaImage(
                                path: course.imagePath,
                                accent: resolvedAccent,
                                borderRadius: 18,
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
                            fontSize: 16,
                            weight: FontWeight.w900,
                            color: Appcolors.ktextdark,
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: 5),
                          ResponsiveText(
                            '${course.language} • ${course.level}',
                            fontSize: 12,
                            weight: FontWeight.w700,
                            color: Appcolors.kdashboardMutedText,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                    LearningAccessPill(
                      access: course.access,
                      homeLanguage: homeLanguage,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ResponsiveText(
                  course.words.isEmpty
                      ? t.emptyLesson
                      : t.coursePracticeDescription(
                          course.words.length,
                          course.category,
                        ),
                  fontSize: 12.5,
                  weight: FontWeight.w600,
                  color: Appcolors.kdashboardMutedText,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _CourseInfoChip(
                      icon: Icons.auto_stories_rounded,
                      label: course.words.isEmpty
                          ? t.contentPending
                          : t.wordsAvailable(course.words.length),
                      color: resolvedAccent,
                    ),
                    const SizedBox(width: 8),
                    _CourseInfoChip(
                      icon: Icons.graphic_eq_rounded,
                      label: t.listen,
                      color: playfulAccent,
                    ),
                    const Spacer(),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Appcolors.kwhitecolor.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: playfulAccent,
                        size: 24,
                      ),
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

class _CourseInfoChip extends StatelessWidget {
  const _CourseInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: ResponsiveText(
                label,
                fontSize: 10.5,
                weight: FontWeight.w900,
                color: color,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LearningAccessPill extends StatelessWidget {
  const LearningAccessPill({
    super.key,
    required this.access,
    this.homeLanguage = 'English',
  });

  final LearningAccess access;
  final String homeLanguage;

  @override
  Widget build(BuildContext context) {
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
            GentleFloat(distance: 2, child: Icon(icon, color: color, size: 22)),
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
