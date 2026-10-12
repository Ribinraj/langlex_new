import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/api_exception.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/authentication/auth_repo.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_bloc.dart';
import 'package:langlex_new_app/features/dashboard/pages/dashboard_shell_page.dart';
import 'package:langlex_new_app/features/dashboard/pages/home_page.dart';
import 'package:langlex_new_app/features/dashboard/pages/learn_page.dart';
import 'package:langlex_new_app/features/dashboard/pages/profile_page.dart';
import 'package:langlex_new_app/features/dashboard/widgets/custom_bottom_nav_bar.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/pages/course_detail_page.dart';
import 'package:langlex_new_app/features/learning/pages/practice_catalog_page.dart';
import 'package:langlex_new_app/features/learning/pages/story_reader_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repository extends LearningRepository {
  _Repository(super.dio);
  bool fail = false;
  Future<void>? pendingLoad;
  int attempts = 0;
  @override
  Future<LearningCatalog> fetchCatalog() async {
    attempts++;
    await pendingLoad;
    if (fail) throw ApiException('Offline');
    return LearningCatalog.fromApi(
      languages: ['English'],
      courses: [],
      content: [],
      alphabets: [],
      quizzes: [],
      phonics: [],
      stories: [],
      plans: [],
      setup: {
        'child_name': 'Alex',
        'selected_languages': ['English', 'Hindi', 'Kannada'],
        'learning_language': 'English',
        'primary_language': 'English',
        'level': 'LKG',
        'is_configured': true,
      },
    );
  }
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    if (const bool.fromEnvironment('CAPTURE_FLOW')) {
      for (final entry in {
        'Devanagari':
            '/System/Library/Fonts/Supplemental/Devanagari Sangam MN.ttc',
        'Kannada': '/System/Library/Fonts/NotoSansKannada.ttc',
        'Bengali': '/System/Library/Fonts/Supplemental/Bangla Sangam MN.ttc',
      }.entries) {
        if (await File(entry.value).exists()) {
          await (FontLoader(entry.key)..addFont(
                File(
                  entry.value,
                ).readAsBytes().then((bytes) => bytes.buffer.asByteData()),
              ))
              .load();
        }
      }
    }

    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers.global/events'),
          (_) async => null,
        );
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final requests = <RequestOptions>[];
  Dio client({
    int courseCount = 1,
    List<Map<String, dynamic>>? alphabetRows,
    bool emptyOnSearch = false,
  }) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          final resource = request.path;
          final rawRows = switch (resource) {
            'courses' => List.generate(
              courseCount,
              (i) => {
                'id': 308 + i,
                'title': i == 0 ? 'Pet Animals' : 'Animal topic $i',
                'language': 'English',
                'word_count': 1,
              },
            ),
            'content' => [
              {
                'id': 1,
                'content': 'Cat',
                'course': 'Pet Animals',
                'language': 'English',
              },
            ],
            'stories' => [
              {
                'id': 1,
                'title': 'The little bird',
                'text': 'A bird sings.',
                'language': 'English',
                'grade': 'Nursery',
              },
            ],
            'alphabets' =>
              alphabetRows ??
                  [
                    {
                      'id': 1,
                      'letter': 'A',
                      'coursename': 'Alphabets',
                      'examples': [
                        {'ill_word': 'Apple'},
                      ],
                    },
                  ],
            _ => <Map<String, dynamic>>[],
          };
          final rows =
              emptyOnSearch &&
                  '${request.queryParameters['search'] ?? ''}'.trim().isNotEmpty
              ? <Map<String, dynamic>>[]
              : rawRows;
          handler.resolve(
            Response(
              requestOptions: request,
              data: {
                resource: rows,
                'pagination': {
                  'page': request.queryParameters['page'] ?? 1,
                  'limit': 20,
                  'total': rows.length,
                },
                'progress': {'position': 0},
              },
            ),
          );
        },
      ),
    );
    return dio;
  }

  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
    bool settle = true,
    bool disableAnimations = false,
    EdgeInsets safePadding = EdgeInsets.zero,
    _Repository? repository,
  }) async {
    requests.clear();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = repository ?? _Repository(client());
    await tester.pumpWidget(
      RepositoryProvider<LearningRepository>.value(
        value: repo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => LearningBloc(repo)),
            BlocProvider(create: (_) => AuthBloc(AuthRepository(Dio()))),
          ],
          child: MaterialApp(
            theme: ThemeData(
              fontFamilyFallback: const ['Devanagari', 'Kannada', 'Bengali'],
              textTheme: GoogleFonts.montserratTextTheme().apply(
                fontFamilyFallback: const ['Devanagari', 'Kannada', 'Bengali'],
              ),
            ),
            builder: (context, child) {
              ResponsiveUtils().init(context);
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: disableAnimations,
                  padding: safePadding,
                  viewPadding: safePadding,
                ),
                child: RepaintBoundary(
                  key: const ValueKey('capture'),
                  child: child!,
                ),
              );
            },
            home: const DashboardShellPage(),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/kids_image.png'),
        tester.element(find.byType(HomePage)),
      );
      await precacheImage(
        const AssetImage('assets/images/knowledge-fox.png'),
        tester.element(find.byType(HomePage)),
      );
      await GoogleFonts.pendingFonts();
    });
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final finder = find.text(label).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> screenshot(
    WidgetTester tester,
    String name, {
    bool settle = true,
  }) async {
    if (!const bool.fromEnvironment('CAPTURE_FLOW')) return;
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    if (settle) await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('/tmp/langlex-flow/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'home shimmers while loading and disposes the animation on success',
    (tester) async {
      final ready = Completer<void>();
      final repo = _Repository(client())..pendingLoad = ready.future;
      final semantics = tester.ensureSemantics();
      try {
        await mount(tester, repository: repo, settle: false);
        expect(find.bySemanticsLabel('Loading lessons...'), findsOneWidget);
        expect(find.byKey(const ValueKey('home-name-shimmer')), findsOneWidget);
        expect(
          find.textContaining('Learner', findRichText: true),
          findsNothing,
        );
        expect(find.textContaining('Hello', findRichText: true), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.pump(const Duration(milliseconds: 500));
        await screenshot(tester, 'home-shimmer', settle: false);
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.descendant(
            of: find.byType(CustomBottomNavBar),
            matching: find.text('Profile'),
          ),
        );
        // The profile progress card also shimmers while this request is pending.
        await tester.pump(const Duration(milliseconds: 350));
        await tester.tap(
          find.descendant(
            of: find.byType(CustomBottomNavBar),
            matching: find.text('Home'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        ready.complete();
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Loading lessons...'), findsNothing);
        expect(find.byKey(const ValueKey('home-name-shimmer')), findsNothing);
        expect(find.textContaining('Alex', findRichText: true), findsOneWidget);
        expect(find.text('Knowledge'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(768, 1024),
  ]) {
    testWidgets('home loading respects reduced motion and fits $size', (
      tester,
    ) async {
      final ready = Completer<void>();
      final repo = _Repository(client())..pendingLoad = ready.future;
      await mount(
        tester,
        repository: repo,
        size: size,
        scale: 1.8,
        disableAnimations: true,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
      await screenshot(tester, 'home-shimmer-${size.width.toInt()}');
      ready.complete();
      await tester.pumpAndSettle();
      expect(find.text('Knowledge'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 1.8),
    (const Size(834, 1112), 1.0),
    (const Size(1440, 900), 1.0),
  ]) {
    testWidgets('alphabet search previews and examples fit $size at $scale', (
      tester,
    ) async {
      final examples = [
        ('A', 'Apple', 'fruits/apples.jpg'),
        ('B', 'Ball', ''),
        ('C', 'Cat', ''),
        ('D', 'Dog', ''),
        ('E', 'Elephant', ''),
        ('F', 'Fish', ''),
      ];
      final rows = [
        for (final (index, item) in examples.indexed)
          {
            'id': index + 1,
            'letter': item.$1,
            'coursename': 'Alphabets',
            'letter_sound': 'https://example.test/letter-${item.$1}.mp3',
            'examples': [
              {
                'ill_word': item.$2,
                'ill_image': item.$3.isEmpty
                    ? ''
                    : 'https://kids.langlex.com/media/images/content_image/${item.$3}',
              },
              if (index == 0) {'ill_word': 'Ant'},
            ],
          },
      ];
      await mount(
        tester,
        size: size,
        scale: scale,
        repository: _Repository(client(alphabetRows: rows)),
      );
      await tap(tester, 'Search');
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Alphabets'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Alphabets'));
      await tester.pumpAndSettle();
      expect(find.text('Letters & sounds'), findsOneWidget);
      expect(find.text('6 letters'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.byTooltip('Listen · A'), findsOneWidget);
      if (scale == 1) {
        expect(
          tester.getCenter(find.text('A')).dy,
          tester.getCenter(find.text('B')).dy,
        );
      }
      expect(tester.takeException(), isNull);
      await screenshot(tester, 'search-alphabets-${size.width.toInt()}-$scale');
      await tester.ensureVisible(find.text('Apple'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      expect(find.text('Ant'), findsOneWidget);
      expect(find.byTooltip('Play letter A'), findsOneWidget);
      expect(find.byTooltip('Play Apple'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await screenshot(tester, 'search-letter-${size.width.toInt()}-$scale');
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Ant'), findsNothing);
    });
  }

  testWidgets(
    'empty search clears the query and restores the selected collection',
    (tester) async {
      await mount(tester, repository: _Repository(client(emptyOnSearch: true)));
      await tap(tester, 'Search');
      await tester.enterText(find.byType(TextField), 'zznothing');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('No matches this time'), findsOneWidget);
      expect(find.text('No results'), findsNothing);
      expect(find.text('Pet Animals'), findsNothing);
      await screenshot(tester, 'empty-search');
      await tester.ensureVisible(find.text('Clear search'));
      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('No matches this time'), findsNothing);
      expect(find.text('Pet Animals'), findsOneWidget);
      expect(requests.last.queryParameters['search'], anyOf('', isNull));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home destinations push pages, keep language, and return to their parent',
    (tester) async {
      await mount(tester);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
      expect(
        tester.getTopLeft(find.text('Alphabets')).dy,
        tester.getTopLeft(find.text('Knowledge')).dy,
      );
      expect(find.byType(CustomBottomNavBar), findsOneWidget);
      expect(find.byType(IndexedStack), findsOneWidget);
      await screenshot(tester, 'home');
      await tester.tap(find.byTooltip('Language'));
      await tester.pumpAndSettle();
      await screenshot(tester, 'language-sheet');
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tap(tester, 'Alphabets');
      expect(
        tester
            .widget<PracticeCatalogPage>(find.byType(PracticeCatalogPage))
            .resource,
        'alphabets',
      );
      expect(find.text('A'), findsOneWidget);
      await screenshot(tester, 'alphabets');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(tester, 'Knowledge');
      expect(find.byType(LearnPage), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Alphabets'), findsNothing);
      expect(find.byType(SegmentedButton<bool>), findsNothing);
      final courseRequest = requests.firstWhere((r) => r.path == 'courses');
      expect(courseRequest.queryParameters['language'], 'English');
      expect(courseRequest.queryParameters['level'], 'LKG');
      await screenshot(tester, 'knowledge');
      await tap(tester, 'Sounds');
      expect(
        tester
            .widget<PracticeCatalogPage>(find.byType(PracticeCatalogPage))
            .resource,
        'phonics',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(tester, 'Pet Animals');
      expect(find.byType(CourseDetailPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      await tap(tester, 'Stories');
      final storyRequest = requests.firstWhere((r) => r.path == 'stories');
      expect(storyRequest.queryParameters['language'], 'English');
      expect(storyRequest.queryParameters.containsKey('level'), isFalse);
      expect(find.text('Alphabets'), findsNothing);
      await screenshot(tester, 'stories');
      await tap(tester, 'The little bird');
      expect(find.byType(StoryReaderPage), findsOneWidget);
      await screenshot(tester, 'story-reader');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(tester, 'Quizzes');
      expect(
        tester
            .widget<PracticeCatalogPage>(find.byType(PracticeCatalogPage))
            .resource,
        'quizzes',
      );
      await screenshot(tester, 'quizzes');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sidebar selects the profile tab and closes the drawer', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await screenshot(tester, 'sidebar');
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('Profile')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(
      tester
          .widget<CustomBottomNavBar>(find.byType(CustomBottomNavBar))
          .selectedIndex,
      2,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsNothing);
    expect(find.byType(Drawer).hitTestable(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets('sidebar remains usable at $size with large text', (
      tester,
    ) async {
      await mount(tester, size: size, scale: 1.8);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      final drawer = find.byType(Drawer);
      final notifications = find.descendant(
        of: drawer,
        matching: find.text('Notifications'),
      );
      await tester.scrollUntilVisible(
        notifications,
        160,
        scrollable: find.descendant(
          of: drawer,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(notifications.hitTestable(), findsOneWidget);
      expect(find.byTooltip('Close').hitTestable(), findsOneWidget);
      await screenshot(tester, 'sidebar-${size.width.toInt()}');
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(drawer.hitTestable(), findsNothing);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      final search = find.descendant(of: drawer, matching: find.text('Search'));
      await tester.scrollUntilVisible(
        search,
        120,
        scrollable: find.descendant(
          of: drawer,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(search);
      await tester.pumpAndSettle();
      expect(drawer.hitTestable(), findsNothing);
      expect(
        tester
            .widget<CustomBottomNavBar>(find.byType(CustomBottomNavBar))
            .selectedIndex,
        1,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('bottom tabs search all four categories and retain the query', (
    tester,
  ) async {
    await mount(tester);
    final nav = find.byType(CustomBottomNavBar);
    expect(
      tester.widget<CustomBottomNavBar>(nav).items.map((item) => item.label),
      ['Home', 'Search', 'Profile'],
    );
    expect(requests, isEmpty);
    await tester.tap(find.descendant(of: nav, matching: find.text('Search')));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsNothing);
    await tester.enterText(find.byType(TextField), 'Animals');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters['search'], 'Animals');
    expect(requests.last.queryParameters['language'], 'English');
    await screenshot(tester, 'search');
    final chipY = tester
        .getCenter(find.widgetWithText(ChoiceChip, 'Knowledge'))
        .dy;
    for (final label in ['Alphabets', 'Stories', 'Quizzes']) {
      expect(
        tester.getCenter(find.widgetWithText(ChoiceChip, label)).dy,
        chipY,
      );
    }
    for (final (label, resource) in [
      ('Alphabets', 'alphabets'),
      ('Stories', 'stories'),
      ('Quizzes', 'quizzes'),
    ]) {
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
      expect(requests.last.path, resource);
      expect(requests.last.queryParameters['search'], 'Animals');
      expect(requests.last.queryParameters['language'], 'English');
      expect(requests.last.queryParameters.containsKey('level'), isFalse);
      if (resource == 'alphabets') {
        expect(requests.last.queryParameters['view'], 'letters');
      }
    }
    await tester.tap(find.descendant(of: nav, matching: find.text('Profile')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    await screenshot(tester, 'profile-tab');
    await tester.tap(find.descendant(of: nav, matching: find.text('Search')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Animals',
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Quizzes'))
          .selected,
      isTrue,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(tester.widget<CustomBottomNavBar>(nav).selectedIndex, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search content scrolls behind the floating glass bar', (
    tester,
  ) async {
    await mount(tester, repository: _Repository(client(courseCount: 30)));
    final nav = find.byType(CustomBottomNavBar);
    await tester.tap(find.descendant(of: nav, matching: find.text('Search')));
    await tester.pumpAndSettle();
    final scroll = find.byType(CustomScrollView);
    expect(tester.getRect(scroll).bottom, 844);
    final position = tester
        .state<ScrollableState>(
          find.descendant(of: scroll, matching: find.byType(Scrollable)).first,
        )
        .position;
    final item = find.text('Animal topic 5');
    position.jumpTo(tester.getCenter(item).dy - tester.getCenter(nav).dy);
    await tester.pumpAndSettle();
    expect(tester.getRect(item).overlaps(tester.getRect(nav)), isTrue);
    expect(
      find.descendant(of: nav, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    await screenshot(tester, 'glass-search-scrolled');
    await tester.tap(find.descendant(of: nav, matching: find.text('Profile')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search fits above the keyboard on a small phone', (
    tester,
  ) async {
    await mount(tester, size: const Size(320, 568));
    await tester.tap(
      find.descendant(
        of: find.byType(CustomBottomNavBar),
        matching: find.text('Search'),
      ),
    );
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(find.byType(TextField), 'Cat');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(requests.last.queryParameters['search'], 'Cat');
  });

  testWidgets(
    'search header leaves with content and returns on reverse scroll without losing the query',
    (tester) async {
      await mount(tester, repository: _Repository(client(courseCount: 30)));
      await tap(tester, 'Knowledge');
      await tester.enterText(find.byType(TextField), 'Animals');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      final scroll = find.byType(CustomScrollView).last;
      await tester.drag(scroll, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.byType(TextField).hitTestable(), findsNothing);
      await screenshot(tester, 'knowledge-scrolled');
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(of: scroll, matching: find.byType(Scrollable))
                .first,
          )
          .position;
      expect(position.pixels, greaterThan(400));
      await tester.drag(scroll, const Offset(0, 100));
      await tester.pumpAndSettle();
      expect(find.byType(TextField).hitTestable(), findsOneWidget);
      expect(position.pixels, greaterThan(100));
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Animals',
      );
      expect(
        requests
            .where((r) => r.path == 'courses')
            .last
            .queryParameters['search'],
        'Animals',
      );
      await screenshot(tester, 'knowledge-header-returned');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('home can recover from a catalog error', (tester) async {
    final repo = _Repository(client())..fail = true;
    await mount(tester, repository: repo);
    expect(find.text('Retry'), findsOneWidget);
    repo.fail = false;
    await tap(tester, 'Retry');
    expect(repo.attempts, 2);
    expect(find.text('Knowledge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home cards scroll clear of the floating bar with large text', (
    tester,
  ) async {
    await mount(
      tester,
      size: const Size(320, 568),
      scale: 1.8,
      safePadding: const EdgeInsets.only(top: 44, bottom: 34),
    );
    expect(
      find.descendant(
        of: find.byType(HomePage),
        matching: find.byType(Scrollable),
      ),
      findsOneWidget,
    );
    for (final label in ['Knowledge', 'Alphabets', 'Stories', 'Quizzes']) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text(label).hitTestable(), findsOneWidget);
      final card = find
          .ancestor(of: find.text(label), matching: find.byType(InkWell))
          .first;
      expect(
        tester.getRect(card).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(CustomBottomNavBar)).top),
      );
    }
    await screenshot(tester, 'home-safe-area');
    expect(tester.takeException(), isNull);
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 1.8),
    (const Size(568, 320), 1.0),
    (const Size(568, 320), 1.8),
    (const Size(768, 1024), 1.8),
    (const Size(1440, 900), 1.8),
  ]) {
    testWidgets('navigation fits $size at text scale $scale', (tester) async {
      await mount(tester, size: size, scale: scale);
      await screenshot(tester, 'home-header-${size.width.toInt()}-$scale');
      await tester.tap(find.byTooltip('Language'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await screenshot(tester, 'language-sheet-${size.width.toInt()}-$scale');
      await tester.ensureVisible(find.text('Kannada'));
      await tester.pumpAndSettle();
      expect(find.text('Kannada').hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(HomePage),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );
      for (final label in ['Knowledge', 'Alphabets', 'Stories', 'Quizzes']) {
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        expect(find.text(label).hitTestable(), findsOneWidget);
        final card = find
            .ancestor(of: find.text(label), matching: find.byType(InkWell))
            .first;
        final rect = tester.getRect(card);
        expect(rect.height, greaterThanOrEqualTo(44));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      await screenshot(tester, 'home-${size.width.toInt()}-$scale');
      await tap(tester, 'Search');
      expect(tester.takeException(), isNull);
      await screenshot(tester, 'search-${size.width.toInt()}-$scale');
      await tap(tester, 'Home');
      await tap(tester, 'Knowledge');
      expect(tester.takeException(), isNull);
      await screenshot(tester, 'knowledge-${size.width.toInt()}');
      expect(find.text('Alphabets'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(tester, 'Alphabets');
      expect(tester.takeException(), isNull);
    });
  }
}
