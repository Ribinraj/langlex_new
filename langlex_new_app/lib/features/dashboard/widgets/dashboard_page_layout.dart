import 'package:flutter/material.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';

class DashboardPageLayout extends StatelessWidget {
  const DashboardPageLayout({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return SingleChildScrollView(
      padding: ResponsiveUtils.pagePadding(
        context,
        mobileHorizontalPercent: 6,
        tabletHorizontal: 42,
        desktopHorizontal: 56,
        top: isMobile ? ResponsiveUtils.hp(3) : 48,
        bottom: 132,
      ),
      child: ResponsiveUtils.constrainWidth(
        context: context,
        maxWidth: 680,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++)
              StaggeredEntrance(index: index, child: children[index]),
          ],
        ),
      ),
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          title,
          fontSize: 30,
          weight: FontWeight.w800,
          color: Appcolors.ktextdark,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: 8),
        ResponsiveText(
          subtitle,
          fontSize: 14,
          weight: FontWeight.w600,
          color: Appcolors.ktextlight,
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }
}

class DashboardActionTile extends StatelessWidget {
  const DashboardActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.surface,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color surface;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: onTap != null,
      child: Material(
        color: Appcolors.ktransparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Appcolors.kwhitecolor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Appcolors.kauthDivider),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        title,
                        fontSize: 15,
                        weight: FontWeight.w800,
                        color: Appcolors.ktextdark,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 4),
                      ResponsiveText(
                        subtitle,
                        fontSize: 12.5,
                        weight: FontWeight.w600,
                        color: Appcolors.kdashboardMutedText,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Appcolors.kdashboardMutedIcon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
