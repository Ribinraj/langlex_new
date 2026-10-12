import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/local_storage.dart';
import 'package:langlex_new_app/core/storage_keys.dart';
import 'package:langlex_new_app/features/dashboard/widgets/sound_effects_setting.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LearningAssetSound.initialize();
  });
  for (final scale in [1.0, 1.8]) {
    testWidgets(
      'Profile switch persists off/on and fits narrow width at $scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(320, 700),
                textScaler: TextScaler.linear(scale),
              ),
              child: const Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: SoundEffectsSetting(t: AppLocalizations('English')),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('App sound effects'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(StorageKeys.soundEffectsEnabled), isFalse);
        // Logout must not discard the preference for this device.
        await LocalStorage.clearAuthSession();
        await LearningAssetSound.initialize();
        expect(LearningAssetSound.enabled.value, isFalse);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(prefs.getBool(StorageKeys.soundEffectsEnabled), isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
