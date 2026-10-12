import 'package:flutter/material.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/colors.dart';

/// One animation for a whole placeholder, with static reduced-motion feedback.
class AppShimmer extends StatefulWidget {
  const AppShimmer({super.key, required this.child, this.label});

  final Widget child;
  final String? label;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionDisabled(context) || !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    liveRegion: widget.label != null,
    excludeSemantics: true,
    child: IgnorePointer(
      child: RepaintBoundary(
        child: motionDisabled(context)
            ? widget.child
            : AnimatedBuilder(
                animation: _controller,
                child: widget.child,
                builder: (context, child) => ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) =>
                      LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: .65),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ).createShader(
                        Rect.fromLTWH(
                          bounds.width * (-1 + 3 * _controller.value),
                          0,
                          bounds.width,
                          bounds.height,
                        ),
                      ),
                  child: child,
                ),
              ),
      ),
    ),
  );
}

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Appcolors.kprimarycolor.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.fraction = 1, this.height = 14});

  final double fraction;
  final double height;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: fraction,
    alignment: Alignment.centerLeft,
    child: SkeletonBlock(height: height),
  );
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Appcolors.kwhitecolor.withValues(alpha: .75),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Appcolors.kauthDivider),
    ),
    child: child,
  );
}
