import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/features/dashboard/widgets/flow_scroll_view.dart';

class PracticeCatalogHeader extends StatelessWidget {
  const PracticeCatalogHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artwork,
    this.footer,
    this.artworkAboveFooter = false,
    this.usePageBackground = false,
    this.maxWidth = 760,
  });

  final String title;
  final String subtitle;
  final String artwork;
  final Widget? footer;
  final bool artworkAboveFooter;
  final bool usePageBackground;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: usePageBackground
          ? null
          : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Appcolors.klibrarySkyTop,
                Appcolors.klibrarySkyMiddle,
                Appcolors.kscreenWarmBackground,
              ],
            ),
    ),
    child: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final perched = artworkAboveFooter && footer != null;
                final showArtwork =
                    MediaQuery.textScalerOf(context).scale(16) < 24;
                final artworkSize = constraints.maxWidth < 340 ? 84.0 : 92.0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const FlowBackButton(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.montserrat(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: Appcolors.klibrarySubtitle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      subtitle,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 22,
                                        height: 1.16,
                                        letterSpacing: -.7,
                                        fontWeight: FontWeight.w900,
                                        color: Appcolors.klibraryTitle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ExcludeSemantics(
                                    child: Row(
                                      children: [
                                        for (final (width, color) in [
                                          (
                                            30.0,
                                            Appcolors.klearningPlayfulCoral,
                                          ),
                                          (
                                            18.0,
                                            Appcolors.klearningPlayfulTeal,
                                          ),
                                          (
                                            8.0,
                                            Appcolors.klearningPlayfulYellow,
                                          ),
                                        ])
                                          Container(
                                            width: width,
                                            height: 4,
                                            margin: const EdgeInsets.only(
                                              right: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (showArtwork) ...[
                              const SizedBox(width: 16),
                              if (perched)
                                SizedBox(
                                  width: artworkSize + 12,
                                  height: artworkSize - 20,
                                )
                              else
                                ExcludeSemantics(
                                  child: SizedBox(
                                    width: 84,
                                    height: 84,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 72,
                                          height: 72,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Appcolors.kgoalChipGoldSurface,
                                          ),
                                        ),
                                        Transform.rotate(
                                          angle: -.12,
                                          child: artwork.endsWith('.svg')
                                              ? SvgPicture.asset(
                                                  artwork,
                                                  width: 64,
                                                  height: 64,
                                                )
                                              : Image.asset(
                                                  artwork,
                                                  width: 72,
                                                  height: 72,
                                                  fit: BoxFit.contain,
                                                ),
                                        ),
                                        const Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 18,
                                            color:
                                                Appcolors.kheroStartButtonText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                        if (footer != null) ...[
                          const SizedBox(height: 12),
                          footer!,
                        ],
                      ],
                    ),
                    if (perched && showArtwork)
                      Positioned(
                        right: 12,
                        bottom: 46,
                        child: IgnorePointer(
                          child: ExcludeSemantics(
                            child: artwork.endsWith('.svg')
                                ? SvgPicture.asset(
                                    artwork,
                                    width: artworkSize,
                                    height: artworkSize,
                                  )
                                : Image.asset(
                                    artwork,
                                    width: artworkSize,
                                    height: artworkSize,
                                    fit: BoxFit.contain,
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
  );
}
