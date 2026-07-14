import 'package:langlex_new_app/core/storage_keys.dart';
import 'package:langlex_new_app/features/authentication/models/app_user.dart';
import 'package:langlex_new_app/features/authentication/models/auth_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  const LocalStorage._();

  static Future<void> saveAuthSession(AuthResponse response) async {
    await saveToken(response.token);
    await saveUser(response.user);
    await setLoginStatus(true);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.accessToken, token);
  }

  static Future<void> saveAccessToken(String token) => saveToken(token);

  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.accessToken) ?? '';
  }

  static Future<String> getAccessToken() => getToken();

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.accessToken);
  }

  static Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.userId, user.id.toString());
    await prefs.setString(StorageKeys.userName, user.fullName);
    await prefs.setString(StorageKeys.userEmail, user.email ?? '');
    await prefs.setString(StorageKeys.userPhone, user.mobileNumber);
    await prefs.setString(StorageKeys.userDetails, user.encode());
  }

  static Future<AppUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return AppUser.decode(prefs.getString(StorageKeys.userDetails) ?? '');
  }

  static Future<void> saveFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.fcmToken, token);
  }

  static Future<String> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.fcmToken) ?? '';
  }

  static Future<void> setLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.isLoggedIn, isLoggedIn);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.isLoggedIn) ?? false;
  }

  static Future<bool> hasSession() async {
    final token = await getToken();
    return token.isNotEmpty && await isLoggedIn();
  }

  static Future<void> clearAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.accessToken);
    await prefs.remove(StorageKeys.userId);
    await prefs.remove(StorageKeys.userName);
    await prefs.remove(StorageKeys.userEmail);
    await prefs.remove(StorageKeys.userPhone);
    await prefs.remove(StorageKeys.userDetails);
    await prefs.setBool(StorageKeys.isLoggedIn, false);
  }

  static Future<void> clearAll() => clearAuthSession();
}
