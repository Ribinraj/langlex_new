import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/widgets/learning_widgets.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/pages/phonics_practice_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  final rows =
      (jsonDecode(
                File('test/fixtures/phonics_long_text.json').readAsStringSync(),
              )
              as List)
          .map((row) => PhonicsItem.fromJson(Map<String, dynamic>.from(row)))
          .toList();

  Widget view(LearningRepository repo, {double scale = 1, int? initialIndex}) =>
      RepositoryProvider.value(
        value: repo,
        child: MaterialApp(
          builder: (context, child) {
            ResponsiveUtils().init(context);
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            );
          },
          home: PhonicsPracticePage(
            phonics: List.generate(20, (i) => rows[i % rows.length]),
            homeLanguage: 'Hindi',
            initialIndex: initialIndex,
          ),
        ),
      );

  testWidgets(
    'course summaries show the full word count before words are fetched',
    (tester) async {
      final course = LearningCourse.fromCourseJson(
        {
          'id': 1,
          'title': 'Pet Animals',
          'language': 'English',
          'word_count': 25,
        },
        [],
        alphabets: [],
        phonics: [],
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            ResponsiveUtils().init(context);
            return child!;
          },
          home: Scaffold(body: LearningCourseCard(course: course)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('25 words'), findsOneWidget);
      expect(find.text('Content pending'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'original phonics text fits $size with large type and 20 cards',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) => handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'progress': {'position': 0},
                },
              ),
            ),
          ),
        );
        await tester.pumpWidget(view(LearningRepository(dio), scale: 1.8));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // Navigation remains visible even when the long card must be scrolled.
        expect(
          find.byIcon(Icons.arrow_forward_rounded).hitTestable(),
          findsOneWidget,
        );
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -600),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Maithili'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'resume never writes card zero before the saved position is read',
    (tester) async {
      final resume = Completer<void>();
      final writes = <int>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            if (request.method == 'GET') await resume.future;
            if (request.method == 'POST') {
              writes.add(request.data['position'] as int);
            }
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'progress': {'position': 7},
                },
              ),
            );
          },
        ),
      );
      await tester.pumpWidget(view(LearningRepository(dio)));
      await tester.pump();
      expect(writes, isEmpty);
      resume.complete();
      await tester.pumpAndSettle();
      expect(writes, isNotEmpty);
      expect(writes, everyElement(7));
      expect(tester.takeException(), isNull);
    },
  );
}
