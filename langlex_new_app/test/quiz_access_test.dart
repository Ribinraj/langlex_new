import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/widgets/quiz_catalog_widgets.dart';
import 'package:langlex_new_app/features/payments/pages/payment_checkout_page.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  for (final scenario in [
    'free learner',
    'premium learner',
    'access changed',
    'premium became free',
  ]) {
    testWidgets('quiz topic access: $scenario', (tester) async {
      final calls = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls.add(request);
            if (request.path == 'quizzes' &&
                ['free learner', 'access changed'].contains(scenario)) {
              handler.reject(
                DioException(
                  requestOptions: request,
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: request,
                    statusCode: 403,
                    data: {
                      'message': 'An active Premium subscription is required.',
                    },
                  ),
                ),
              );
              return;
            }
            final data = switch (request.path) {
              'subscriptions/me' => {
                'subscription': scenario == 'premium learner'
                    ? {
                        'status': 'active',
                        'type': 'premium',
                        'started_at': DateTime.now()
                            .subtract(const Duration(days: 1))
                            .toIso8601String(),
                        'expires_at': DateTime.now()
                            .add(const Duration(days: 1))
                            .toIso8601String(),
                      }
                    : {'status': 'free'},
              },
              'plans' => {
                'plans': [
                  {
                    'id': 1,
                    'name': 'Premium',
                    'type': 'premium',
                    'amount': '99',
                    'plan_timeperiod': 'Monthly',
                  },
                ],
              },
              'quizzes' => {
                'quizzes': [],
                'pagination': {'page': 1, 'limit': 100, 'total': 0},
              },
              _ => {'progress': {}},
            };
            handler.resolve(
              Response(requestOptions: request, statusCode: 200, data: data),
            );
          },
        ),
      );
      await tester.pumpWidget(
        RepositoryProvider.value(
          value: LearningRepository(dio),
          child: MaterialApp(
            builder: (context, child) {
              ResponsiveUtils().init(context);
              return child!;
            },
            home: Scaffold(
              body: SingleChildScrollView(
                child: QuizSetCard(
                  topic: {
                    'id': 42,
                    'topic': 'Animals',
                    'language': 'English',
                    'question_count': 2,
                    'show_plan': scenario == 'access changed'
                        ? 'Free'
                        : 'Premium',
                    'locked': scenario != 'premium learner',
                  },
                  homeLanguage: 'English',
                  index: 0,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();
      if (scenario == 'premium learner' || scenario == 'premium became free') {
        expect(calls.where((r) => r.path == 'quizzes').length, 1);
        expect(find.byType(PaymentCheckoutPage), findsNothing);
        expect(calls.where((r) => r.path == 'plans'), isEmpty);
      } else {
        expect(find.byType(PaymentCheckoutPage), findsOneWidget);
        expect(calls.where((r) => r.path == 'quizzes').length, 1);
        Navigator.of(
          tester.element(find.byType(PaymentCheckoutPage)),
        ).pop(false);
        await tester.pumpAndSettle();
        expect(calls.where((r) => r.method == 'POST'), isEmpty);
        expect(calls.where((r) => r.path == 'quizzes').length, 1);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
