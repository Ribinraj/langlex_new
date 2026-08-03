import 'package:langlex_new_app/features/authentication/auth_repo.dart';
import 'package:langlex_new_app/features/authentication/models/app_user.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUserExists extends AuthState {
  const AuthUserExists({required this.mobileNumber});

  final String mobileNumber;
}

class AuthUserNotExists extends AuthState {
  const AuthUserNotExists({required this.mobileNumber});

  final String mobileNumber;
}

class AuthOtpSent extends AuthState {
  const AuthOtpSent({
    required this.mobileNumber,
    this.resendAfterSeconds = 30,
    this.isResend = false,
  });

  final String mobileNumber;
  final int resendAfterSeconds;
  final bool isResend;
}

class AuthSocialRegistrationRequired extends AuthState {
  const AuthSocialRegistrationRequired(this.draft);

  final SocialRegistrationDraft draft;
}

class AuthOtpVerified extends AuthState {
  const AuthOtpVerified({required this.user});

  final AppUser user;
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});

  final AppUser user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}
