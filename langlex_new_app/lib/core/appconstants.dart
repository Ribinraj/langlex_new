class AppConstants {
  const AppConstants._();

  static const appLogo = 'assets/images/logo_new.png';
  static const splashPageArt = 'assets/images/splash_page_art_clean.png';
  static const loginImage = 'assets/images/login_image.png';

  static const loginTitle = 'Welcome back!';
  static const loginSubtitle = 'Enter your mobile number to continue learning.';
  static const mobileNumberLabel = 'Mobile number';
  static const mobileNumberHint = 'Enter mobile number';
  static const loginButtonLabel = 'Continue';
  static const signupPrompt = 'New to LangLex?';
  static const signupAction = 'Create account';

  static const signupTitle = 'Create account';
  static const signupSubtitle = 'Add your details to get started with LangLex.';
  static const usernameLabel = 'Full name';
  static const usernameHint = 'Enter full name';
  static const emailLabel = 'Email';
  static const emailHint = 'Enter email address';
  static const schoolLabel = 'School';
  static const schoolHint = 'Enter school name';
  static const cityLabel = 'City';
  static const cityHint = 'Enter city';
  static const stateLabel = 'State';
  static const stateHint = 'Enter state';
  static const signupButtonLabel = 'Sign up';
  static const loginPrompt = 'Already have an account?';
  static const loginAction = 'Login';

  static const verifyOtpTitle = 'Verify OTP';
  static const verifyOtpSubtitle =
      'Enter the 6 digit code generated for your mobile number.';
  static const otpLabel = 'OTP code';
  static const otpButtonLabel = 'Verify OTP';
  static const resendOtpPrompt = 'Did not receive code?';
  static const resendOtpAction = 'Resend';
}

@Deprecated('Use AppConstants instead.')
class Appconstants {
  static const appLogo = AppConstants.appLogo;
  static const applogo = AppConstants.appLogo;
}
