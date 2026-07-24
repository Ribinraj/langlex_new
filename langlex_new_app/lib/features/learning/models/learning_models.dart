import 'package:flutter/material.dart';
import 'package:langlex_new_app/core/colors.dart';

enum LearningAccess { free, login, premium }

class LearningSetupOptions {
  const LearningSetupOptions._();

  static const allLevels = 'All levels';
  static const ageGroups = [
    '2-3 years',
    '3-4 years',
    '4-5 years',
    '5-6 years',
    '6+ years',
  ];
  static const academicLevels = [
    'Playgroup',
    'Nursery',
    'LKG',
    'UKG',
    'Class 1',
    'Class 2',
  ];

  static String cleanAgeGroup(String value) {
    return ageGroups.contains(value) ? value : ageGroups[1];
  }

  static String cleanAcademicLevel(String value) {
    final normalized = normalizeLevel(value);
    return academicLevels.contains(normalized) ? normalized : academicLevels[1];
  }

  static String normalizeLevel(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';
    final alias = switch (text.toLowerCase()) {
      'beginner' => 'Nursery',
      'intermediate' => 'LKG',
      'advanced' => 'UKG',
      _ => null,
    };
    if (alias != null) return alias;
    for (final level in academicLevels) {
      if (level.toLowerCase() == text.toLowerCase()) return level;
    }
    return text;
  }

  static bool isAcademicLevel(String value) {
    return academicLevels.contains(normalizeLevel(value));
  }
}

class LearningCatalog {
  const LearningCatalog({
    required this.languages,
    required this.levels,
    required this.courses,
    required this.alphabets,
    required this.stories,
    required this.quizQuestions,
    required this.phonics,
    required this.plans,
    required this.setup,
    required this.dailyGoal,
  });

  final List<String> languages;
  final List<String> levels;
  final List<LearningCourse> courses;
  final List<AlphabetItem> alphabets;
  final List<StoryItem> stories;
  final List<QuizQuestion> quizQuestions;
  final List<PhonicsItem> phonics;
  final List<SubscriptionPlan> plans;
  final LearningSetup setup;
  final DailyGoal dailyGoal;

  int get phonicsCount => phonics.length;

