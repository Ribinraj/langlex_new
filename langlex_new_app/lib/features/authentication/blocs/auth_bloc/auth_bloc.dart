import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/api_exception.dart';
import 'package:langlex_new_app/features/authentication/auth_repo.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_event.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<CheckLoginStatusEvent>(_onCheckLoginStatus);
    on<CheckUserEvent>(_onCheckUser);
    on<RegisterEvent>(_onRegister);
    on<SocialLoginEvent>(_onSocialLogin);
    on<CompleteSocialRegistrationEvent>(_onCompleteSocialRegistration);
    on<SendOtpEvent>(_onSendOtp);
    on<ResendOtpEvent>(_onResendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<LogoutEvent>(_onLogout);
    on<UserChangedEvent>(_onUserChanged);
  }

  final AuthRepository _repository;

  Future<void> _onCheckLoginStatus(
    CheckLoginStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.restoreSession();
      emit(AuthAuthenticated(user: user));
    } on ApiException {
      emit(const AuthUnauthenticated());
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onCheckUser(
    CheckUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    final mobileNumber = event.mobileNumber.trim();
    final validationError = _validateMobile(mobileNumber);
    if (validationError != null) {
      emit(AuthError(validationError));
      return;
    }

    emit(const AuthLoading());
    try {
      final isExistingUser = await _repository.checkUser(
        mobileNumber: mobileNumber,
      );

      if (!isExistingUser) {
        emit(AuthUserNotExists(mobileNumber: mobileNumber));
        return;
      }

      emit(AuthUserExists(mobileNumber: mobileNumber));
      final resendAfterSeconds = await _repository.sendOtp(
        mobileNumber: mobileNumber,
      );
      emit(
        AuthOtpSent(
          mobileNumber: mobileNumber,
          resendAfterSeconds: resendAfterSeconds,
        ),
      );
    } on ApiException catch (error) {
      emit(AuthError(error.message));
    } catch (_) {
      emit(const AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    final fullName = event.fullName.trim();
    final mobileNumber = event.mobileNumber.trim();
    final school = event.school.trim();
    final city = event.city.trim();
    final state = event.state.trim();
    final validationError = _validateRegistration(
      fullName: fullName,
      mobileNumber: mobileNumber,
      school: school,
      city: city,
      state: state,
      email: event.email,
    );
    if (validationError != null) {
      emit(AuthError(validationError));
      return;
    }

    emit(const AuthLoading());
    try {
      final resendAfterSeconds = await _repository.register(
        fullName: fullName,
        mobileNumber: mobileNumber,
        school: school,
        city: city,
        state: state,
        email: event.email,
      );
      emit(
        AuthOtpSent(
          mobileNumber: mobileNumber,
          resendAfterSeconds: resendAfterSeconds,
        ),
      );
    } on ApiException catch (error) {
      emit(AuthError(error.message));
    } catch (_) {
      emit(const AuthError('Registration failed. Please try again.'));
    }
  }

  Future<void> _onSocialLogin(
    SocialLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _repository.signInWithGoogle();

      switch (result) {
        case SocialLoginAuthenticated():
          emit(AuthAuthenticated(user: result.user));
        case SocialLoginNeedsRegistration():
          emit(AuthSocialRegistrationRequired(result.draft));
        case SocialLoginNeedsOtp():
          emit(
            AuthOtpSent(
              mobileNumber: result.mobileNumber,
              resendAfterSeconds: result.resendAfterSeconds,
            ),
          );
      }
    } on ApiException catch (error) {
      emit(AuthError(error.message));
    } catch (_) {
      emit(const AuthError('Social login failed. Please try again.'));
    }
  }

  Future<void> _onCompleteSocialRegistration(
    CompleteSocialRegistrationEvent event,
    Emitter<AuthState> emit,
  ) async {
    final fullName = event.fullName.trim();
    final mobileNumber = event.mobileNumber.trim();
    final school = event.school.trim();
    final city = event.city.trim();
    final state = event.state.trim();
    final validationError = _validateRegistration(
      fullName: fullName,
      mobileNumber: mobileNumber,
      school: school,
      city: city,
      state: state,
      email: event.email,
    );
    if (validationError != null) {
      emit(AuthError(validationError));
      return;
    }

    emit(const AuthLoading());
    try {
      final resendAfterSeconds = await _repository.completeSocialRegistration(
        fullName: fullName,
        mobileNumber: mobileNumber,
        school: school,
        city: city,
        state: state,
        email: event.email,
      );
      emit(
        AuthOtpSent(
          mobileNumber: mobileNumber,
          resendAfterSeconds: resendAfterSeconds,
        ),
      );
    } on ApiException catch (error) {
      emit(AuthError(error.message));
    } catch (_) {
      emit(const AuthError('Social registration failed. Please try again.'));
    }
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    final mobileNumber = event.mobileNumber.trim();
    final validationError = _validateMobile(mobileNumber);
    if (validationError != null) {
      emit(AuthError(validationError));
      return;
    }

    emit(const AuthLoading());
    try {
      final resendAfterSeconds = await _repository.sendOtp(
        mobileNumber: mobileNumber,
      );
      emit(
        AuthOtpSent(
          mobileNumber: mobileNumber,
          resendAfterSeconds: resendAfterSeconds,
        ),
      );
    } on ApiException catch (error) {
      emit(AuthError(error.message));
    } catch (_) {
      emit(const AuthError('Could not send OTP. Please try again.'));
    }
  }

  Future<void> _onResendOtp(
    ResendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    final mobileNumber = event.mobileNumber.trim();
    final validationError = _validateMobile(mobileNumber);
    if (validationError != null) {
      emit(AuthError(validationError));
      return;
    }

    emit(const AuthLoading());
    try {
      final resendAfterSeconds = await _repository.resendOtp(
        mobileNumber: mobileNumber,
      );
      emit(
        AuthOtpSent(
          mobileNumber: mobileNumber,
          resendAfterSeconds: resendAfterSeconds,
          isResend: true,
        ),
      );
    } on ApiException catch (error) {
      emit(AuthError(error.message));
    } catch (_) {
      emit(const AuthError('Could not resend OTP. Please try again.'));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    final mobileNumber = event.mobileNumber.trim();
    final otp = event.otp.trim();
    final mobileError = _validateMobile(mobileNumber);
    if (mobileError != null) {
      emit(AuthError(mobileError));
      return;
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      emit(const AuthError('Enter the 6 digit OTP.'));
      return;
    }

    emit(const AuthLoading());
    try {
      final user = await _repository.verifyOtp(
        mobileNumber: mobileNumber,
        otp: otp,
      );
      emit(AuthOtpVerified(user: user));
      emit(AuthAuthenticated(user: user));
    } on ApiException catch (error) {
      emit(AuthError(error.message));
    } catch (_) {
      emit(const AuthError('OTP verification failed. Please try again.'));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }

  void _onUserChanged(UserChangedEvent event, Emitter<AuthState> emit) {
    emit(AuthAuthenticated(user: event.user));
  }

  String? _validateMobile(String mobileNumber) {
    if (!RegExp(r'^[0-9]{10}$').hasMatch(mobileNumber)) {
      return 'Enter a valid 10 digit mobile number.';
    }
    return null;
  }

  String? _validateRegistration({
    required String fullName,
    required String mobileNumber,
    required String school,
    required String city,
    required String state,
    String? email,
  }) {
    if (fullName.isEmpty) return 'Full name is required.';
    final mobileError = _validateMobile(mobileNumber);
    if (mobileError != null) return mobileError;
    if (school.isEmpty) return 'School is required.';
    if (city.isEmpty) return 'City is required.';
    if (state.isEmpty) return 'State is required.';

    final trimmedEmail = email?.trim() ?? '';
    if (trimmedEmail.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmedEmail)) {
      return 'Enter a valid email address.';
    }

    return null;
  }
}
