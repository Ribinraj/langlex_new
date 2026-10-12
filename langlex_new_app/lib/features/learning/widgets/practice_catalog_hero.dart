import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';

class PracticeCatalogHero extends StatelessWidget {
  const PracticeCatalogHero({
    super.key,
    required this.language,
    required this.title,
    required this.subtitle,
    required this.artwork,
    required this.badgeLabel,
    required this.badgeIcon,
  });
  final String language;
  final String title;
  final String subtitle;
  final String artwork;
  final String badgeLabel;
  final IconData badgeIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showArt =
                    constraints.maxWidth > 290 &&
                    MediaQuery.textScalerOf(context).scale(16) < 24;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.montserrat(
                                  fontSize: 32,
                                  height: 1.12,
                                  fontWeight: FontWeight.w900,
                                  color: Appcolors.klibraryTitle,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                subtitle,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                  color: Appcolors.klibrarySubtitle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showArt) ...[
                          const SizedBox(width: 16),
                          ExcludeSemantics(
                            child: SizedBox(
                              width: constraints.maxWidth > 500 ? 150 : 108,
                              height: 144,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 108,
                                    height: 108,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Appcolors.kwhitecolor.withValues(
                                        alpha: .48,
                                      ),
                                    ),
                                  ),
                                  SvgPicture.asset(
                                    artwork,
                                    width: 100,
                                    height: 110,
                                  ),
                                  const Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Icon(
                                      Icons.auto_awesome_rounded,
                                      color: Appcolors.klibraryTitle,
                                      size: 22,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: SvgPicture.asset(
                                      KidsLearningAssets.starIcon,
                                      width: 24,
                                      height: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CatalogBadge(
                          icon: Icons.language_rounded,
                          label: language,
                        ),
                        _CatalogBadge(icon: badgeIcon, label: badgeLabel),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogBadge extends StatelessWidget {
  const _CatalogBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Appcolors.kwhitecolor.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Appcolors.klibraryTitle),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Appcolors.klibraryTitle,
            ),
          ),
        ),
      ],
    ),
  );
}