  LearningCatalog copyWith({LearningSetup? setup, DailyGoal? dailyGoal}) {
    return LearningCatalog(
      languages: languages,
      levels: levels,
      courses: courses,
      alphabets: alphabets,
      stories: stories,
      quizQuestions: quizQuestions,
      phonics: phonics,
      plans: plans,
      setup: setup ?? this.setup,
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }

  factory LearningCatalog.fromApi({
    required List<dynamic> languages,
    required List<dynamic> courses,
    required List<dynamic> content,
    required List<dynamic> alphabets,
    required List<dynamic> quizzes,
    required List<dynamic> phonics,
    required List<dynamic> stories,
    required List<dynamic> plans,
    Map<String, dynamic>? setup,
    Map<String, dynamic>? dailyGoal,
  }) {
    final contentRows = content
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    final alphabetItems = alphabets
        .whereType<Map>()
        .map((row) => AlphabetItem.fromJson(Map<String, dynamic>.from(row)))
        .toList();

    final storyItems = stories
        .whereType<Map>()
        .map((row) => StoryItem.fromJson(Map<String, dynamic>.from(row)))
        .toList();

    final quizItems = quizzes
        .whereType<Map>()
        .map((row) => QuizQuestion.fromJson(Map<String, dynamic>.from(row)))
        .toList();

    final phonicsItems = phonics
        .whereType<Map>()
        .map((row) => PhonicsItem.fromJson(Map<String, dynamic>.from(row)))
        .toList();

    final planItems = plans
        .whereType<Map>()
        .map((row) => SubscriptionPlan.fromJson(Map<String, dynamic>.from(row)))
        .toList();

    final courseItems = courses.whereType<Map>().map((row) {
      final courseJson = Map<String, dynamic>.from(row);
      final title = _asString(courseJson['title']);
      final courseContent = contentRows
          .where((item) => _asString(item['course']) == title)
          .toList();
      return LearningCourse.fromCourseJson(
        courseJson,
        courseContent,
        alphabets: alphabetItems,
        phonics: phonicsItems,
      );
    }).toList();

    final languageItems = <String>{
      ..._languagesFromApi(languages),
      for (final item in courseItems) item.language,
      for (final item in alphabetItems) item.language,
      for (final item in storyItems) item.language,
      for (final item in quizItems) item.language,
      for (final item in phonicsItems) item.language,
    }.where((value) => value.trim().isNotEmpty).toList()..sort();

    const levels = LearningSetupOptions.academicLevels;

    return LearningCatalog(
      languages: languageItems.isEmpty ? const ['English'] : languageItems,
      levels: levels,
      courses: courseItems,
      alphabets: alphabetItems,
      stories: storyItems,
      quizQuestions: quizItems,
      phonics: phonicsItems,
      plans: planItems,
      setup: LearningSetup.fromJson(
        setup,
        languages: languageItems.isEmpty ? const ['English'] : languageItems,
        plans: planItems,
      ),
      dailyGoal: DailyGoal.fromJson(dailyGoal),
    );
  }
}

List<String> _languagesFromApi(List<dynamic> rows) {
  return rows
      .map((row) {
        if (row is String) return row;
        if (row is Map) {
          return _asString(row['language']);
        }
        return '';
      })
      .where((value) => value.trim().isNotEmpty)
      .toList();
}

class LearningSetup {
  const LearningSetup({
    required this.childName,
    required this.ageGroup,
    required this.primaryLanguage,
    required this.learningLanguage,
    required this.level,
    required this.interests,
    required this.dailyGoalMinutes,
    required this.planId,
    required this.isConfigured,
  });

  final String childName;
  final String ageGroup;
  final String primaryLanguage;
  final String learningLanguage;
  final String level;
  final List<String> interests;
  final int dailyGoalMinutes;
  final int? planId;
  final bool isConfigured;

  factory LearningSetup.fromJson(
    Map<String, dynamic>? json, {
    required List<String> languages,
    required List<SubscriptionPlan> plans,
  }) {
    final source = json ?? const <String, dynamic>{};
    final defaultLanguage = languages.isNotEmpty ? languages.first : 'English';
    final secondLanguage = languages.length > 1
        ? languages[1]
        : defaultLanguage;
    final defaultAgeGroup = LearningSetupOptions.ageGroups[1];
    final defaultLevel = LearningSetupOptions.academicLevels[1];
    final defaultPlanId = plans.isNotEmpty ? plans.first.id : null;
    final rawInterests = source['interests'];

    return LearningSetup(
      childName: _asString(source['child_name'], fallback: 'LangLex Learner'),
      ageGroup: LearningSetupOptions.cleanAgeGroup(
        _asString(source['age_group'], fallback: defaultAgeGroup),
      ),
      primaryLanguage: _asString(
        source['primary_language'],
        fallback: defaultLanguage,
      ),
      learningLanguage: _asString(
        source['learning_language'],
        fallback: secondLanguage,
      ),
      level: LearningSetupOptions.cleanAcademicLevel(
        _asString(source['level'], fallback: defaultLevel),
      ),
      interests: rawInterests is List
          ? rawInterests
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList()
          : const [],
      dailyGoalMinutes: _asInt(source['daily_goal_minutes'], fallback: 15),
      planId: source['plan_id'] == null
          ? defaultPlanId
          : _asInt(source['plan_id']),
      isConfigured: source['is_configured'] == true,
    );
  }

