import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/pages/practice_catalog_page.dart';
import 'package:langlex_new_app/features/learning/pages/quiz_practice_page.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  Widget view(Dio dio, String resource) => RepositoryProvider.value(
    value: LearningRepository(dio),
    child: MaterialApp(
      builder: (context, child) {
        ResponsiveUtils().init(context);
        return child!;
      },
      home: PracticeCatalogPage(
        resource: resource,
        language: 'English',
        homeLanguage: 'English',
      ),
    ),
  );

  testWidgets(
    'quiz cards group complete topics and load all questions before starting',
    (tester) async {
      final dio = Dio();
      final calls = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls.add(request);
            if (request.path.contains('content-progress')) {
              handler.resolve(
                Response(requestOptions: request, data: {'progress': {}}),
              );
              return;
            }
            final page = request.queryParameters['page'] as int;
            final limit = request.queryParameters['limit'] as int;
            final topics = request.queryParameters['view'] == 'sets';
            final rows = topics
                ? [
                    {
                      'id': 1,
                      'topic': 'Alphabet Letter Recognition',
                      'language': 'English',
                      'question_count': 104,
                    },
                    {
                      'id': 105,
                      'topic': 'Animals',
                      'language': 'English',
                      'question_count': 3,
                    },
                  ]
                : List.generate(
                    104,
                    (i) => {
                      'id': i + 1,
                      'topic': 'Alphabet Letter Recognition',
                      'Question': 'Question ${i + 1}',
                      'ca': 'Answer ${i + 1}',
                      'o1': 'Other',
                    },
                  );
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'quizzes': rows.skip((page - 1) * limit).take(limit).toList(),
                  'pagination': {
                    'page': page,
                    'limit': limit,
                    'total': rows.length,
                  },
                },
              ),
            );
          },
        ),
      );
      await tester.pumpWidget(view(dio, 'quizzes'));
      await tester.pumpAndSettle();
      expect(find.text('Alphabet Letter Recognition'), findsOneWidget);
      expect(find.text('Animals'), findsOneWidget);
      expect(find.text('2 topics'), findsOneWidget);
      expect(find.text('104 questions'), findsOneWidget);
      expect(calls.length, 1);
      final start = find.text('Start quiz · 104 questions');
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      final quiz = tester.widget<QuizPracticePage>(
        find.byType(QuizPracticePage),
      );
      expect(quiz.questions.length, 104);
      expect(quiz.questions.last.id, 104);
      expect(quiz.contentKey, 'quiz-topic-1');
      final questionCalls = calls
          .where((r) => r.queryParameters['topic'] != null)
          .toList();
      expect(questionCalls.length, 2);
      expect(questionCalls.map((r) => r.queryParameters['page']), [1, 2]);
      expect(
        questionCalls.every(
          (r) => r.queryParameters['topic'] == 'Alphabet Letter Recognition',
        ),
        true,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'alphabet tiles show each letter once with all examples accessible',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.queryParameters['view'], 'letters');
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'alphabets': [
                    {
                      'id': 1,
                      'letter': 'A',
                      'coursename': 'Alphabets',
                      'examples': [
                        {'ill_word': 'Apple'},
                        {'ill_word': 'Ant'},
                      ],
                    },
                    {
                      'id': 3,
                      'letter': 'B',
                      'coursename': 'Alphabets',
                      'examples': [
                        {'ill_word': 'Ball'},
                      ],
                    },
                  ],
                  'pagination': {'page': 1, 'limit': 20, 'total': 2},
                },
              ),
            );
          },
        ),
      );
      await tester.pumpWidget(view(dio, 'alphabets'));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('2 examples'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('A')).dx,
        lessThan(tester.getTopLeft(find.text('B')).dx),
      );
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Ant'), findsOneWidget);
      expect(find.byTooltip('Play letter A'), findsOneWidget);
      expect(find.byTooltip('Play Apple'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
