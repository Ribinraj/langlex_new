class TopicProgress {
  TopicProgress.fromJson(Map<String, dynamic> json)
    : type = '${json['content_type']}',
      key = '${json['content_key']}',
      title = '${json['title'] ?? ''}',
      language = '${json['language'] ?? ''}',
      completed = (json['completed_items'] as num?)?.toInt() ?? 0,
      total = (json['total_items'] as num?)?.toInt() ?? 0,
      correct = (json['correct_items'] as num?)?.toInt() ?? 0,
      accessible = json['accessible'] == true,
      premium = json['premium'] == true,
      status = '${json['status'] ?? 'not_started'}';
  final String type, key, title, language, status;
  final int completed, total, correct;
  final bool accessible, premium;
  double get fraction => total == 0 ? 0 : (completed / total).clamp(0, 1);
  int get percent => (fraction * 100).floor();
}

class LearningProgressOverview {
  LearningProgressOverview.fromJson(Map<String, dynamic> json)
    : language = '${json['language'] ?? ''}',
      level = '${json['level'] ?? ''}',
      planName = '${json['plan_name'] ?? 'Free'}',
      premium = json['has_premium'] == true,
      completed = (json['completed_items'] as num?)?.toInt() ?? 0,
      total = (json['total_items'] as num?)?.toInt() ?? 0,
      completedTopics = (json['completed_topics'] as num?)?.toInt() ?? 0,
      totalTopics = (json['total_topics'] as num?)?.toInt() ?? 0,
      lockedTopics = (json['locked_topics'] as num?)?.toInt() ?? 0,
      savedLocked = (json['saved_locked_items'] as num?)?.toInt() ?? 0,
      languages = (json['selected_languages'] as List? ?? [])
          .map((e) => '$e')
          .toList(),
      topics = (json['topics'] as List? ?? [])
          .map(
            (e) => TopicProgress.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
  final String language, level, planName;
  final bool premium;
  final int completed,
      total,
      completedTopics,
      totalTopics,
      lockedTopics,
      savedLocked;
  final List<String> languages;
  final List<TopicProgress> topics;
  double get fraction => total == 0 ? 0 : (completed / total).clamp(0, 1);
  int get percent => (fraction * 100).floor();
  TopicProgress? topic(String type, String key) {
    for (final topic in topics) {
      if (topic.type == type && topic.key == key) return topic;
    }
    return null;
  }
}