  LearningSetup copyWith({
    String? childName,
    String? ageGroup,
    String? primaryLanguage,
    String? learningLanguage,
    String? level,
    List<String>? interests,
    int? dailyGoalMinutes,
    int? planId,
    bool? isConfigured,
  }) {
    return LearningSetup(
      childName: childName ?? this.childName,
      ageGroup: ageGroup ?? this.ageGroup,
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
      learningLanguage: learningLanguage ?? this.learningLanguage,
      level: level ?? this.level,
      interests: interests ?? this.interests,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      planId: planId ?? this.planId,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'child_name': childName,
      'age_group': ageGroup,
      'primary_language': primaryLanguage,
      'learning_language': learningLanguage,
      'level': level,
      'interests': interests,
      'daily_goal_minutes': dailyGoalMinutes,
      'plan_id': planId,
    };
  }
}

class DailyGoal {
  const DailyGoal({
    required this.activityDate,
    required this.dailyGoalMinutes,
    required this.targetWords,
    required this.targetQuizzes,
    required this.completedWords,
    required this.completedQuizzes,
    required this.completedMinutes,
    required this.isComplete,
  });

  final String activityDate;
  final int dailyGoalMinutes;
  final int targetWords;
  final int targetQuizzes;
  final int completedWords;
  final int completedQuizzes;
  final int completedMinutes;
  final bool isComplete;

  double get progress {
    if (dailyGoalMinutes <= 0) return 0;
    final value = completedMinutes / dailyGoalMinutes;
    return value.clamp(0, 1).toDouble();
  }

  DailyGoal retarget(int minutes) {
    final nextTargetWords = _targetWords(minutes);
    final nextTargetQuizzes = _targetQuizzes(minutes);

    return DailyGoal(
      activityDate: activityDate,
      dailyGoalMinutes: minutes,
      targetWords: nextTargetWords,
      targetQuizzes: nextTargetQuizzes,
      completedWords: completedWords,
      completedQuizzes: completedQuizzes,
      completedMinutes: completedMinutes.clamp(0, minutes).toInt(),
      isComplete:
          completedMinutes >= minutes ||
          (completedWords >= nextTargetWords &&
              completedQuizzes >= nextTargetQuizzes),
    );
  }

  factory DailyGoal.fromJson(Map<String, dynamic>? json) {
    final source = json ?? const <String, dynamic>{};
    final minutes = _asInt(source['daily_goal_minutes'], fallback: 15);
    return DailyGoal(
      activityDate: _asString(source['activity_date'], fallback: _todayDate()),
      dailyGoalMinutes: minutes,
      targetWords: _asInt(
        source['target_words'],
        fallback: _targetWords(minutes),
      ),
      targetQuizzes: _asInt(
        source['target_quizzes'],
        fallback: _targetQuizzes(minutes),
      ),
      completedWords: _asInt(source['completed_words']),
      completedQuizzes: _asInt(source['completed_quizzes']),
      completedMinutes: _asInt(source['completed_minutes']),
      isComplete: source['is_complete'] == true,
    );
  }
}

class ContentProgress {
  const ContentProgress({
    required this.contentType,
    required this.contentKey,
    required this.status,
    required this.position,
    required this.totalItems,
    required this.score,
    required this.completedItemKeys,
    required this.restartSession,
  });

  final String contentType;
  final String contentKey;
  final String status;
  final int position;
  final int totalItems;
  final int score;
  final Set<String> completedItemKeys;
  final bool restartSession;

  bool get isCompleted => status == 'completed';

  factory ContentProgress.fromJson(Map<String, dynamic>? json) {
    final source = json ?? const <String, dynamic>{};
    final rawKeys = source['completed_item_keys'];
    final metadata = source['metadata'];

    return ContentProgress(
      contentType: _asString(source['content_type']),
      contentKey: _asString(source['content_key']),
      status: _asString(source['status'], fallback: 'not_started'),
      position: _asInt(source['position']),
      totalItems: _asInt(source['total_items']),
      score: _asInt(source['score']),
      completedItemKeys: rawKeys is List
          ? rawKeys.map((item) => item.toString()).toSet()
          : const <String>{},
      restartSession: metadata is Map && metadata['restart_session'] == true,
    );
  }
}

class LearningCourse {
  const LearningCourse({
    required this.id,
    required this.title,
    required this.language,
    required this.levels,
    required this.category,
    required this.description,
    required this.access,
    required this.icon,
    required this.accent,
    required this.words,
    required this.progress,
    this.imagePath,
  });

