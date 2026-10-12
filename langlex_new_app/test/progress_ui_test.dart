import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/widgets/alphabet_catalog_widgets.dart';
import 'package:langlex_new_app/features/progress/progress_models.dart';
import 'package:langlex_new_app/features/progress/progress_page.dart';
import 'package:langlex_new_app/features/progress/progress_widgets.dart';

Map<String, dynamic> snapshot({bool premium = false, bool empty = false}) => {
  'selected_languages': ['English', 'Hindi'],
  'language': 'English',
  'level': 'Nursery',
  'has_premium': premium,
  'total_items': empty
      ? 0
      : premium
      ? 60
      : 40,
  'completed_items': empty ? 0 : 20,
  'total_topics': empty
      ? 0
      : premium
      ? 6
      : 4,
  'completed_topics': empty ? 0 : 1,
  'locked_topics': premium ? 0 : 2,
  'saved_locked_items': 3,
  'topics': empty
      ? []
      : [
          for (final type in ['course', 'alphabet', 'phonics', 'quiz', 'story'])
            {
              'content_type': type,
              'content_key': '$type-1',
              'title': switch (type) {
                'course' => 'Pet animals',
                'alphabet' => 'A · Letters and sounds',
                'phonics' => 'Everyday words',
                'quiz' => 'Animal sounds quiz',
                _ => 'The clever little fox',
              },
              'language': 'English',
              'total_items': 10,
              'completed_items': type == 'course' ? 10 : 3,
              'correct_items': 2,
              'status': type == 'course' ? 'completed' : 'in_progress',
              'accessible': type != 'story' || premium,
              'premium': type == 'story',
            },
        ],
};
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_PROGRESS')) return;
    await tester.pumpAndSettle();
    final render =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await render.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/progress_previews/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('progress summary and topic filters fit $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (r, h) => h.resolve(
              Response(
                requestOptions: r,
                statusCode: 200,
                data: {'progress': snapshot()},
              ),
            ),
          ),
        );
      final repo = LearningRepository(dio);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepositoryProvider.value(
          value: repo,
          child: MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              textTheme: GoogleFonts.montserratTextTheme(),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(width == 320 ? 1.8 : 1)),
              child: child!,
            ),
            home: RepaintBoundary(
              key: key,
              child: const ProgressPage(language: 'English'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('50%'), findsOneWidget);
      await capture(tester, key, 'overview-${width.toInt()}');
      final course = find.widgetWithText(ChoiceChip, 'Knowledge');
      for (var i = 0; i < 12; i++) {
        final y = tester.getCenter(course).dy;
        if (y > 200 && y < 800) break;
        await tester.drag(
          find.byType(CustomScrollView),
          Offset(0, y > 800 ? -350 : 350),
        );
        await tester.pumpAndSettle();
      }
      expect(course.hitTestable(), findsOneWidget);
      await tester.tap(course);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Pet animals'), 200);
      expect(find.text('Animal sounds quiz'), findsNothing);
      expect(tester.takeException(), isNull);
      await capture(tester, key, 'topics-${width.toInt()}');
      await tester.pumpWidget(const SizedBox.shrink());
      repo.progress.dispose();
    });
  }
  testWidgets('premium changes denominator and an empty catalogue has no NaN', (
    tester,
  ) async {
    Future<void> show(Map<String, dynamic> raw) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProgressSummary(
              data: LearningProgressOverview.fromJson(raw),
              t: const AppLocalizations('English'),
            ),
          ),
        ),
      ),
    );
    await show(snapshot(premium: true));
    expect(find.text('33%'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    await show(snapshot(empty: true));
    expect(find.text('0%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'failed request shows retry and successful retry displays actual data',
    (tester) async {
      var fail = true;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (r, h) {
              if (fail) {
                h.reject(DioException(requestOptions: r));
              } else {
                h.resolve(
                  Response(
                    requestOptions: r,
                    statusCode: 200,
                    data: {'progress': snapshot()},
                  ),
                );
              }
            },
          ),
        );
      final repo = LearningRepository(dio);
      await tester.pumpWidget(
        RepositoryProvider.value(
          value: repo,
          child: const MaterialApp(home: ProgressPage(language: 'English')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProgressUnavailable), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('50%'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      repo.progress.dispose();
    },
  );
  testWidgets('language selector requests a separate scope', (tester) async {
    final languages = <String>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) {
            final language = '${r.queryParameters['language']}';
            languages.add(language);
            h.resolve(
              Response(
                requestOptions: r,
                statusCode: 200,
                data: {
                  'progress': {...snapshot(), 'language': language},
                },
              ),
            );
          },
        ),
      );
    final repo = LearningRepository(dio);
    await tester.pumpWidget(
      RepositoryProvider.value(
        value: repo,
        child: const MaterialApp(home: ProgressPage(language: 'English')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hindi').last);
    await tester.pumpAndSettle();
    expect(languages, ['English', 'Hindi']);
    expect(repo.progress.overview!.language, 'Hindi');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    repo.progress.dispose();
  });
  testWidgets(
    'marking alphabet search practice submits only visible example IDs',
    (tester) async {
      final ids = <String>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (r, h) {
              if (r.method == 'POST') ids.add('${r.data['item_key']}');
              h.resolve(
                Response(
                  requestOptions: r,
                  statusCode: 200,
                  data: {'progress': snapshot()},
                ),
              );
            },
          ),
        );
      final repo = LearningRepository(dio);
      await tester.pumpWidget(
        RepositoryProvider.value(
          value: repo,
          child: MaterialApp(
            home: Scaffold(
              body: AlphabetGroups(
                rows: const [
                  {
                    'id': 2,
                    'progress_key': 'alphabet-1',
                    'letter': 'A',
                    'language': 'English',
                    'coursename': 'Letters',
                    'examples': [
                      {'id': 2, 'ill_word': 'Ant'},
                    ],
                  },
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(ids, isEmpty);
      await tester.tap(find.widgetWithText(FilledButton, 'Mark as practiced'));
      await tester.pumpAndSettle();
      expect(ids, ['alphabet-2']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      repo.progress.dispose();
    },
  );
}
