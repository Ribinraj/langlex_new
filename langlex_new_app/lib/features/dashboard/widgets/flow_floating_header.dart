// Copyright 2014 The Flutter Authors. All rights reserved.
// Derived from Flutter's widgets/sliver_floating_header.dart.
// BSD-3-Clause license: see third_party/flutter/LICENSE.
//
// The SDK header disposes its snap controller on render-object detach, then
// creates another on reattach. Its SingleTickerProviderStateMixin rejects that
// second ticker. Keep the same sizing and snapping behavior, with a ticker
// provider that supports this lifecycle. No global Flutter SDK patch is needed.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A naturally sized floating header that can safely leave and rejoin a tree.
class FlowFloatingHeader extends StatefulWidget {
  /// Create a floating header sliver that animates into view when the user
  /// scrolls forward, and disappears the user starts scrolling in the
  /// opposite direction.
  const FlowFloatingHeader({
    super.key,
    this.animationStyle,
    this.snapMode,
    required this.child,
  });

  /// Non null properties override the default durations (300ms) and
  /// curves (Curves.easeInOut) for subsequent header animations.
  ///
  /// The reverse duration and curve apply to the animation that hides the header.
  final AnimationStyle? animationStyle;

  /// Specifies how a partially visible [FlowFloatingHeader] animates
  /// into a view when a user scroll gesture ends.
  ///
  /// The default is [FloatingHeaderSnapMode.overlay]. This parameter doesn't
  /// modify an animation in progress, just subsequent animations.
  final FloatingHeaderSnapMode? snapMode;

  /// The widget contained by this sliver.
  final Widget child;

  @override
  State<FlowFloatingHeader> createState() => _FlowFloatingHeaderState();
}

class _FlowFloatingHeaderState extends State<FlowFloatingHeader>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return _FlowFloatingHeader(
      vsync: this,
      animationStyle: widget.animationStyle,
      snapMode: widget.snapMode,
      child: _SnapTrigger(widget.child),
    );
  }
}

class _SnapTrigger extends StatefulWidget {
  const _SnapTrigger(this.child);

  final Widget child;

  @override
  _SnapTriggerState createState() => _SnapTriggerState();
}