  final int id;
  final String title;
  final String language;
  final List<String> levels;
  final String category;
  final String description;
  final LearningAccess access;
  final IconData icon;
  final Color accent;
  final List<LearningWord> words;
  final double progress;
  final String? imagePath;

  String get level {
    if (levels.isEmpty || levels.contains(LearningSetupOptions.allLevels)) {
      return LearningSetupOptions.allLevels;
    }
    return levels.join(', ');
  }

  bool supportsLevel(String selectedLevel) {
    return levels.contains(LearningSetupOptions.allLevels) ||
        levels.contains(LearningSetupOptions.normalizeLevel(selectedLevel));
  }

  factory LearningCourse.fromCourseJson(
    Map<String, dynamic> json,
    List<Map<String, dynamic>> contentRows, {
    required List<AlphabetItem> alphabets,
    required List<PhonicsItem> phonics,
  }) {
    final title = _asString(json['title']);
    final category = contentRows.isEmpty
        ? _cleanCourseTitle(title)
        : _asString(
            contentRows.first['category'],
            fallback: _cleanCourseTitle(title),
          );
    final levels = _levelsForCourse(
      courseJson: json,
      contentRows: contentRows,
      title: title,
      category: category,
      alphabets: alphabets,
      phonics: phonics,
    );
    final words = contentRows.map(LearningWord.fromContentJson).toList();
    final access = _asString(json['show_plan']) == '1'
        ? LearningAccess.premium
        : LearningAccess.free;

    return LearningCourse(
      id: _asInt(json['id']),
      title: title,
      language: _asString(json['language'], fallback: 'English'),
      levels: levels,
      category: category,
      description: words.isEmpty
          ? 'New lesson content is coming soon.'
          : '${words.length} words for ${category.toLowerCase()} practice.',
      access: access,
      icon: _iconFor(category, title),
      accent: _accentFor(category, title),
      words: words,
      progress: words.isEmpty ? 0 : 1,
      imagePath: _nullableString(json['image']),
    );
  }
}

List<String> _levelsForCourse({
  required Map<String, dynamic> courseJson,
  required List<Map<String, dynamic>> contentRows,
  required String title,
  required String category,
  required List<AlphabetItem> alphabets,
  required List<PhonicsItem> phonics,
}) {
  final levels = <String>{};

  void addLevel(dynamic value) {
    final normalized = LearningSetupOptions.normalizeLevel(
      value?.toString() ?? '',
    );
    if (LearningSetupOptions.isAcademicLevel(normalized)) {
      levels.add(normalized);
    }
  }

  addLevel(courseJson['level']);
  for (final row in contentRows) {
    addLevel(row['level']);
  }

  final courseKey = _courseMatchKey(title);
  final categoryKey = _courseMatchKey(category);
  for (final item in alphabets) {
    final itemCourseKey = _courseMatchKey(item.courseName);
    final itemCategoryKey = _courseMatchKey(item.category);
    if (itemCourseKey == courseKey ||
        itemCourseKey == categoryKey ||
        itemCategoryKey == categoryKey) {
      addLevel(item.level);
    }
  }

  for (final item in phonics) {
    final itemCourseKey = _courseMatchKey(item.courseName);
    final itemCategoryKey = _courseMatchKey(item.category);
    if (itemCourseKey == courseKey ||
        itemCourseKey == categoryKey ||
        itemCategoryKey == categoryKey) {
      addLevel(item.level);
    }
  }

  final sorted = levels.toList()
    ..sort(
      (a, b) => LearningSetupOptions.academicLevels
          .indexOf(a)
          .compareTo(LearningSetupOptions.academicLevels.indexOf(b)),
    );
  return sorted.isEmpty ? const [LearningSetupOptions.allLevels] : sorted;
}

String _courseMatchKey(String value) {
  final prepared = value.toLowerCase().replaceFirst(RegExp(r'^learn\s+'), '');
  final buffer = StringBuffer();

  for (final rune in prepared.runes) {
    final isAsciiLetter = (rune >= 97 && rune <= 122);
    final isAsciiNumber = (rune >= 48 && rune <= 57);
    final isNonAsciiText =
        rune > 127 && String.fromCharCode(rune).trim().isNotEmpty;

    if (isAsciiLetter || isAsciiNumber || isNonAsciiText) {
      buffer.writeCharCode(rune);
    }
  }

  return buffer.toString();
}

class LearningWord {
  const LearningWord({
    required this.id,
    required this.term,
    required this.meaning,
    required this.audioPath,
    required this.imagePath,
  });

