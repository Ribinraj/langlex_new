import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/pages/quiz_practice_page.dart';

class _QuizRepository extends LearningRepository {
  _QuizRepository(this.resume) : super(Dio());
  final Future<ContentProgress> resume;
  final answers = <String>[];
  bool failSave = false;
  @override
  Future<ContentProgress> getContentProgress({
    required String contentType,
    required String contentKey,
  }) => resume;
  @override
  Future<ContentProgress> recordContentItem({
    required String contentType,
    required String contentKey,
    required String itemKey,
    required int position,
    required int totalItems,
    String status = 'in_progress',
    bool? isCorrect,
    String? answer,
  }) async {
    answers.add(itemKey);
    if (failSave) throw Exception('Offline');
    return ContentProgress.fromJson({});
  }

  @override
  Future<ContentProgress> restartContentProgress({
    required String contentType,
    required String contentKey,
  }) async => ContentProgress.fromJson({});
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (_) async {
        throw PlatformException(code: 'test_audio_unavailable');
      },
    );
  });
  final questions = List.generate(
    4,
    (i) => QuizQuestion.fromJson({
      'id': i + 1,
      'Question': 'Question ${i + 1}',
      'ca': 'Answer ${i + 1}',
      'o1': 'Wrong ${i + 1}',
      'Language': 'English',
      'topic': 'Letters',
    }),
  );
  Future<void> mount(WidgetTester tester, _QuizRepository repo) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepositoryProvider<LearningRepository>.value(
        value: repo,
        child: MaterialApp(
          builder: (context, child) {
            ResponsiveUtils().init(context);
            return child!;
          },
          home: QuizPracticePage(
            questions: questions,
            homeLanguage: 'English',
            contentKey: 'test-quiz',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> answer(WidgetTester tester, int question) async {
    await tester.ensureVisible(find.text('Answer $question'));
    await tester.tap(find.text('Answer $question'));
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Next question'));
    await tester.tap(find.text('Next question'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Next advances once and a delayed resume cannot replay an answered question',
    (tester) async {
      final pending = Completer<ContentProgress>();
      final repo = _QuizRepository(pending.future);
      await mount(tester, repo);
      await answer(tester, 1);
      await next(tester);
      await answer(tester, 2);
      await next(tester);
      expect(find.text('Question 3'), findsOneWidget);
      pending.complete(
        ContentProgress.fromJson({
          'completed_item_keys': ['quiz-1'],
          'score': 1,
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('Question 3'), findsOneWidget);
      expect(find.text('Question 2'), findsNothing);
      expect(repo.answers, ['quiz-1', 'quiz-2']);
    },
  );
  testWidgets(
    'a second tap on an outgoing Next button cannot skip a question',
    (tester) async {
      final repo = _QuizRepository(Future.value(ContentProgress.fromJson({})));
      await mount(tester, repo);
      await answer(tester, 1);
      final nextButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Next question'),
      );
      nextButton.onPressed!();
      nextButton.onPressed!();
      await tester.pumpAndSettle();
      expect(find.text('Question 2'), findsOneWidget);
      expect(find.text('Question 3'), findsNothing);
    },
  );
  testWidgets(
    'resume skips saved answers and a failed save does not block Next',
    (tester) async {
      final repo = _QuizRepository(
        Future.value(
          ContentProgress.fromJson({
            'completed_item_keys': ['quiz-1', 'quiz-3'],
            'score': 2,
          }),
        ),
      )..failSave = true;
      await mount(tester, repo);
      expect(find.text('Question 2'), findsOneWidget);
      await answer(tester, 2);
      await next(tester);
      expect(find.text('Question 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'restart invalidates pending resume and resets the next question',
    (tester) async {
      final pending = Completer<ContentProgress>();
      await mount(tester, _QuizRepository(pending.future));
      await answer(tester, 1);
      await next(tester);
      await tester.ensureVisible(find.byTooltip('Restart'));
      await tester.tap(find.byTooltip('Restart'));
      await tester.pumpAndSettle();
      pending.complete(
        ContentProgress.fromJson({
          'completed_item_keys': ['quiz-1', 'quiz-2'],
          'score': 2,
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('Question 1'), findsOneWidget);
      await answer(tester, 1);
      await next(tester);
      expect(find.text('Question 2'), findsOneWidget);
    },
  );
}
