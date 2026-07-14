import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppMotion {
  const AppMotion._();

  static const quick = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const entranceGap = Duration(milliseconds: 55);

  static const playfulCurve = Curves.easeOutBack;
  static const standardCurve = Curves.easeOutCubic;
}

bool motionDisabled(BuildContext context) {
  return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = const Offset(0, 0.08),
    this.duration = AppMotion.slow,
  });

  final Widget child;
  final int index;
  final Offset offset;
  final Duration duration;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.standardCurve,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curved);
    _scale = Tween<double>(begin: 0.98, end: 1).animate(curved);
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  Future<void> _play() async {
    if (!mounted) return;
    if (motionDisabled(context)) {
      _controller.value = 1;
      return;
    }

    final delayMs = widget.index * AppMotion.entranceGap.inMilliseconds;
    if (delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
    if (mounted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (motionDisabled(context)) return widget.child;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || motionDisabled(context)) return widget.child;

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        duration: AppMotion.quick,
        curve: AppMotion.standardCurve,
        scale: _pressed ? widget.pressedScale : 1,
        child: widget.child,
      ),
    );
  }
}

class GentleFloat extends StatefulWidget {
  const GentleFloat({
    super.key,
    required this.child,
    this.distance = 5,
    this.duration = const Duration(milliseconds: 1800),
  });

  final Widget child;
  final double distance;
  final Duration duration;

  @override
  State<GentleFloat> createState() => _GentleFloatState();
}

class _GentleFloatState extends State<GentleFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !motionDisabled(context)) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (motionDisabled(context)) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final y = math.sin(_controller.value * math.pi) * -widget.distance;
        return Transform.translate(offset: Offset(0, y), child: child);
      },
      child: widget.child,
    );
  }
}

class CelebrationBurst extends StatefulWidget {
  const CelebrationBurst({
    super.key,
    required this.trigger,
    required this.child,
    this.color = const Color(0xFF9B6EE8),
  });

  final int trigger;
  final Widget child;
  final Color color;

  @override
  State<CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<CelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow);
  }

  @override
  void didUpdateWidget(covariant CelebrationBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && !motionDisabled(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (motionDisabled(context)) return widget.child;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = Curves.easeOutCubic.transform(_controller.value);
              final opacity = (1 - value).clamp(0.0, 1.0);
              return Opacity(
                opacity: opacity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: List.generate(6, (index) {
                    final angle = (math.pi * 2 / 6) * index;
                    final radius = 16 + (34 * value);
                    return Transform.translate(
                      offset: Offset(
                        math.cos(angle) * radius,
                        math.sin(angle) * radius,
                      ),
                      child: Transform.rotate(
                        angle: angle + value,
                        child: Icon(
                          Icons.star_rounded,
                          size: 13 + (5 * (1 - value)),
                          color: widget.color,
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Route<T> playfulRoute<T>({required Widget page}) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, _, _) => page,
    transitionDuration: AppMotion.slow,
    reverseTransitionDuration: AppMotion.normal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (motionDisabled(context)) return child;

      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.standardCurve,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}