  final int id;
  final String term;
  final String meaning;
  final String audioPath;
  final String imagePath;

  factory LearningWord.fromContentJson(Map<String, dynamic> json) {
    final category = _asString(json['category']);
    final subcategory = _asString(json['subcategory']);

    return LearningWord(
      id: _asInt(json['id']),
      term: _asString(json['content']),
      meaning: subcategory.isEmpty ? category : '$category • $subcategory',
      audioPath: _firstNotEmpty([json['word_audio'], json['content_audio']]),
      imagePath: _asString(json['content_image']),
    );
  }
}

class AlphabetItem {
  const AlphabetItem({
    required this.letter,
    required this.word,
    required this.type,
    required this.audioPath,
    required this.courseName,
    required this.category,
    required this.language,
    required this.level,
  });

  final String letter;
  final String word;
  final String type;
  final String audioPath;
  final String courseName;
  final String category;
  final String language;
  final String level;

  factory AlphabetItem.fromJson(Map<String, dynamic> json) {
    return AlphabetItem(
      letter: _asString(json['letter']),
      word: _asString(json['ill_word']),
      type: _asString(json['letter_type']),
      audioPath: _firstNotEmpty([json['letter_sound'], json['word_audio']]),
      courseName: _asString(json['coursename']),
      category: _asString(json['category']),
      language: _asString(json['language'], fallback: 'English'),
      level: LearningSetupOptions.normalizeLevel(_asString(json['level'])),
    );
  }
}

class StoryItem {
  const StoryItem({
    required this.id,
    required this.title,
    required this.language,
    required this.grade,
    required this.minutes,
    required this.access,
    required this.text,
    required this.imagePath,
    required this.audioPath,
  });

  final int id;
  final String title;
  final String language;
  final String grade;
  final int minutes;
  final LearningAccess access;
  final String text;
  final String imagePath;
  final String audioPath;

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    final text = _asString(json['text']);
    return StoryItem(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      language: _asString(json['language'], fallback: 'English'),
      grade: _asString(json['grade'], fallback: 'Beginner'),
      minutes: _readingMinutes(text),
      access: _asString(json['show_plan']) == '1'
          ? LearningAccess.premium
          : LearningAccess.free,
      text: text,
      imagePath: _asString(json['image']),
      audioPath: _asString(json['audio']),
    )._normalizedGrade();
  }

  StoryItem _normalizedGrade() {
    return StoryItem(
      id: id,
      title: title,
      language: language,
      grade: LearningSetupOptions.normalizeLevel(grade),
      minutes: minutes,
      access: access,
      text: text,
      imagePath: imagePath,
      audioPath: audioPath,
    );
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.topic,
    required this.language,
    required this.feedback,
    required this.wrongFeedback,
    required this.imagePath,
  });

  final int id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String topic;
  final String language;
  final String feedback;
  final String wrongFeedback;
  final String imagePath;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final correctAnswer = _asString(json['ca']);
    final options = <String>[
      correctAnswer,
      _asString(json['o1']),
      _asString(json['o2']),
      _asString(json['o3']),
    ].where((value) => value.trim().isNotEmpty).toSet().toList();

    return QuizQuestion(
      id: _asInt(json['id']),
      question: _asString(json['Question']),
      options: options,
      correctAnswer: correctAnswer,
      topic: _asString(json['topic']),
      language: _asString(json['Language'], fallback: 'English'),
      feedback: _asString(json['RAFeed'], fallback: 'Great job'),
      wrongFeedback: _asString(json['WAFeed'], fallback: 'Try again'),
      imagePath: _asString(json['image']),
    );
  }
}

