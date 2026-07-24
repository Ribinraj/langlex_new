import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/appconstants.dart';
import 'package:langlex_new_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows splash page and unauthenticated login flow', (
    tester,
  ) async {
    await tester.pumpWidget(const LanglexNewApp());

    expect(
      find.image(const AssetImage(AppConstants.splashPageArt)),
      findsOneWidget,
    );
    expect(find.text('Getting your lessons ready...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    final progressBar = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(progressBar.widthFactor, 1.0);

    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text(AppConstants.loginTitle), findsOneWidget);
    expect(find.text(AppConstants.mobileNumberLabel), findsOneWidget);
    expect(find.text(AppConstants.usernameLabel), findsNothing);
    expect(find.text(AppConstants.signupAction), findsNothing);
  });
}