class _SnapTriggerState extends State<_SnapTrigger> {
  ScrollPosition? position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (position != null) {
      position!.isScrollingNotifier.removeListener(isScrollingListener);
    }
    position = Scrollable.maybeOf(context)?.position;
    if (position != null) {
      position!.isScrollingNotifier.addListener(isScrollingListener);
    }
  }

  @override
  void dispose() {
    if (position != null) {
      position!.isScrollingNotifier.removeListener(isScrollingListener);
    }
    super.dispose();
  }

  // Called when the sliver starts or ends scrolling.
  void isScrollingListener() {
    assert(position != null);
    final _RenderFlowFloatingHeader? renderer = context
        .findAncestorRenderObjectOfType<_RenderFlowFloatingHeader>();
    renderer?.isScrollingUpdate(position!);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _FlowFloatingHeader extends SingleChildRenderObjectWidget {
  const _FlowFloatingHeader({
    this.vsync,
    this.animationStyle,
    this.snapMode,
    super.child,
  });

  final TickerProvider? vsync;
  final AnimationStyle? animationStyle;
  final FloatingHeaderSnapMode? snapMode;

  @override
  _RenderFlowFloatingHeader createRenderObject(BuildContext context) {
    return _RenderFlowFloatingHeader(
      vsync,
      animationStyle: animationStyle,
      snapMode: snapMode,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFlowFloatingHeader renderObject,
  ) {
    renderObject
      ..vsync = vsync
      ..animationStyle = animationStyle
      ..snapMode = snapMode;
  }
}

class _RenderFlowFloatingHeader extends RenderSliverSingleBoxAdapter {
  _RenderFlowFloatingHeader(this._vsync, {this.animationStyle, this.snapMode});

  late Animation<double> snapAnimation;
  AnimationController? snapController;
  double? lastScrollOffset;

  // The distance from the start of the header to the start of the viewport. When the
  // header is showing it varies between 0 (completely visible) and childExtent (not visible
  // because it's just above the viewport's starting edge). It's used to compute the
  // header's paintExtent which defines where the header will appear - see paint().
  late double effectiveScrollOffset;

  TickerProvider? get vsync => _vsync;
  TickerProvider? _vsync;
  set vsync(TickerProvider? value) {
    if (value == _vsync) {
      return;
    }
    _vsync = value;
    if (value == null) {
      snapController?.dispose();
      snapController = null;
    } else {
      snapController?.resync(value);
    }
  }

  AnimationStyle? animationStyle;

  FloatingHeaderSnapMode? snapMode;

  // Called each time the position's isScrollingNotifier indicates that user scrolling has
  // stopped or started, i.e. if the sliver "is scrolling".
  void isScrollingUpdate(ScrollPosition position) {
    if (position.isScrollingNotifier.value) {
      snapController?.stop();
    } else {
      final ScrollDirection direction = position.userScrollDirection;
      final bool headerIsPartiallyVisible = switch (direction) {
        ScrollDirection.forward when effectiveScrollOffset <= 0 =>
          false, // completely visible
        ScrollDirection.reverse when effectiveScrollOffset >= childExtent =>
          false, // not visible
        _ => true,
      };
      if (headerIsPartiallyVisible) {
        snapController ??= AnimationController(vsync: vsync!)
          ..addListener(() {
            if (effectiveScrollOffset != snapAnimation.value) {
              effectiveScrollOffset = snapAnimation.value;
              markNeedsLayout();
            }
          });
        snapController!.duration = switch (direction) {
          ScrollDirection.forward =>
            animationStyle?.duration ?? const Duration(milliseconds: 300),
          _ =>
            animationStyle?.reverseDuration ??
                const Duration(milliseconds: 300),
        };
        snapAnimation = snapController!.drive(
          Tween<double>(
            begin: effectiveScrollOffset,
            end: switch (direction) {
              ScrollDirection.forward => 0,
              _ => childExtent,
            },
          ).chain(
            CurveTween(
              curve: switch (direction) {
                ScrollDirection.forward =>
                  animationStyle?.curve ?? Curves.easeInOut,
                _ => animationStyle?.reverseCurve ?? Curves.easeInOut,
              },
            ),
          ),
        );
        snapController!.forward(from: 0.0);
      }
    }
  }

  double get childExtent {
    if (child == null) {
      return 0.0;
    }
    assert(child!.hasSize);
    return switch (constraints.axis) {
      Axis.vertical => child!.size.height,
      Axis.horizontal => child!.size.width,
    };
  }

  @override
  void detach() {
    snapController?.dispose();
    snapController = null; // lazily recreated if we're reattached.
    super.detach();
  }

  // True if the header has been laid at at least once (lastScrollOffset != null) and either:
  // - We're scrolling forward: constraints.scrollOffset < lastScrollOffset
  // - The header's already partially visible: effectiveScrollOffset < childExtent
  // Scrolling forwards (towards the scrollable's start) is the trigger that causes the
  // header to be shown.
  bool get floatingHeaderNeedsToBeUpdated {
    return lastScrollOffset != null &&
        (constraints.scrollOffset < lastScrollOffset! ||
            effectiveScrollOffset < childExtent);
  }

  @override
  void performLayout() {
    if (!floatingHeaderNeedsToBeUpdated) {
      effectiveScrollOffset = constraints.scrollOffset;
    } else {
      double delta =
          lastScrollOffset! -
          constraints.scrollOffset; // > 0 when the header is growing
      if (constraints.userScrollDirection == ScrollDirection.forward) {
        if (effectiveScrollOffset > childExtent) {
          effectiveScrollOffset =
              childExtent; // The header is now just above the start edge of viewport.
        }
      } else {
        // delta > 0 and scrolling forward is a contradiction. Assume that it's noise (set delta to 0).
        delta = clampDouble(delta, -double.infinity, 0);
      }
      effectiveScrollOffset = clampDouble(
        effectiveScrollOffset - delta,
        0.0,
        constraints.scrollOffset,
      );
    }

    child?.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    final double paintExtent = childExtent - effectiveScrollOffset;
    final double layoutExtent = switch (snapMode ??
        FloatingHeaderSnapMode.overlay) {
      FloatingHeaderSnapMode.overlay => childExtent - constraints.scrollOffset,
      FloatingHeaderSnapMode.scroll => paintExtent,
    };
    geometry = SliverGeometry(
      paintOrigin: math.min(constraints.overlap, 0.0),
      scrollExtent: childExtent,
      paintExtent: clampDouble(
        paintExtent,
        0.0,
        constraints.remainingPaintExtent,
      ),
      layoutExtent: clampDouble(
        layoutExtent,
        0.0,
        constraints.remainingPaintExtent,
      ),
      maxPaintExtent: childExtent,
      hasVisualOverflow:
          true, // Conservatively say we do have overflow to avoid complexity.
    );

    lastScrollOffset = constraints.scrollOffset;
  }

  @override
  double childMainAxisPosition(covariant RenderObject child) {
    return geometry == null
        ? 0
        : math.min(0, geometry!.paintExtent - childExtent);
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child == this.child);
    applyPaintTransformForBoxChild(child as RenderBox, transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && geometry!.visible) {
      offset += switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection,
        constraints.growthDirection,
      )) {
        AxisDirection.up => Offset(
          0.0,
          geometry!.paintExtent - childMainAxisPosition(child!) - childExtent,
        ),
        AxisDirection.left => Offset(
          geometry!.paintExtent - childMainAxisPosition(child!) - childExtent,
          0.0,
        ),
        AxisDirection.right => Offset(childMainAxisPosition(child!), 0.0),
        AxisDirection.down => Offset(0.0, childMainAxisPosition(child!)),
      };
      context.paintChild(child!, offset);
    }
  }
}
