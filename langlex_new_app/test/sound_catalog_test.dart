import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/pages/phonics_practice_page.dart';
import 'package:langlex_new_app/features/learning/pages/practice_catalog_page.dart';

void main() {
  final requests = <RequestOptions>[];
  var failPractice = false;
  const titles = [
    'नाक उच्चारण वाले शब्द',
    'दिन उच्चारण वाले शब्द',
    'खीर उच्चारण वाले शब्द',
    'तीन अक्षर वाले शब्दों का उच्चारण अभ्यास',
  ];

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    if (const bool.fromEnvironment('CAPTURE_SOUNDS')) {
      final file = File(
        '/System/Library/Fonts/Supplemental/Devanagari Sangam MN.ttc',
      );
      if (await file.exists()) {
        await (FontLoader('Devanagari')..addFont(
              file.readAsBytes().then((bytes) => bytes.buffer.asByteData()),
            ))
            .load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  setUp(() {
    requests.clear();
    failPractice = false;
  });

  Widget view({double scale = 1}) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          final categories = request.queryParameters['view'] == 'courses';
          final page = request.queryParameters['page'] ?? 1;
          if (request.path == 'phonics' && !categories && failPractice) {
            handler.reject(DioException(requestOptions: request));
            return;
          }
          handler.resolve(
            Response(
              requestOptions: request,
              data: {
                'phonics': categories
                    ? List.generate(
                        titles.length,
                        (i) => {
                          'id': i + 1,
                          'title': titles[i],
                          'sound_count': i == 0 ? 3 : 18,
                        },
                      )
                    : List.generate(
                        page == 1 ? 2 : 1,
                        (i) => {
                          'id': (page - 1) * 2 + i + 1,
                          'word': 'काक',
                          'sentence': 'काग पेड़ पर है।',
                          'coursename': titles.first,
                          'language': 'Hindi',
                        },
                      ),
                'pagination': {
                  'page': page,
                  'limit': categories ? 20 : 2,
                  'total': categories ? titles.length : 3,
                },
                'progress': {'position': 0},
              },
            ),
          );
        },
      ),
    );
    return RepositoryProvider.value(
      value: LearningRepository(dio),
      child: MaterialApp(
        theme: ThemeData(
          fontFamilyFallback: const ['Devanagari'],
          textTheme: GoogleFonts.montserratTextTheme().apply(
            fontFamilyFallback: const ['Devanagari'],
          ),
        ),
        builder: (context, child) {
          ResponsiveUtils().init(context);
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(
              key: const ValueKey('sounds-capture'),
              child: child!,
            ),
          );
        },
        home: const PracticeCatalogPage(
          resource: 'phonics',
          language: 'Hindi',
          homeLanguage: 'English',
        ),
      ),
    );
  }

  testWidgets(
    'catalog shows categories; Start opens all sounds in only that category',
    (tester) async {
      await tester.pumpWidget(view());
      await tester.pumpAndSettle();
      expect(find.text(titles.first), findsOneWidget);
      expect(find.text('काक'), findsNothing);
      expect(find.text('काग पेड़ पर है।'), findsNothing);
      expect(find.textContaining('Start set'), findsNothing);
      expect(requests.single.queryParameters['view'], 'courses');
      await tester.tap(find.text('Start').first);
      await tester.pumpAndSettle();
      final practice = tester.widget<PhonicsPracticePage>(
        find.byType(PhonicsPracticePage),
      );
      expect(practice.phonics.length, 3);
      expect(practice.contentKey, 'phonics-course-1-Hindi');
      final loads = requests.where(
        (r) => r.path == 'phonics' && r.queryParameters['view'] == null,
      );
      expect(loads.map((r) => r.queryParameters['page']), [1, 2]);
      expect(
        loads.every(
          (r) =>
              r.queryParameters['language'] == 'Hindi' &&
              r.queryParameters['course'] == titles.first,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed category start remains on catalog and can retry', (
    tester,
  ) async {
    failPractice = true;
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start').first);
    await tester.pumpAndSettle();
    expect(find.text('Could not load learning content.'), findsOneWidget);
    expect(find.byType(PhonicsPracticePage), findsNothing);
    failPractice = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(PhonicsPracticePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets('sound category layout fits $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(view(scale: size.width == 320 ? 1.8 : 1));
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pumpAndSettle();
      expect(find.text('Start'), findsNWidgets(4));
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_SOUNDS')) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('sounds-capture')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            '/tmp/langlex-sounds/sounds-${size.width.toInt()}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.ensureVisible(find.text('Start').last);
      await tester.pumpAndSettle();
      expect(find.text('Start').last.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
