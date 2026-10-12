import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({
    super.key,
    required this.t,
    required this.setup,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onNotifications,
    required this.onSetup,
  });

  final AppLocalizations t;
  final LearningSetup? setup;
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onNotifications;
  final VoidCallback? onSetup;

  @override
  Widget build(BuildContext context) {
    final childName = setup?.childName.trim() ?? '';
    return Drawer(
      width: math.min(350, MediaQuery.sizeOf(context).width - 24),
      backgroundColor: Appcolors.kauthBackground,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Appcolors.kauthBackground,
              Appcolors.khomeBackgroundMiddle,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 12, 12),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: SvgPicture.asset(
                        KidsLearningAssets.rainbowIcon,
                        width: 32,
                        height: 32,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'LangLex',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Appcolors.klibraryTitle,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Scaffold.of(context).closeDrawer(),
                      style: IconButton.styleFrom(
                        backgroundColor: Appcolors.kwhitecolor.withValues(
                          alpha: .8,
                        ),
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Appcolors.klibraryTitle,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Appcolors.kprimaryLightColor,
                            Appcolors.khomeBackgroundMiddle,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Appcolors.kwhitecolor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ExcludeSemantics(
                                child: Container(
                                  width: 58,
                                  height: 58,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Appcolors.kwhitecolor.withValues(
                                      alpha: .8,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icons/animal.svg',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  childName.isEmpty
                                      ? t.langLexLearner
                                      : childName,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 20,
                                    height: 1.3,
                                    fontWeight: FontWeight.w800,
                                    color: Appcolors.klibraryTitle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (setup != null && setup!.isConfigured) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _SetupLabel(
                                  icon: Icons.language_rounded,
                                  label: setup!.learningLanguage,
                                ),
                                _SetupLabel(
                                  icon: Icons.school_outlined,
                                  label: setup!.level,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 12),
                      child: Text(
                        t.learning,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Appcolors.ktextgreycolor,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                    for (final entry in [
                      (Icons.home_rounded, t.home),
                      (Icons.search_rounded, t.search),
                      (Icons.person_outline_rounded, t.profile),
                    ].indexed)
                      _DrawerItem(
                        icon: entry.$2.$1,
                        label: entry.$2.$2,
                        selected: selectedIndex == entry.$1,
                        onTap: () => onSelectTab(entry.$1),
                      ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      child: Divider(height: 1, color: Appcolors.kbordercolor),
                    ),
                    if (onSetup != null)
                      _DrawerItem(
                        icon: Icons.tune_rounded,
                        label: t.setUpLearning,
                        onTap: onSetup!,
                      ),
                    _DrawerItem(
                      icon: Icons.notifications_outlined,
                      label: t.notifications,
                      onTap: onNotifications,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupLabel extends StatelessWidget {
  const _SetupLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Appcolors.kwhitecolor.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(icon, size: 16, color: Appcolors.klibraryTitle),
            ),
          ),
          TextSpan(text: label),
        ],
      ),
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Appcolors.klibraryTitle,
      ),
    ),
  );
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      selected: selected,
      child: Material(
        color: selected
            ? Appcolors.kprimaryLightColor
            : Appcolors.kwhitecolor.withValues(alpha: .60),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? Appcolors.kwhitecolor
                        : Appcolors.kauthSoftBlue,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: Appcolors.klibraryTitle, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: Appcolors.klibraryTitle,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: Appcolors.klibraryTitle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