class PhonicsItem {
  const PhonicsItem({
    required this.id,
    required this.sentence,
    required this.word,
    required this.imagePath,
    required this.sentenceAudioPath,
    required this.wordAudioPath,
    required this.courseName,
    required this.language,
    required this.category,
    required this.subcategory,
    required this.level,
  });

  final int id;
  final String sentence;
  final String word;
  final String imagePath;
  final String sentenceAudioPath;
  final String wordAudioPath;
  final String courseName;
  final String language;
  final String category;
  final String subcategory;
  final String level;

  factory PhonicsItem.fromJson(Map<String, dynamic> json) {
    return PhonicsItem(
      id: _asInt(json['id']),
      sentence: _asString(json['sentence']),
      word: _asString(json['word']),
      imagePath: _asString(json['image']),
      sentenceAudioPath: _asString(json['sentence_sound']),
      wordAudioPath: _asString(json['word_audio']),
      courseName: _asString(json['coursename']),
      language: _asString(json['language'], fallback: 'English'),
      category: _asString(json['category']),
      subcategory: _asString(json['subcategory']),
      level: LearningSetupOptions.normalizeLevel(
        _asString(
          json['level'],
          fallback: LearningSetupOptions.academicLevels[1],
        ),
      ),
    );
  }
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.period,
  });

  final int id;
  final String name;
  final String type;
  final String amount;
  final String period;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      type: _asString(json['type']),
      amount: _asString(json['amount']),
      period: _asString(json['plan_timeperiod']),
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

String _firstNotEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return '';
}

String _cleanCourseTitle(String title) {
  final cleaned = title.replaceFirst(
    RegExp(r'^learn\s+', caseSensitive: false),
    '',
  );
  return cleaned.trim().isEmpty ? title : cleaned;
}

int _readingMinutes(String text) {
  final words = text
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  final estimated = (words.length / 80).ceil();
  return estimated < 1 ? 1 : estimated;
}

int _targetWords(int minutes) {
  return (minutes / 2).ceil().clamp(3, 30).toInt();
}

int _targetQuizzes(int minutes) {
  return (minutes / 10).ceil().clamp(1, 10).toInt();
}

String _todayDate() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

IconData _iconFor(String category, String title) {
  final text = '$category $title'.toLowerCase();
  if (text.contains('animal')) return Icons.pets_rounded;
  if (text.contains('alphabet')) return Icons.abc_rounded;
  if (text.contains('number')) return Icons.looks_one_rounded;
  if (text.contains('color')) return Icons.palette_rounded;
  if (text.contains('fruit')) return Icons.local_dining_rounded;
  if (text.contains('vegetable')) return Icons.eco_rounded;
  return Icons.school_rounded;
}

Color _accentFor(String category, String title) {
  final text = '$category $title'.toLowerCase();
  if (text.contains('animal')) return Appcolors.ksecondarycolor;
  if (text.contains('alphabet')) return Appcolors.kprimarycolor;
  if (text.contains('number')) return Appcolors.klearningCategoryNumber;
  if (text.contains('color')) return Appcolors.kmetricInventory;
  if (text.contains('fruit')) return Appcolors.klearningCategoryFruit;
  if (text.contains('vegetable')) return Appcolors.klearningCategoryVegetable;
  return Appcolors.kprimarycolor;
}
