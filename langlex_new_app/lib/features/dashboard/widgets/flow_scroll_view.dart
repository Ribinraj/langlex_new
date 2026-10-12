import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/features/dashboard/widgets/flow_floating_header.dart';

/// One scrolling surface: the header leaves with content and returns on reverse
/// scroll. Its natural height accommodates translations and larger text.
class FlowScrollView extends StatelessWidget {
  const FlowScrollView({
    super.key,
    required this.header,
    this.child,
    this.slivers,
    this.padding = EdgeInsets.zero,
    this.controller,
    this.physics,
  }) : assert((child == null) != (slivers == null));

  final Widget header;
  final Widget? child;
  final List<Widget>? slivers;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    controller: controller,
    physics: physics,
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    slivers: [
      FlowFloatingHeader(
        snapMode: FloatingHeaderSnapMode.scroll,
        animationStyle: motionDisabled(context)
            ? AnimationStyle.noAnimation
            : const AnimationStyle(
                duration: Duration(milliseconds: 220),
                reverseDuration: Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeOutCubic,
              ),
        child: header,
      ),
      if (child != null)
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(child: child),
        )
      else
        ...slivers!,
      SliverToBoxAdapter(
        child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ),
    ],
  );
}

/// Navigation is part of the illustrated content, never a separate app bar.
class FlowPageHeader extends StatelessWidget {
  const FlowPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.artwork,
    this.footer,
    this.actions = const [],
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final String? artwork;
  final Widget? footer;
  final List<Widget> actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
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
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (showBack) ...[
                      const FlowBackButton(),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          maxLines: 1,
                          style: GoogleFonts.montserrat(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            color: Appcolors.klibraryTitle,
                          ),
                        ),
                      ),
                    ),
                    ...actions,
                  ],
                ),
                if (subtitle != null || artwork != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (subtitle != null)
                        Expanded(
                          child: Text(
                            subtitle!,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                              color: Appcolors.klibrarySubtitle,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      if (artwork != null &&
                          MediaQuery.textScalerOf(context).scale(16) < 24) ...[
                        const SizedBox(width: 16),
                        ExcludeSemantics(
                          child: SvgPicture.asset(
                            artwork!,
                            width: 96,
                            height: 88,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (footer != null) ...[const SizedBox(height: 20), footer!],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class FlowBackButton extends StatelessWidget {
  const FlowBackButton({super.key});
  @override
  Widget build(BuildContext context) => BackButton(
    color: Appcolors.klibraryTitle,
    style: IconButton.styleFrom(
      backgroundColor: Appcolors.kwhitecolor.withValues(alpha: .85),
      minimumSize: const Size(48, 48),
    ),
  );
}
