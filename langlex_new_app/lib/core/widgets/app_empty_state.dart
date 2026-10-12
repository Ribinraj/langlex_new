import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/colors.dart';

enum EmptyStateKind {
  search,
  lessons,
  stories,
  alphabets,
  sounds,
  quizzes,
  notifications,
  plans,
}

/// A calm, illustrated pause with an optional way back to useful content.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.kind = EmptyStateKind.search,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.arrow_back_rounded,
    this.compact = false,
  }) : assert((actionLabel == null) == (onAction == null));

  final String title;
  final String message;
  final EmptyStateKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (icon, accent, surface) = switch (kind) {
      EmptyStateKind.search => (
        Icons.search_rounded,
        Appcolors.kprimarycolor,
        Appcolors.ksoftPrimarySurface,
      ),
      EmptyStateKind.lessons => (
        Icons.auto_stories_rounded,
        Appcolors.klearningPlayfulBlue,
        Appcolors.kauthSoftBlue,
      ),
      EmptyStateKind.stories => (
        Icons.menu_book_rounded,
        Appcolors.klearningPlayfulCoral,
        Appcolors.kmetricLowStockSurface,
      ),
      EmptyStateKind.alphabets => (
        Icons.abc_rounded,
        Appcolors.kdashboardTeal,
        Appcolors.kauthSoftGreen,
      ),
      EmptyStateKind.sounds => (
        Icons.music_note_rounded,
        Appcolors.kdashboardTeal,
        Appcolors.kauthSoftGreen,
      ),
      EmptyStateKind.quizzes => (
        Icons.extension_rounded,
        Appcolors.kprimarycolor,
        Appcolors.ksoftPrimarySurface,
      ),
      EmptyStateKind.notifications => (
        Icons.notifications_none_rounded,
        Appcolors.kheroStartButtonText,
        Appcolors.kgoalChipGoldSurface,
      ),
      EmptyStateKind.plans => (
        Icons.workspace_premium_rounded,
        Appcolors.kprimarycolor,
        Appcolors.ksoftPrimarySurface,
      ),
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: compact ? 16 : 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: compact ? 152 : 206,
                  height: compact ? 124 : 168,
                  child: FittedBox(
                    child: _EmptyIllustration(
                      icon: icon,
                      accent: accent,
                      surface: surface,
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 16 : 22),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: compact ? 18 : 21,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: Appcolors.ktextdark,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  color: Appcolors.kdashboardMutedText,
                ),
              ),
              if (onAction != null) ...[
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: Appcolors.klibraryTitle,
                    foregroundColor: Appcolors.kwhitecolor,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(actionIcon, size: 20),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          actionLabel!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration({
    required this.icon,
    required this.accent,
    required this.surface,
  });
  final IconData icon;
  final Color accent;
  final Color surface;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 206,
    height: 168,
    child: CustomPaint(
      painter: _EmptyBackdrop(accent: accent, surface: surface),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 49,
            top: 22,
            child: Transform.rotate(
              angle: -.13,
              child: Container(
                width: 104,
                height: 116,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: accent.withValues(alpha: .14)),
                ),
              ),
            ),
          ),
          Positioned(
            left: 60,
            top: 16,
            child: Transform.rotate(
              angle: .09,
              child: Container(
                width: 104,
                height: 120,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Appcolors.kwhitecolor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: accent.withValues(alpha: .18)),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: .09),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 17,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 15),
                    for (final width in [62.0, 45.0, 53.0])
                      Container(
                        width: width,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 7),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 112,
            top: 90,
            child: Transform.rotate(
              angle: -.12,
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Appcolors.kwhitecolor, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: .16),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, size: 33, color: Appcolors.kwhitecolor),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyBackdrop extends CustomPainter {
  const _EmptyBackdrop({required this.accent, required this.surface});
  final Color accent;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = surface.withValues(alpha: .8);
    canvas.drawOval(const Rect.fromLTWH(20, 19, 167, 137), paint);
    paint
      ..color = accent.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      const Rect.fromLTWH(9, 8, 186, 149),
      math.pi * .73,
      .5,
      false,
      paint,
    );
    canvas.drawArc(const Rect.fromLTWH(9, 8, 186, 149), -.6, .35, false, paint);
    paint.style = PaintingStyle.fill;
    for (final (point, radius, color) in [
      (const Offset(27, 47), 5.0, Appcolors.klearningPlayfulYellow),
      (const Offset(184, 113), 4.0, Appcolors.klearningPlayfulCoral),
      (const Offset(44, 137), 3.0, Appcolors.klearningPlayfulTeal),
    ]) {
      paint.color = color;
      canvas.drawCircle(point, radius, paint);
    }
    paint
      ..color = Appcolors.klearningPlayfulYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final center in [const Offset(174, 26), const Offset(24, 99)]) {
      canvas.drawLine(
        center - const Offset(5, 0),
        center + const Offset(5, 0),
        paint,
      );
      canvas.drawLine(
        center - const Offset(0, 5),
        center + const Offset(0, 5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EmptyBackdrop oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.surface != surface;
}
