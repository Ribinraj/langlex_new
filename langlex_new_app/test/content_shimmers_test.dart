import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/core/widgets/app_shimmer.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/widgets/content_shimmers.dart';
import 'package:langlex_new_app/features/learning/widgets/paged_learning_list.dart';

void main() {
  final variants = <String, Widget>{
    for (final kind in CatalogSkeleton.values)
      kind.name: CatalogShimmer(
        kind: kind,
        label: 'Loading ${kind.name}',
        itemCount: 3,
        showHeading: true,
      ),
    'lesson': const LessonShimmer(label: 'Loading lesson', showControls: true),
    'profile': const LearningProgressShimmer(label: 'Loading progress'),
    'practice': const PracticeShimmer(label: 'Loading practice'),
  };

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final entry in variants.entries) {
      testWidgets('${entry.key} fits $width with large text', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              ResponsiveUtils().init(context);
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(width == 320 ? 2 : 1),
                  disableAnimations: true,
                ),
                child: child!,
              );
            },
            home: RepaintBoundary(
              key: boundary,
              child: Scaffold(
                backgroundColor: const Color(0xFFFFFAEF),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: entry.value,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        if (Platform.environment['SHIMMER_PREVIEWS'] == '1' && width == 390) {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await render.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final directory = Directory('build/shimmer_previews');
            await directory.create(recursive: true);
            await File(
              '${directory.path}/${entry.key}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }

  testWidgets('shimmer respects motion settings and disposes its ticker', (
    tester,
  ) async {
    Widget view({bool reduceMotion = false, bool enabled = true}) =>
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: TickerMode(
              enabled: enabled,
              child: const AppShimmer(
                label: 'Loading stories',
                child: SkeletonBlock(width: 100, height: 100),
              ),
            ),
          ),
        );
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(view());
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(find.bySemanticsLabel('Loading stories'), findsOneWidget);
    await tester.pumpWidget(view(reduceMotion: true));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(view(enabled: false));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(view());
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'pending results become content or retry without a lingering shimmer',
    (tester) async {
      var request = Completer<CatalogPage<int>>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PagedLearningList<int>(
                loadingIndicator: const CatalogShimmer(
                  kind: CatalogSkeleton.stories,
                  label: 'Loading stories',
                ),
                load: (_) => request.future,
                builder: (_, page) => Text('Story ${page.items.single}'),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(AppShimmer), findsOneWidget);
      request.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(find.byType(AppShimmer), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      request = Completer<CatalogPage<int>>();
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(find.byType(AppShimmer), findsOneWidget);
      request.complete(CatalogPage(items: [1], page: 1, limit: 20, total: 1));
      await tester.pumpAndSettle();
      expect(find.text('Story 1'), findsOneWidget);
      expect(find.byType(AppShimmer), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
