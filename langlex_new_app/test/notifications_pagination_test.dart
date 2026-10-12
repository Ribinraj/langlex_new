import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/notifications/notification_repo.dart';
import 'package:langlex_new_app/features/notifications/pages/notifications_page.dart';

void main() {
  testWidgets(
    'notifications append on scroll and marking read retains the list',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final requests = <int>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            final page = request.queryParameters['page'] as int? ?? 1;
            if (request.method == 'GET') requests.add(page);
            handler.resolve(
              Response(
                requestOptions: request,
                data: request.method == 'GET'
                    ? {
                        'notifications': List.generate(
                          20,
                          (i) => {
                            'id': (page - 1) * 20 + i + 1,
                            'title': 'Notice ${(page - 1) * 20 + i + 1}',
                            'body': 'Your next learning activity is ready.',
                            'type': 'info',
                            'is_read': false,
                            'created_at': '2026-09-17T12:00:00Z',
                          },
                        ),
                        'pagination': {'total': 40, 'has_more': page == 1},
                        'unread_count': 40,
                      }
                    : {'unread_count': 39},
              ),
            );
          },
        ),
      );
      await tester.pumpWidget(
        RepositoryProvider.value(
          value: NotificationRepository(dio),
          child: MaterialApp(
            builder: (context, child) {
              ResponsiveUtils().init(context);
              return child!;
            },
            home: const NotificationsPage(homeLanguage: 'English'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, [1]);
      await tester.tap(find.text('Notice 1'));
      await tester.pumpAndSettle();
      expect(requests, [1]);
      expect(find.text('Read'), findsOneWidget);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(requests, [1, 2]);
      scrollable.position.jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('Notice 1'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);
      expect(find.byTooltip('Next page'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
