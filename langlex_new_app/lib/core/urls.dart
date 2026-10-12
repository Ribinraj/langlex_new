class Endpoints {
  static const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const _productionApiBaseUrl = 'https://langlex.crisant.com/api/';

  static String get baseUrl =>
      _baseUrl(_apiBaseUrlOverride, _productionApiBaseUrl);

  static String get mediaBaseUrl {
    final uri = Uri.parse(baseUrl);
    final path = uri.path.replaceFirst(RegExp(r'/api/?$'), '/');
    return uri.replace(path: path, query: null, fragment: null).toString();
  }

  static String _baseUrl(String override, String fallback) {
    final value = override.trim().isEmpty ? fallback : override.trim();
    return value.endsWith('/') ? value : '$value/';
  }

  static const checkUser = 'auth/check-user';
  static const register = 'auth/register';
  static const sendOtp = 'auth/send-otp';
  static const resendOtp = 'auth/resend-otp';
  static const verifyOtp = 'auth/verify-otp';
  static const socialLogin = 'auth/social-login';
  static const socialRegister = 'auth/social-register';
  static const logout = 'auth/logout';
  static const currentUser = 'user/profile';
  static const updateProfile = 'user/profile';
  static const updatePushToken = 'user/push-token';
  static const learningSetup = 'user/learning-setup';
  static const learningProgress = 'user/learning-progress';
  static const contentProgress = 'user/content-progress';
  static const contentProgressItem = 'user/content-progress/item';
  static const contentProgressRestart = 'user/content-progress/restart';

  static const languages = 'languages';
  static const categories = 'categories';
  static const subcategories = 'subcategories';
  static const courses = 'courses';
  static const content = 'content';
  static const alphabets = 'alphabets';
  static const quizzes = 'quizzes';
  static const phonics = 'phonics';
  static const stories = 'stories';
  static const plans = 'plans';

  static const paymentPlans = 'payments/plans';
  static const createPaymentOrder = 'payments/create-order';
  static const verifyPayment = 'payments/verify';
  static const mySubscription = 'subscriptions/me';
  static const notifications = 'notifications';
  static const notificationUnreadCount = 'notifications/unread-count';
  static const markAllNotificationsRead = 'notifications/read-all';

  static String markNotificationRead(int id) => 'notifications/$id/read';

  static String mediaUrl(String path) {
    final value = path.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final normalized = value.startsWith('/') ? value.substring(1) : value;
    return Uri.parse(mediaBaseUrl).resolve(normalized).toString();
  }
}
