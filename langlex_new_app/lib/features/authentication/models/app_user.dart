import 'dart:convert';

class AppUser {
  const AppUser({
    required this.id,
    required this.mobileNumber,
    required this.fullName,
    this.email,
    this.school,
    this.city,
    this.state,
    this.pushToken,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String mobileNumber;
  final String fullName;
  final String? email;
  final String? school;
  final String? city;
  final String? state;
  final String? pushToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _asInt(json['id']),
      mobileNumber: json['mobile_number']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: _nullableString(json['email']),
      school: _nullableString(json['school']),
      city: _nullableString(json['city']),
      state: _nullableString(json['state']),
      pushToken: _nullableString(json['push_token']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobile_number': mobileNumber,
      'full_name': fullName,
      'email': email,
      'school': school,
      'city': city,
      'state': state,
      'push_token': pushToken,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String encode() => jsonEncode(toJson());

  static AppUser? decode(String value) {
    if (value.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return AppUser.fromJson(decoded);
      }
      if (decoded is Map) {
        return AppUser.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static DateTime? _parseDate(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}
