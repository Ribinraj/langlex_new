import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final double? sizeFactor;
  final double? fontSize;
  final double minScale;
  final double maxScale;
  final FontWeight? weight;
  final Color? color;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final int? maxLines;
  final double? height;
  final double? letterSpacing;
  final TextDecoration? decoration;
  final bool? softWrap;
  final TextStyle? style;

  const ResponsiveText(
    this.text, {
    super.key,
    this.sizeFactor,
    this.fontSize,
    this.minScale = 0.9,
    this.maxScale = 1.16,
    this.weight,
    this.color,
    this.overflow,
    this.textAlign,
    this.maxLines,
    this.height,
    this.letterSpacing,
    this.decoration,
    this.softWrap,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final baseSize = ResponsiveUtils.sp(4);
    final resolvedSize =
        fontSize ?? (sizeFactor != null ? baseSize * sizeFactor! : baseSize);

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      softWrap: softWrap,
      style:
          style ??
          GoogleFonts.montserrat(
            fontSize: resolvedSize,
            fontWeight: weight ?? FontWeight.normal,
            color: color ?? Appcolors.kblackcolor,
            height: height,
            letterSpacing: letterSpacing,
            decoration: decoration,
          ),
    );
  }
}

// Optional: Predefined text styles
class TextStyles {
  static ResponsiveText headline({
    String? text,
    FontWeight? weight,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
  }) {
    return ResponsiveText(
      text ?? '',
      sizeFactor: 1.5, // 50% larger than base size
      weight: weight ?? FontWeight.bold,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }

  static ResponsiveText subheadline({
    String? text,
    FontWeight? weight,
    Color? color,
  }) {
    return ResponsiveText(
      text ?? '',
      sizeFactor: 1.22,
      weight: weight ?? FontWeight.w600,
      color: color,
    );
  }

  static ResponsiveText title({
    String? text,
    FontWeight? weight,
    Color? color,
  }) {
    return ResponsiveText(
      text ?? '',
      sizeFactor: 1.07,
      weight: weight ?? FontWeight.bold,
      color: color,
    );
  }

  static ResponsiveText body({String? text, FontWeight? weight, Color? color}) {
    return ResponsiveText(
      text ?? '',
      sizeFactor: .93, // base size
      weight: weight,
      color: color,
    );
  }

  static ResponsiveText medium({
    String? text,
    FontWeight? weight,
    Color? color,
  }) {
    return ResponsiveText(
      text ?? '',
      sizeFactor: .82, // base size
      weight: weight,
      color: color,
    );
  }

  static ResponsiveText caption({
    String? text,
    FontWeight? weight,
    Color? color,
    int? maxline,
  }) {
    return ResponsiveText(
      text ?? '',
      sizeFactor: 0.74, // 25% smaller than base size
      weight: weight,
      maxLines: maxline,
      color: color ?? Appcolors.ktextgreycolor,
    );
  }
}

class ResponsiveTextStyles {
  static TextStyle text({
    double fontSize = 14,
    FontWeight weight = FontWeight.normal,
    Color color = Appcolors.kblackcolor,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  static TextStyle dmSans({
    double fontSize = 14,
    FontWeight weight = FontWeight.normal,
    Color color = Appcolors.kblackcolor,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  static TextStyle playfairDisplay({
    double fontSize = 32,
    FontWeight weight = FontWeight.w900,
    Color color = Appcolors.kblackcolor,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  static TextStyle montserrat({
    double fontSize = 14,
    FontWeight weight = FontWeight.normal,
    Color color = Appcolors.kblackcolor,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }
}
///////
// Basic usage
// ResponsiveText(
//   'Hello, World!',
//   sizeFactor: 1.5, // 50% larger than base size
//   weight: FontWeight.bold,
//   color: Appcolors.kauthAccentBlue,
// )

// // Using predefined styles
// TextStyles.headline(text: 'Main Title')

// TextStyles.subheadline(
//   text: 'Subtitle',
//   color: Appcolors.kgreyColor,
// )

// TextStyles.body(
//   text: 'This is the body text.',
//   weight: FontWeight.w300,
// )

// TextStyles.caption(text: 'Small caption text')

// // Custom sizing
// ResponsiveText(
//   'Custom sized text',
//   sizeFactor: 2.0, // Twice the base size
// )
//////////////////////////
//  Text(
//               'Welcome to our responsive app!',
//               style: TextStyle(
//                 fontSize: ResponsiveUtils.sp(6),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
/////////////------------------borderradius-----------------/////////////////

class ResponsiveBorderRadius {
  final double? sizeFactor;

  const ResponsiveBorderRadius({this.sizeFactor});

  BorderRadius getBorderRadius() {
    // Base size is 1% of screen width
    final baseSize = ResponsiveUtils.borderRadius(1);

    return BorderRadius.circular(
      sizeFactor != null ? baseSize * sizeFactor! : baseSize,
    );
  }
}

// Predefined border radius styles
class BorderRadiusStyles {
  static BorderRadius kradius5() {
    return const ResponsiveBorderRadius(sizeFactor: 1.25).getBorderRadius();
  }

  static BorderRadius kradius10() {
    return const ResponsiveBorderRadius(sizeFactor: 2.5).getBorderRadius();
  }

  static BorderRadius kradius15() {
    return const ResponsiveBorderRadius(sizeFactor: 3.75).getBorderRadius();
  }

  static BorderRadius kradius20() {
    return const ResponsiveBorderRadius(sizeFactor: 5).getBorderRadius();
  }

  static BorderRadius kradius30() {
    return const ResponsiveBorderRadius(sizeFactor: 7.5).getBorderRadius();
  }

  static BorderRadius custom({double? sizeFactor}) {
    return ResponsiveBorderRadius(sizeFactor: sizeFactor).getBorderRadius();
  }
}
/////
// Container(
//   decoration: BoxDecoration(
//     borderRadius: BorderRadiusStyles.kradius10(),
//     color: Appcolors.kauthAccentBlue,
//   ),
//   child: Text('Hello, World!'),
// )

// // Or for a custom size:
// Container(
//   decoration: BoxDecoration(
//     borderRadius: BorderRadiusStyles.custom(sizeFactor: 4.0),
//     color: Appcolors.kgreencolor,
//   ),
//   child: Text('Custom radius'),
// )
//////////////-------sizedbox---------------////////////

class ResponsiveSizedBox {
  // Height constants
  static SizedBox height5 = SizedBox(height: ResponsiveUtils.hp(0.5));
  static SizedBox height10 = SizedBox(height: ResponsiveUtils.hp(1));
  static SizedBox height15 = SizedBox(height: ResponsiveUtils.hp(1.5));
  static SizedBox height20 = SizedBox(height: ResponsiveUtils.hp(2));
  static SizedBox height30 = SizedBox(height: ResponsiveUtils.hp(3));
  static SizedBox height40 = SizedBox(height: ResponsiveUtils.hp(4));
  static SizedBox height50 = SizedBox(height: ResponsiveUtils.hp(5));

  // Width constants
  static SizedBox width5 = SizedBox(width: ResponsiveUtils.wp(1.25));
  static SizedBox width10 = SizedBox(width: ResponsiveUtils.wp(2.5));
  static SizedBox width20 = SizedBox(width: ResponsiveUtils.wp(5));
  static SizedBox width30 = SizedBox(width: ResponsiveUtils.wp(7.5));
  static SizedBox width50 = SizedBox(width: ResponsiveUtils.wp(12.5));

  static double scaledHeight(double value) {
    return value;
  }

  static double scaledWidth(double value) {
    return value;
  }

  // Custom methods for dynamic sizes
  static SizedBox height(double percentage) {
    return SizedBox(height: ResponsiveUtils.hp(percentage));
  }

  static SizedBox width(double percentage) {
    return SizedBox(width: ResponsiveUtils.wp(percentage));
  }

  static SizedBox heightPx(double value) {
    return SizedBox(height: scaledHeight(value));
  }

  static SizedBox widthPx(double value) {
    return SizedBox(width: scaledWidth(value));
  }

  static SizedBox gapHeight(bool condition, double first, double second) {
    return heightPx(condition ? first : second);
  }

  static SizedBox gapWidth(bool condition, double first, double second) {
    return widthPx(condition ? first : second);
  }

  static SizedBox square(double value) {
    final size = scaledWidth(value);
    return SizedBox(width: size, height: size);
  }

  static SizedBox box({double? width, double? height, Widget? child}) {
    return SizedBox(width: width, height: height, child: child);
  }

  static SizedBox expand({Widget? child}) {
    return SizedBox.expand(child: child);
  }
}

//////////---------------//////////////
