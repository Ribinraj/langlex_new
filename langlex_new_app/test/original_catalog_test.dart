import 'package:flutter_test/flutter_test.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';

void main() {
  test('lesson pronunciation and item sounds remain separate', () {
    final animal = LearningWord.fromContentJson({
      'content': 'Cat',
      'word_audio': 'cat-name.mp3',
      'content_audio': 'meow.mp3',
    });
    expect(animal.audioPath, 'cat-name.mp3');
    expect(animal.listenAudioPath, 'meow.mp3');

    final nameOnly = LearningWord.fromContentJson({
      'word_audio': 'apple.mp3',
      'content_audio': '   ',
    });
    expect(nameOnly.listenAudioPath, 'apple.mp3');

    final soundOnly = LearningWord.fromContentJson({
      'content_audio': 'roar.mp3',
    });
    expect(soundOnly.audioPath, isEmpty);
    expect(soundOnly.listenAudioPath, 'roar.mp3');
    expect(LearningWord.fromContentJson({}).listenAudioPath, isEmpty);
  });

  test('original translated grades map to the app filters', () {
    expect(LearningSetupOptions.normalizeLevel('शिशुसदन'), 'Nursery');
    expect(LearningSetupOptions.normalizeLevel('ಅವರ'), 'ಅವರ');
    expect(LearningSetupOptions.normalizeLevel('ಶಿಶುವಿಹಾರ'), 'Nursery');
    expect(LearningSetupOptions.normalizeLevel('अवर बालविहार'), 'LKG');
    expect(LearningSetupOptions.normalizeLevel('ಯುಕೆಜಿ'), 'UKG');
    expect(LearningSetupOptions.normalizeLevel('নাৰ্চাৰী'), 'Nursery');
  });

  test('original access labels and passage audio survive catalog parsing', () {
    final story = StoryItem.fromJson({
      'id': 1,
      'title': 'प्यासा कौआ',
      'show_plan': 'Premium',
      'grade': 'शिशुसदन',
      'text': 'First\n\nLast',
      'sections': [
        {'text': 'First', 'audio': 'https://kids.langlex.com/first.mp3'},
        {'text': 'Last', 'audio': 'https://kids.langlex.com/last.mp3'},
      ],
    });
    expect(story.access, LearningAccess.premium);
    expect(story.grade, 'Nursery');
    expect(story.sections.last.audioPath, endsWith('/last.mp3'));
    final course = LearningCourse.fromCourseJson(
      {'title': 'Pet Animals', 'show_plan': 'Login'},
      [],
      alphabets: [],
      phonics: [],
    );
    expect(course.access, LearningAccess.login);
  });

  test(
    'matching course titles do not mix content from different languages',
    () {
      final catalog = LearningCatalog.fromApi(
        languages: ['English', 'Hindi'],
        courses: [
          {'id': 1, 'title': 'Shared', 'language': 'English'},
        ],
        content: [
          {
            'id': 1,
            'course': 'Shared',
            'language': 'English',
            'content': 'Cat',
            'category': 'Nursery',
          },
          {
            'id': 2,
            'course': 'Shared',
            'language': 'Hindi',
            'content': 'बिल्ली',
          },
        ],
        alphabets: [],
        quizzes: [],
        phonics: [],
        stories: [],
        plans: [],
      );
      expect(catalog.courses.single.words.length, 1);
      expect(catalog.courses.single.levels, ['Nursery']);
    },
  );

  test('listening quizzes retain both prompt and target sound', () {
    final quiz = QuizQuestion.fromJson({
      'audio': 'letter.mp3',
      'q_audio': 'question.mp3',
    });
    expect(quiz.audioPath, 'letter.mp3');
    expect(quiz.questionAudioPath, 'question.mp3');
  });

  test(
    'quiz answers vary their position without changing correctness on reload',
    () {
      final positions = <int>{};
      for (var id = 1; id <= 20; id++) {
        final row = {
          'id': id,
          'ca': 'Correct',
          'o1': 'First',
          'o2': 'Second',
          'o3': 'Third',
        };
        final first = QuizQuestion.fromJson(row);
        final reopened = QuizQuestion.fromJson(row);
        expect(first.correctAnswer, 'Correct');
        expect(first.options.toSet(), {'Correct', 'First', 'Second', 'Third'});
        expect(first.options, reopened.options);
        positions.add(first.options.indexOf(first.correctAnswer));
      }
      expect(positions.length, greaterThan(1));
    },
  );
}
