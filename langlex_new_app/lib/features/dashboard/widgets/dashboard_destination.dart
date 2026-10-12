import 'package:flutter/material.dart';
import 'package:langlex_new_app/core/colors.dart';

/// Turns former dashboard tabs into ordinary pages with a predictable Back path.
class DashboardDestination extends StatelessWidget {
  const DashboardDestination({
    super.key,
    required this.title,
    required this.child,
    this.backgroundGradient,
  });
  final String title;
  final Widget child;
  final Gradient? backgroundGradient;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Appcolors.kscreenWarmBackground,
    body: backgroundGradient == null
        ? child
        : SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: backgroundGradient),
              child: child,
            ),
          ),
  );
}
