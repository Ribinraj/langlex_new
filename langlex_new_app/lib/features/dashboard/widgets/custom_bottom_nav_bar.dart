import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';

const _navColors = [
  Color(0xFF8B5CF6),
  Color(0xFF3A86FF),
  Color(0xFFFF6B6B),
  Color(0xFF2EC4B6),
];

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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    _navColors[selectedIndex.clamp(0, _navColors.length - 1)]
                        .withValues(alpha: 0.13),
                    Appcolors.kwhitecolor.withValues(alpha: 0.84),
                  ),
                  Color.alphaBlend(
                    Appcolors.kmetricInventory.withValues(alpha: 0.10),
                    Appcolors.kwhitecolor.withValues(alpha: 0.68),
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: Color.alphaBlend(
                  _navColors[selectedIndex.clamp(0, _navColors.length - 1)]
                      .withValues(alpha: 0.16),
                  Appcolors.kwhitecolor.withValues(alpha: 0.72),
                ),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      _navColors[selectedIndex.clamp(0, _navColors.length - 1)]
                          .withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SizedBox(
              height: 68,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _FloatingSelectionIndicator(
                      itemCount: items.length,
                      selectedIndex: selectedIndex,
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        for (var index = 0; index < items.length; index++)
                          Expanded(
                            child: _BottomNavButton(
                              item: items[index],
                              color: _navColors[index % _navColors.length],
                              isSelected: selectedIndex == index,
                              onTap: () => onTap(index),
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

class BottomNavBarItem {
  const BottomNavBarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _FloatingSelectionIndicator extends StatelessWidget {
  const _FloatingSelectionIndicator({
    required this.itemCount,
    required this.selectedIndex,
  });

  final int itemCount;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final safeIndex = selectedIndex.clamp(0, itemCount - 1);
    final alignmentX = itemCount == 1
        ? 0.0
        : -1.0 + (safeIndex * 2.0) / (itemCount - 1);

    return AnimatedAlign(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      alignment: Alignment(alignmentX, -0.18),
      child: FractionallySizedBox(
        widthFactor: 1 / itemCount,
        heightFactor: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _navColors[safeIndex % _navColors.length],
                  Color.alphaBlend(
                    Appcolors.kwhitecolor.withValues(alpha: 0.18),
                    _navColors[safeIndex % _navColors.length],
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Appcolors.kwhitecolor.withValues(alpha: 0.38),
              ),
              boxShadow: [
                BoxShadow(
                  color: _navColors[safeIndex % _navColors.length].withValues(
                    alpha: 0.28,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final BottomNavBarItem item;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected
        ? Appcolors.kwhitecolor
        : Appcolors.kdashboardNavText;

    return Semantics(
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
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration: AppMotion.normal,
                  curve: AppMotion.playfulCurve,
                  top: isSelected ? 4 : 8,
                  child: AnimatedOpacity(
                    duration: AppMotion.quick,
                    opacity: isSelected ? 1 : 0,
                    child: Icon(
                      Icons.star_rounded,
                      color: Appcolors.kmetricInventory,
                      size: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        duration: AppMotion.normal,
                        curve: AppMotion.playfulCurve,
                        scale: isSelected && !motionDisabled(context)
                            ? 1.18
                            : 1,
                        child: GentleFloat(
                          distance: isSelected ? 2 : 0,
                          child: Container(
                            width: 31,
                            height: 31,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Appcolors.kwhitecolor.withValues(
                                      alpha: 0.20,
                                    )
                                  : color.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              color: isSelected ? foreground : color,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      ResponsiveText(
                        item.label,
                        fontSize: 10.8,
                        weight: FontWeight.w900,
                        color: foreground,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
