import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/widgets/paged_learning_list.dart';

void main() {
  test(
    'startup requests only bounded language previews, never all pages',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final calls = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls.add(request);
            final resource = request.uri.path.split('/').last;
            final data = switch (resource) {
              'learning-setup' => {
                'learning_setup': {
                  'selected_languages': ['English', 'Hindi', 'Kannada'],
                  'learning_language': 'Hindi',
                  'level': 'Nursery',
                },
              },
              'languages' => {
                'languages': ['Hindi', 'English'],
              },
              _ => {
                resource: [],
                'pagination': {
                  'page': 1,
                  'limit': request.queryParameters['limit'] ?? 20,
                  'total': 1000,
                },
              },
            };
            handler.resolve(
              Response(requestOptions: request, statusCode: 200, data: data),
            );
          },
        ),
      );
      final catalog = await LearningRepository(dio).fetchCatalog();
      expect(calls.length, 9);
      for (final request in calls.where(
        (r) => [
          'courses',
          'content',
          'alphabets',
          'quizzes',
          'phonics',
          'stories',
        ].contains(r.path),
      )) {
        expect(request.queryParameters['language'], 'Hindi');
        expect(request.queryParameters['limit'], lessThanOrEqualTo(20));
      }
      expect(catalog.totals['content'], 1000);
      calls.clear();
      final result = await LearningRepository(dio)
          .fetchPage<Map<String, dynamic>>(
            'quizzes',
            (row) => row,
            page: 4,
            filters: {'language': 'Hindi'},
          );
      expect(calls.single.queryParameters['page'], 4);
      expect(result.total, 1000);
    },
  );

  testWidgets(
    'scroll appends pages, preserves items and retries without repeated requests',
    (tester) async {
      final requests = <int>[];
      var fail = true;
      final pending = Completer<CatalogPage<int>>();
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: controller,
              child: PagedLearningList<int>(
                load: (page) async {
                  requests.add(page);
                  if (page == 2 && fail) throw Exception('offline');
                  if (page == 2) return pending.future;
                  return CatalogPage(
                    items: [page],
                    page: page,
                    limit: 1,
                    total: 2,
                  );
                },
                builder: (_, page) => Column(
                  children: [
                    for (final item in page.items)
                      SizedBox(height: 1000, child: Text('Item $item')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, [1]);
      expect(find.byTooltip('Next page'), findsNothing);
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(requests, [1, 2]);
      expect(find.text('Item 1'), findsOneWidget);
      expect(
        find.text('Could not load more. Your place is saved.'),
        findsOneWidget,
      );
      controller.jumpTo(controller.offset - 10);
      await tester.pumpAndSettle();
      expect(requests, [1, 2]);
      fail = false;
      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await tester.pump();
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      expect(requests, [1, 2, 2]);
      final offset = controller.offset;
      pending.complete(
        const CatalogPage(items: [2], page: 2, limit: 1, total: 2),
      );
      await tester.pumpAndSettle();
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(controller.offset, offset);
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(requests, [1, 2, 2]);
      expect(find.text('End of results'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets(
    'short pages fill the viewport automatically and empty pages stop loading',
    (tester) async {
      final requests = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PagedLearningList<int>(
                load: (page) async {
                  requests.add(page);
                  return CatalogPage(
                    items: page == 3 ? [] : [page],
                    page: page,
                    limit: 1,
                    total: 100,
                  );
                },
                builder: (_, page) => Text(page.items.join(',')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, [1, 2, 3]);
      expect(find.text('1,2'), findsOneWidget);
    },
  );

  testWidgets(
    'changing filters discards a slow response from the previous query',
    (tester) async {
      final old = Completer<CatalogPage<int>>();
      Widget view(String key) => MaterialApp(
        home: Scaffold(
          body: PagedLearningList<int>(
            key: ValueKey(key),
            load: (_) => key == 'old'
                ? old.future
                : Future.value(
                    const CatalogPage(items: [2], page: 1, limit: 20, total: 1),
                  ),
            builder: (_, page) => Text('Item ${page.items.single}'),
          ),
        ),
      );
      await tester.pumpWidget(view('old'));
      await tester.pumpWidget(view('new'));
      await tester.pumpAndSettle();
      old.complete(const CatalogPage(items: [1], page: 1, limit: 20, total: 1));
      await tester.pumpAndSettle();
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 1'), findsNothing);
    },
  );
}
