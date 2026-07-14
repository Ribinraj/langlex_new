import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:langlex_new_app/core/colors.dart';

/// A reusable animated background with softly drifting bubble blobs, echoing
/// the LangLex logo's speech-bubble motif. Drop it behind any page's content:
///
/// ```dart
/// Scaffold(
///   body: KidsBubbleBackground(
///     child: SafeArea(child: ...),
///   ),
/// )
/// ```
class KidsBubbleBackground extends StatefulWidget {
  const KidsBubbleBackground({super.key, required this.child, this.baseColor});

  final Widget child;
  final Color? baseColor;

  @override
  State<KidsBubbleBackground> createState() => _KidsBubbleBackgroundState();
}

class _KidsBubbleBackgroundState extends State<KidsBubbleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.baseColor ?? const Color(0xFFF6EFFD),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _BubblePainter(progress: _controller.value),
                  size: Size.infinite,
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.progress});

  final double progress;

  double _wave(double phase, double speed) =>
      math.sin((progress * 2 * math.pi * speed) + phase);

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = <_BlobSpec>[
      _BlobSpec(
        center: Offset(size.width * 0.10, size.height * 0.06),
        radius: size.width * 0.42,
        color: Appcolors.ksecondarycolor.withValues(alpha: 0.22),
        phase: 0,
        speed: 0.5,
        driftX: 14,
        driftY: 10,
      ),
      _BlobSpec(
        center: Offset(size.width * 0.98, size.height * 0.16),
        radius: size.width * 0.34,
        color: Appcolors.kprimarycolor.withValues(alpha: 0.21),
        phase: 1.7,
        speed: 0.4,
        driftX: 10,
        driftY: 16,
      ),
      _BlobSpec(
        center: Offset(size.width * 0.02, size.height * 0.78),
        radius: size.width * 0.38,
        color: Appcolors.kmetricInventory.withValues(alpha: 0.19),
        phase: 3.1,
        speed: 0.45,
        driftX: 12,
        driftY: 12,
      ),
      _BlobSpec(
        center: Offset(size.width * 0.92, size.height * 0.94),
        radius: size.width * 0.30,
        color: Appcolors.ksecondarycolor.withValues(alpha: 0.17),
        phase: 4.4,
        speed: 0.5,
        driftX: 8,
        driftY: 14,
      ),
    ];

    for (final b in blobs) {
      final dx = _wave(b.phase, b.speed) * b.driftX;
      final dy = _wave(b.phase + 1.2, b.speed) * b.driftY;
      final paint = Paint()..color = b.color;
      canvas.drawCircle(b.center.translate(dx, dy), b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BlobSpec {
  const _BlobSpec({
    required this.center,
    required this.radius,
    required this.color,
    required this.phase,
    required this.speed,
    required this.driftX,
    required this.driftY,
  });

  final Offset center;
  final double radius;
  final Color color;
  final double phase;
  final double speed;
  final double driftX;
  final double driftY;
}
