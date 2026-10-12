import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/app_toast.dart';
import 'package:langlex_new_app/core/colors.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    if (const bool.fromEnvironment('CAPTURE_TOAST')) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  late BuildContext pageContext;
  var taps = 0;
  Widget view({
    bool accessible = false,
    bool reducedMotion = false,
    double scale = 1,
  }) => MaterialApp(
    theme: ThemeData(
      textTheme: GoogleFonts.montserratTextTheme(),
      scaffoldBackgroundColor: Appcolors.kscreenWarmBackground,
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: const EdgeInsets.only(top: 44),
        viewPadding: const EdgeInsets.only(top: 44),
        viewInsets: const EdgeInsets.only(bottom: 240),
        accessibleNavigation: accessible,
        disableAnimations: reducedMotion,
        textScaler: TextScaler.linear(scale),
      ),
      child: RepaintBoundary(key: const ValueKey('capture'), child: child!),
    ),
    home: Builder(
      builder: (context) {
        pageContext = context;
        return Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => taps++,
              child: const Text('Underlying action'),
            ),
          ),
        );
      },
    ),
  );

  testWidgets(
    'toast stays at the safe top, has round ends, and dismisses automatically',
    (tester) async {
      await tester.pumpWidget(view());
      AppToast.success(pageContext, 'Profile updated');
      await tester.pumpAndSettle();
      final toast = find.byKey(const ValueKey('app-toast'));
      expect(tester.getTopLeft(toast).dy, 56);
      expect(tester.widget<Material>(toast).shape, isA<StadiumBorder>());
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
      taps = 0;
      await tester.tap(find.text('Underlying action'));
      expect(taps, 1);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(toast, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('new messages replace the current toast and cancel its expiry', (
    tester,
  ) async {
    await tester.pumpWidget(view());
    AppToast.show(pageContext, 'First', duration: const Duration(seconds: 1));
    await tester.pumpAndSettle();
    AppToast.error(pageContext, 'Second');
    AppToast.success(pageContext, 'Latest');
    await tester.pumpAndSettle();
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsNothing);
    expect(find.text('Latest'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Latest'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-toast')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'success survives popping its page and unmount cleans up the timer',
    (tester) async {
      await tester.pumpWidget(view());
      Navigator.of(pageContext).push(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  AppToast.success(context, 'Saved');
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Underlying action'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'accessible feedback waits for dismissal and respects reduced motion',
    (tester) async {
      await tester.pumpWidget(view(accessible: true, reducedMotion: true));
      AppToast.error(pageContext, 'Please try again');
      await tester.pump();
      await tester.pump();
      expect(tester.getTopLeft(find.byKey(const ValueKey('app-toast'))).dy, 56);
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Please try again'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Please try again'), findsNothing);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets('toast fits $size including long messages and large type', (
      tester,
    ) async {
      final previousShadowSetting = debugDisableShadows;
      try {
        if (const bool.fromEnvironment('CAPTURE_TOAST')) {
          debugDisableShadows = false;
        }
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(view(scale: size.width == 320 ? 1.8 : 1));
        AppToast.success(
          pageContext,
          size.width == 320
              ? 'Your profile has been updated successfully. You can continue learning with your saved details.'
              : 'Your profile has been updated successfully.',
        );
        await tester.runAsync(() => GoogleFonts.pendingFonts());
        await tester.pumpAndSettle();
        final rect = tester.getRect(find.byKey(const ValueKey('app-toast')));
        expect(rect.left, greaterThanOrEqualTo(16));
        expect(rect.right, lessThanOrEqualTo(size.width - 16));
        expect(rect.width, lessThanOrEqualTo(560));
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('CAPTURE_TOAST')) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('capture')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              '/tmp/langlex-toasts/toast-${size.width.toInt()}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      } finally {
        debugDisableShadows = previousShadowSetting;
      }
    });
  }
}
