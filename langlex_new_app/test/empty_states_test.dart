import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/widgets/app_empty_state.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/widgets/paged_learning_list.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final kind in EmptyStateKind.values) {
      testWidgets('$kind fits $width with accessible action', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundary = GlobalKey();
        var acted = false;
        const t = AppLocalizations('English');
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(textTheme: GoogleFonts.montserratTextTheme()),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 900),
                textScaler: TextScaler.linear(width == 320 ? 2 : 1),
              ),
              child: RepaintBoundary(
                key: boundary,
                child: Scaffold(
                  backgroundColor: const Color(0xFFFFFAEF),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: AppEmptyState(
                      kind: kind,
                      title: kind == EmptyStateKind.search
                          ? t.noResultsTitle
                          : kind == EmptyStateKind.notifications
                          ? t.allCaughtUp
                          : t.nothingHereYet,
                      message: kind == EmptyStateKind.search
                          ? t.emptySearchHint
                          : kind == EmptyStateKind.notifications
                          ? t.emptyNotificationsHint
                          : switch (kind) {
                              EmptyStateKind.lessons => t.emptyLesson,
                              EmptyStateKind.alphabets => t.noAlphabetRows,
                              EmptyStateKind.sounds => t.noPhonics,
                              EmptyStateKind.quizzes => t.noQuizQuestions,
                              EmptyStateKind.plans => t.noPaidPlans,
                              _ => t.noStoriesAvailable,
                            },
                      actionLabel: kind == EmptyStateKind.search
                          ? t.clearSearch
                          : t.goBack,
                      actionIcon: kind == EmptyStateKind.search
                          ? Icons.restart_alt_rounded
                          : Icons.arrow_back_rounded,
                      onAction: () => acted = true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final button = find.byType(FilledButton);
        await tester.ensureVisible(button);
        expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
        await tester.tap(button);
        expect(acted, isTrue);
        if (const bool.fromEnvironment('CAPTURE_EMPTY') && width == 390) {
          await tester.pumpAndSettle();
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await render.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File('build/empty_state_previews/${kind.name}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }

  for (final separatePages in [false, true]) {
    testWidgets(
      'empty first page shows one state, separatePages=$separatePages',
      (tester) async {
        var builds = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PagedLearningList<int>(
                  separatePages: separatePages,
                  load: (_) async =>
                      CatalogPage(items: [], page: 1, limit: 20, total: 0),
                  builder: (_, _) {
                    builds++;
                    return const Text('Content');
                  },
                  emptyState: const AppEmptyState(
                    title: 'No matches this time',
                    message: 'Try another word.',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(builds, 0);
        expect(find.byType(AppEmptyState), findsOneWidget);
        expect(find.text('No results'), findsNothing);
        expect(find.text('End of results'), findsNothing);
      },
    );

    testWidgets(
      'empty tail preserves earlier results, separatePages=$separatePages',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PagedLearningList<int>(
                  separatePages: separatePages,
                  load: (page) async => CatalogPage(
                    items: page == 1 ? [1] : [],
                    page: page,
                    limit: 1,
                    total: 2,
                  ),
                  builder: (_, page) => Text('Items: ${page.items.join(',')}'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Items: 1'), findsOneWidget);
        expect(find.byType(AppEmptyState), findsNothing);
        expect(find.text('End of results'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
