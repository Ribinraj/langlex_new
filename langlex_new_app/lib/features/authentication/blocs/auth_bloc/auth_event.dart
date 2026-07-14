import 'package:langlex_new_app/features/authentication/models/app_user.dart';

abstract class AuthEvent {
  const AuthEvent();
}

class CheckUserEvent extends AuthEvent {
  const CheckUserEvent({required this.mobileNumber});

  final String mobileNumber;
}

class RegisterEvent extends AuthEvent {
  const RegisterEvent({
    required this.fullName,
    required this.mobileNumber,
    required this.school,
    required this.city,
    required this.state,
    this.email,
  });

  final String fullName;
  final String mobileNumber;
  final String school;
  final String city;
  final String state;
  final String? email;
}

class SendOtpEvent extends AuthEvent {
  const SendOtpEvent({required this.mobileNumber});

  final String mobileNumber;
}

class VerifyOtpEvent extends AuthEvent {
  const VerifyOtpEvent({required this.mobileNumber, required this.otp});

  final String mobileNumber;
  final String otp;
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class CheckLoginStatusEvent extends AuthEvent {
  const CheckLoginStatusEvent();
}

class UserChangedEvent extends AuthEvent {
  const UserChangedEvent(this.user);

  final AppUser user;
}
