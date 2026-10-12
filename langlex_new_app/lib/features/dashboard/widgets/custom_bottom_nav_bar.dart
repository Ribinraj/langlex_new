import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  }) : assert(items.length >= 2);

  final List<BottomNavBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(36));
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Appcolors.kbottomGlassTop.withValues(alpha: .94),
                  Appcolors.kbottomGlassBottom.withValues(alpha: .90),
                ],
              ),
              border: Border.all(
                color: Appcolors.kbottomGlassSelected.withValues(alpha: .12),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: SizedBox(
                height: 54,
                child: Row(
                  children: [
                    for (var index = 0; index < items.length; index++)
                      Expanded(
                        child: _BottomNavButton(
                          item: items[index],
                          isSelected: selectedIndex == index,
                          onTap: () => onTap(index),
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
  }
}

class BottomNavBarItem {
  const BottomNavBarItem({
    required this.icon,
    required this.label,
    this.assetPath,
  });

  final IconData icon;
  final String label;
  final String? assetPath;
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final BottomNavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected
        ? Appcolors.kbottomGlassSelected
        : Appcolors.kbottomGlassForeground;

    return Semantics(
      excludeSemantics: true,
      selected: isSelected,
      button: true,
      label: item.label,
      child: Material(
        color: Appcolors.ktransparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: Appcolors.kprimarycolor.withValues(alpha: 0.12),
          highlightColor: Appcolors.kprimarycolor.withValues(alpha: 0.06),
          child: SizedBox(
            height: 54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  duration: AppMotion.normal,
                  curve: AppMotion.playfulCurve,
                  scale: isSelected && !motionDisabled(context) ? 1.08 : 1,
                  child: _NavIcon(item: item, color: foreground),
                ),
                const SizedBox(height: 2),
                ResponsiveText(
                  item.label,
                  fontSize: 9.8,
                  weight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: foreground,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.item, required this.color});

  final BottomNavBarItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final assetPath = item.assetPath;
    if (assetPath != null) {
      return SvgPicture.asset(
        assetPath,
        width: 25,
        height: 25,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    return Icon(item.icon, color: color, size: 25);
  }
}
