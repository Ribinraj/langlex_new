import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/network_services.dart';
import 'package:langlex_new_app/core/push_notification_service.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/core/routes/approuter.dart';
import 'package:langlex_new_app/core/routes/approutes.dart';
import 'package:langlex_new_app/features/authentication/auth_repo.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/notifications/notification_repo.dart';
import 'package:langlex_new_app/features/payments/payment_repo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await PushNotificationService.instance.initialize(
    onNotificationTap: (_) => AppRouter.router.go(AppRoutes.notifications),
  );
  runApp(const LanglexNewApp());
}

class LanglexNewApp extends StatelessWidget {
  const LanglexNewApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Appcolors.kprimarycolor,
        primary: Appcolors.kprimarycolor,
        secondary: Appcolors.ksecondarycolor,
        surface: Appcolors.kbackgroundcolor,
      ),
      scaffoldBackgroundColor: Appcolors.kbackgroundcolor,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository(DioClient.create())),
        RepositoryProvider(
          create: (_) => LearningRepository(DioClient.create()),
        ),
        RepositoryProvider(
          create: (_) => PaymentRepository(DioClient.create()),
        ),
        RepositoryProvider(
          create: (_) => NotificationRepository(DioClient.create()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                LearningBloc(context.read<LearningRepository>()),
          ),
        ],
        child: MaterialApp.router(
          title: 'Langlex',
          debugShowCheckedModeBanner: false,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            ResponsiveUtils().init(context);
            return child ?? const SizedBox.shrink();
          },
          theme: baseTheme.copyWith(
            textTheme: GoogleFonts.montserratTextTheme(baseTheme.textTheme),
            primaryTextTheme: GoogleFonts.montserratTextTheme(
              baseTheme.primaryTextTheme,
            ),
            appBarTheme: baseTheme.appBarTheme.copyWith(
              backgroundColor: Appcolors.kbackgroundcolor,
              foregroundColor: Appcolors.ktextdark,
              centerTitle: true,
              elevation: 0,
              titleTextStyle: GoogleFonts.montserrat(
                color: Appcolors.ktextdark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
