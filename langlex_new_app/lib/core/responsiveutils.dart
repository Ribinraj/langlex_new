// lib/utils/responsive_utils.dart

import 'package:flutter/material.dart';

enum ScreenSizeClass { mobile, tablet, desktop }

class ResponsiveUtils {
  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 1024;
  static const double pageMaxWidth = 1440;
  static const double formMaxWidth = 960;

  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;

  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    _safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;
  }

  static double hp(double percentage) {
    return blockSizeVertical * percentage;
  }

  static double wp(double percentage) {
    return blockSizeHorizontal * percentage;
  }

  static double sp(double percentage) {
    return blockSizeHorizontal * percentage;
  }

  static double borderRadius(double percentage) {
    return blockSizeHorizontal * percentage;
  }

  // New method for icon sizing
  static double iconSize(double percentage) {
    return blockSizeHorizontal * percentage;
  }

  static ScreenSizeClass sizeClass(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return ScreenSizeClass.mobile;
    if (width <= desktopBreakpoint) return ScreenSizeClass.tablet;
    return ScreenSizeClass.desktop;
  }

  static bool isMobile(BuildContext context) {
    return sizeClass(context) == ScreenSizeClass.mobile;
  }

  static bool isTablet(BuildContext context) {
    return sizeClass(context) == ScreenSizeClass.tablet;
  }

  static bool isDesktop(BuildContext context) {
    return sizeClass(context) == ScreenSizeClass.desktop;
  }

  static EdgeInsets pagePadding(
    BuildContext context, {
    double mobileHorizontalPercent = 4,
    double tabletHorizontal = 32,
    double desktopHorizontal = 36,
    double top = 0,
    double bottom = 0,
  }) {
    final horizontal = switch (sizeClass(context)) {
      ScreenSizeClass.mobile => wp(mobileHorizontalPercent),
      ScreenSizeClass.tablet => tabletHorizontal,
      ScreenSizeClass.desktop => desktopHorizontal,
    };

    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }

  static double bottomScrollPadding(
    BuildContext context, {
    double mobilePercent = 3,
    double tablet = 32,
    double desktop = 36,
  }) {
    return switch (sizeClass(context)) {
      ScreenSizeClass.mobile => hp(mobilePercent),
      ScreenSizeClass.tablet => tablet,
      ScreenSizeClass.desktop => desktop,
    };
  }

  static double maxContentWidth(
    BuildContext context, {
    double mobile = double.infinity,
    double tablet = formMaxWidth,
    double desktop = pageMaxWidth,
  }) {
    return switch (sizeClass(context)) {
      ScreenSizeClass.mobile => mobile,
      ScreenSizeClass.tablet => tablet,
      ScreenSizeClass.desktop => desktop,
    };
  }

  static Widget constrainWidth({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
    AlignmentGeometry alignment = Alignment.topCenter,
  }) {
    final resolvedMaxWidth = maxWidth ?? maxContentWidth(context);
    if (resolvedMaxWidth == double.infinity) return child;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
        child: child,
      ),
    );
  }
}

///////////////
class AppSizes {
  static double get smallIcon => ResponsiveUtils.iconSize(4);
  static double get mediumIcon => ResponsiveUtils.iconSize(6);
  static double get largeIcon => ResponsiveUtils.iconSize(8);
}
