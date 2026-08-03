import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/routes/approutes.dart';
import 'package:langlex_new_app/features/authentication/auth_repo.dart';
import 'package:langlex_new_app/features/authentication/pages/login_page.dart';
import 'package:langlex_new_app/features/authentication/pages/signup_page.dart';
import 'package:langlex_new_app/features/authentication/pages/splashpage.dart';
import 'package:langlex_new_app/features/authentication/pages/verify_otp_page.dart';
import 'package:langlex_new_app/features/dashboard/pages/dashboard_shell_page.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/notifications/pages/notifications_page.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    observers: [AppRoutes.routeObserver],
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) {
          return _fadePage(state: state, child: const SplashPage());
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) {
          return _fadePage(state: state, child: const LoginPage());
        },
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) {
          final extra = state.extra;
          return _fadePage(
            state: state,
            child: SignupPage(
              initialMobileNumber: extra is String ? extra : null,
              socialDraft: extra is SocialRegistrationDraft ? extra : null,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        pageBuilder: (context, state) {
          return _fadePage(
            state: state,
            child: VerifyOtpPage(mobileNumber: state.extra as String? ?? ''),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        pageBuilder: (context, state) {
          return _fadePage(state: state, child: const DashboardShellPage());
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) {
          return _fadePage(
            state: state,
            child: NotificationsPage(homeLanguage: _homeLanguage(context)),
          );
        },
      ),
    ],
  );

  static String _homeLanguage(BuildContext context) {
    final state = context.read<LearningBloc>().state;
    if (state is LearningLoaded) {
      return state.catalog.setup.primaryLanguage;
    }
    return 'English';
  }

  static CustomTransitionPage<void> _fadePage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppMotion.slow,
      reverseTransitionDuration: AppMotion.normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (motionDisabled(context)) return child;

        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.standardCurve,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
