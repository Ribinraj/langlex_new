import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/appconstants.dart';
import 'package:langlex_new_app/core/network_services.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/authentication/auth_repo.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_bloc.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_event.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_state.dart';
import 'package:langlex_new_app/features/authentication/pages/verify_otp_page.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/pages/language_selection_page.dart';
import 'package:langlex_new_app/features/learning/pages/learning_setup_page.dart';
import 'package:langlex_new_app/features/dashboard/widgets/home_language_switcher.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Preview',
    )..addFont(rootBundle.load('assets/fonts/Montserrat-Regular.ttf'))).load();
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

    GoogleFonts.config.allowRuntimeFetching = false;
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  final requests = <RequestOptions>[];
  Map<String, dynamic> setup = {};
  Dio client() {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          final path = request.path;
          if (request.method == 'PUT') {
            setup = Map<String, dynamic>.from(request.data as Map);
          }
          final data = path.contains('learning-setup')
              ? {'learning_setup': setup}
              : path == 'languages'
              ? {
                  'languages': [
                    'English',
                    'Hindi',
                    'Kannada',
                    'Maithili',
                    'Assamese',
                  ],
                }
              : {
                  path: <dynamic>[],
                  'pagination': {'total': 0},
                };
          handler.resolve(
            Response(requestOptions: request, statusCode: 200, data: data),
          );
        },
      ),
    );
    return dio;
  }

  setUp(() {
    requests.clear();
    setup = {
      'child_name': 'Alex',
      'active_language': 'English',
      'level': 'Nursery',
    };
  });

  test('unconfigured accounts load choices without learning content', () async {
    final catalog = await LearningRepository(client()).fetchCatalog();
    expect(catalog.setup.hasSelectedLanguages, false);
    expect(requests.length, 3);
    expect(requests.map((r) => r.path), containsAll(['languages', 'plans']));
  });

  testWidgets('learning setup saves without age group or daily goals', (
    tester,
  ) async {
    setup.addAll({
      'selected_languages': ['English', 'Hindi', 'Kannada'],
      'age_group': '3-4 years',
      'daily_goal_minutes': 30,
    });
    final repo = LearningRepository(client());
    final bloc = (await tester.runAsync(() async {
      final bloc = LearningBloc(repo);
      bloc.add(const LoadLearningCatalogEvent());
      await bloc.stream.firstWhere((state) => state is LearningLoaded);
      return bloc;
    }))!;
    final catalog = (bloc.state as LearningLoaded).catalog;
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          builder: (context, child) {
            ResponsiveUtils().init(context);
            return child!;
          },
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LearningSetupPage(catalog: catalog),
                  ),
                ),
                child: const Text('Open setup'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open setup'));
    await tester.pumpAndSettle();
    expect(find.text('Age group'), findsNothing);
    expect(find.textContaining('Daily goal'), findsNothing);
    expect(find.byType(Slider), findsNothing);
    expect(find.text('Languages and level'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Sam');
    await tester.tap(find.byType(FilledButton));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(setup['child_name'], 'Sam');
    expect(setup['level'], 'Nursery');
    expect(setup['active_language'], 'English');
    expect(setup.containsKey('age_group'), false);
    expect(setup.containsKey('daily_goal_minutes'), false);
    expect(
      requests.any((request) => request.path.contains('daily-goal')),
      false,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => bloc.close());
  });

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(834, 1112),
  ]) {
    testWidgets('choose exactly three and save at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = LearningRepository(client());
      final catalog = (await tester.runAsync(() => repo.fetchCatalog()))!;
      final bloc = (await tester.runAsync(() async {
        final bloc = LearningBloc(repo);
        bloc.add(const LoadLearningCatalogEvent());
        await bloc.stream.firstWhere((state) => state is LearningLoaded);
        return bloc;
      }))!;
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            theme: ThemeData(
              fontFamily: 'Preview',
              fontFamilyFallback: const ['Devanagari', 'Kannada', 'Bengali'],
            ),
            home: RepaintBoundary(
              key: const ValueKey('capture'),
              child: LanguageSelectionPage(catalog: catalog),
            ),
          ),
        ),
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      for (final language in ['English', 'Hindi', 'Kannada']) {
        final tile = find.byKey(ValueKey('language-$language'));
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
      }
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('language-Maithili')),
            )
            .onChanged,
        isNull,
      );
      if (size.width == 390) await capture(tester, 'language-selection');
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(setup['selected_languages'], ['English', 'Hindi', 'Kannada']);
      expect(setup['active_language'], 'English');
      expect(
        (bloc.state as LearningLoaded).catalog.setup.hasSelectedLanguages,
        true,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => bloc.close());
    });
  }

  testWidgets(
    'Home offers only saved languages and changes UI plus API filters',
    (tester) async {
      setup['selected_languages'] = ['English', 'Hindi', 'Kannada'];
      final repo = LearningRepository(client());
      final bloc = (await tester.runAsync(() async {
        final bloc = LearningBloc(repo);
        bloc.add(const LoadLearningCatalogEvent());
        await bloc.stream.firstWhere((state) => state is LearningLoaded);
        return bloc;
      }))!;
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            theme: ThemeData(
              fontFamily: 'Preview',
              fontFamilyFallback: const ['Devanagari', 'Kannada', 'Bengali'],
            ),
            home: Scaffold(body: HomeLanguageSwitcher()),
          ),
        ),
      );
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(find.text('Assamese'), findsNothing);
      expect(find.text('Maithili'), findsNothing);
      await tester.tap(find.text('Hindi'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      final state = bloc.state as LearningLoaded;
      expect(state.catalog.setup.primaryLanguage, 'Hindi');
      expect(state.catalog.setup.learningLanguage, 'Hindi');
      expect(
        AppLocalizations(state.catalog.setup.activeLanguage).home,
        isNot('Home'),
      );
      final afterSave = requests.skipWhile((r) => r.method != 'PUT');
      for (final request in afterSave.where(
        (r) => r.queryParameters.containsKey('language'),
      )) {
        expect(request.queryParameters['language'], 'Hindi');
        expect(request.extra[DioClient.skipAuthKey], false);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => bloc.close());
    },
  );

  test('regional interface translations include dynamic text', () {
    expect(const AppLocalizations('Assamese').knowledge, 'জ্ঞান');
    expect(
      const AppLocalizations('Maithili').helloLearner('Alex'),
      'नमस्कार, Alex',
    );
    expect(
      const AppLocalizations('Assamese').helloLearner('Alex'),
      'নমস্কাৰ, Alex',
    );
  });

  testWidgets('OTP preview comes from server and updates on resend', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var count = 0;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {
                  'display_otp': ++count == 1 ? '654321' : '246810',
                  'resend_after_seconds': 1,
                  'expires_at': DateTime.now()
                      .add(const Duration(minutes: 5))
                      .toIso8601String(),
                },
              ),
            );
          },
        ),
      );
    final bloc = (await tester.runAsync(() async {
      final bloc = AuthBloc(AuthRepository(dio));
      bloc.add(const SendOtpEvent(mobileNumber: '9000000001'));
      await bloc.stream.firstWhere((state) => state is AuthOtpSent);
      return bloc;
    }))!;
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: ThemeData(
            fontFamily: 'Preview',
            fontFamilyFallback: const ['Devanagari', 'Kannada', 'Bengali'],
          ),
          home: RepaintBoundary(
            key: ValueKey('capture'),
            child: VerifyOtpPage(mobileNumber: '9000000001'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('654321'), findsOneWidget);
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage(AppConstants.loginImage),
        tester.element(find.byType(VerifyOtpPage)),
      );
      await GoogleFonts.pendingFonts();
    });
    await tester.pumpAndSettle();
    await capture(tester, 'otp-preview');
    await tester.pump(const Duration(seconds: 2));
    await tester.runAsync(() async {
      bloc.add(const ResendOtpEvent(mobileNumber: '9000000001'));
      await bloc.stream.firstWhere((state) => state is AuthOtpSent);
    });
    await tester.pumpAndSettle();
    expect(find.text('246810'), findsOneWidget);
    expect(find.text('654321'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => bloc.close());
  });
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_FLOW')) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/ui-previews').create(recursive: true);
    await File(
      'build/ui-previews/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
