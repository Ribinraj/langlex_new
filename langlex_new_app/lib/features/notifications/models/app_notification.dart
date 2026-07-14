class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      body: _asString(json['body']),
      type: _asString(json['type'], fallback: 'info'),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt:
          DateTime.tryParse(_asString(json['created_at'])) ?? DateTime.now(),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
