class AppLocalizations {
  const AppLocalizations(this.language);

  final String language;

  bool get _isHindi => language.toLowerCase() == 'hindi';
  bool get _isKannada => language.toLowerCase() == 'kannada';

  String get learn => _text('Learn', 'सीखें', 'ಕಲಿಯಿರಿ');
  String get library => _text('Library', 'लाइब्रेरी', 'ಲೈಬ್ರರಿ');
  String get practice => _text('Practice', 'अभ्यास', 'ಅಭ್ಯಾಸ');
  String get profile => _text('Profile', 'प्रोफाइल', 'ಪ್ರೊಫೈಲ್');
  String get retry => _text('Retry', 'फिर कोशिश करें', 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ');
  String get all => _text('All', 'सभी', 'ಎಲ್ಲಾ');
  String get loading => _text('Loading', 'लोड हो रहा है', 'ಲೋಡ್ ಆಗುತ್ತಿದೆ');
  String get loadingLessons => _text(
    'Loading lessons...',
    'पाठ लोड हो रहे हैं...',
    'ಪಾಠಗಳು ಲೋಡ್ ಆಗುತ್ತಿವೆ...',
  );
  String get loadingPracticeContent => _text(
    'Loading practice content...',
    'अभ्यास सामग्री लोड हो रही है...',
    'ಅಭ್ಯಾಸ ವಿಷಯ ಲೋಡ್ ಆಗುತ್ತಿದೆ...',
  );
  String get loadingLibrary => _text(
    'Loading library...',
    'लाइब्रेरी लोड हो रही है...',
    'ಲೈಬ್ರರಿ ಲೋಡ್ ಆಗುತ್ತಿದೆ...',
  );
  String get couldNotLoadLearningContent => _text(
    'Could not load learning content.',
    'लर्निंग सामग्री लोड नहीं हो सकी।',
    'ಕಲಿಕೆ ವಿಷಯ ಲೋಡ್ ಆಗಲಿಲ್ಲ.',
  );
  String get couldNotSaveLearningSetup => _text(
    'Could not save learning setup.',
    'लर्निंग सेटअप सेव नहीं हो सका।',
    'ಕಲಿಕೆ ಸೆಟಪ್ ಉಳಿಸಲಾಗಲಿಲ್ಲ.',
  );
  String get setupSaved => _text(
    'Learning setup saved',
    'लर्निंग सेटअप सेव हो गया',
    'ಕಲಿಕೆ ಸೆಟಪ್ ಉಳಿಸಲಾಗಿದೆ',
  );
  String get saveSetup => _text('Save setup', 'सेटअप सेव करें', 'ಸೆಟಪ್ ಉಳಿಸಿ');
  String get saving =>
      _text('Saving...', 'सेव हो रहा है...', 'ಉಳಿಸಲಾಗುತ್ತಿದೆ...');
  String get edit => _text('Edit', 'बदलें', 'ಸಂಪಾದಿಸಿ');
  String get editProfile =>
      _text('Edit profile', 'प्रोफाइल बदलें', 'ಪ್ರೊಫೈಲ್ ಸಂಪಾದಿಸಿ');
  String get editProfileSubtitle => _text(
    'Update parent and school details.',
    'अभिभावक और स्कूल की जानकारी अपडेट करें।',
    'ಪೋಷಕರು ಮತ್ತು ಶಾಲೆಯ ವಿವರಗಳನ್ನು ನವೀಕರಿಸಿ.',
  );
  String get saveChanges =>
      _text('Save changes', 'बदलाव सेव करें', 'ಬದಲಾವಣೆಗಳನ್ನು ಉಳಿಸಿ');
  String get profileUpdated => _text(
    'Profile updated',
    'प्रोफाइल अपडेट हो गया',
    'ಪ್ರೊಫೈಲ್ ನವೀಕರಿಸಲಾಗಿದೆ',
  );
  String get couldNotUpdateProfile => _text(
    'Could not update profile.',
    'प्रोफाइल अपडेट नहीं हो सका।',
    'ಪ್ರೊಫೈಲ್ ನವೀಕರಿಸಲಾಗಲಿಲ್ಲ.',
  );
  String get logout => _text('Logout', 'लॉगआउट', 'ಲಾಗ್ ಔಟ್');
  String get free => _text('Free', 'फ्री', 'ಉಚಿತ');
  String get premium => _text('Premium', 'प्रीमियम', 'ಪ್ರೀಮಿಯಂ');
  String get login => _text('Login', 'लॉगिन', 'ಲಾಗಿನ್');
  String get home => _text('Home', 'घर', 'ಮನೆ');
  String get learning => _text('Learning', 'सीखना', 'ಕಲಿಕೆ');
  String get level => _text('Level', 'लेवल', 'ಹಂತ');
  String get goal => _text('Goal', 'लक्ष्य', 'ಗುರಿ');
  String get plan => _text('Plan', 'प्लान', 'ಯೋಜನೆ');
  String get student => _text('Student', 'विद्यार्थी', 'ವಿದ್ಯಾರ್ಥಿ');
  String get langLexLearner =>
      _text('LangLex Learner', 'LangLex विद्यार्थी', 'LangLex ವಿದ್ಯಾರ್ಥಿ');
  String get profileActive =>
      _text('Profile active', 'प्रोफाइल सक्रिय है', 'ಪ್ರೊಫೈಲ್ ಸಕ್ರಿಯವಾಗಿದೆ');
  String get interests => _text('Interests', 'रुचियां', 'ಆಸಕ್ತಿಗಳು');
  String get courses => _text('Courses', 'कोर्स', 'ಕೋರ್ಸ್‌ಗಳು');
  String get stories => _text('Stories', 'कहानियां', 'ಕಥೆಗಳು');
  String get questions => _text('Questions', 'प्रश्न', 'ಪ್ರಶ್ನೆಗಳು');
  String get quizzes => _text('quizzes', 'क्विज़', 'ಪ್ರಶ್ನೋತ್ತರಗಳು');
  String get words => _text('words', 'शब्द', 'ಪದಗಳು');
  String get minutesShort => _text('min', 'मिनट', 'ನಿಮಿಷ');
  String get listen => _text('Listen', 'सुनें', 'ಕೇಳಿ');
  String get audio => _text('Audio', 'ऑडियो', 'ಆಡಿಯೋ');
  String get noAudio => _text('No audio', 'ऑडियो नहीं है', 'ಆಡಿಯೋ ಇಲ್ಲ');
  String get word => _text('Word', 'शब्द', 'ಪದ');
  String get sentence => _text('Sentence', 'वाक्य', 'ವಾಕ್ಯ');
  String get story => _text('Story', 'कहानी', 'ಕಥೆ');
  String get phonics => _text('Phonics', 'ध्वनि अभ्यास', 'ಧ್ವನಿ ಅಭ್ಯಾಸ');
  String get quiz => _text('Quiz', 'क्विज़', 'ಪ್ರಶ್ನೋತ್ತರ');
  String get vocabulary => _text('Vocabulary', 'शब्दावली', 'ಪದಸಂಪತ್ತು');

  String get learnSubtitle => _text(
    'Choose a language, level, and course to begin.',
    'शुरू करने के लिए भाषा, लेवल और कोर्स चुनें।',
    'ಪ್ರಾರಂಭಿಸಲು ಭಾಷೆ, ಹಂತ ಮತ್ತು ಕೋರ್ಸ್ ಆಯ್ಕೆಮಾಡಿ.',
  );
  String get practiceSubtitle => _text(
    'Letters, phonics, stories, and quizzes.',
    'अक्षर, ध्वनि अभ्यास, कहानियां और क्विज़।',
    'ಅಕ್ಷರಗಳು, ಧ್ವನಿ ಅಭ್ಯಾಸ, ಕಥೆಗಳು ಮತ್ತು ಪ್ರಶ್ನೋತ್ತರಗಳು.',
  );
  String get librarySubtitle => _text(
    'Browse courses, stories, alphabets, and quizzes.',
    'कोर्स, कहानियां, अक्षर और क्विज़ देखें।',
    'ಕೋರ್ಸ್‌ಗಳು, ಕಥೆಗಳು, ಅಕ್ಷರಗಳು ಮತ್ತು ಪ್ರಶ್ನೋತ್ತರಗಳನ್ನು ನೋಡಿ.',
  );
  String get profileSubtitle => _text(
    'Account, selected languages, and learning progress.',
    'अकाउंट, चुनी हुई भाषाएं और सीखने की प्रगति।',
    'ಖಾತೆ, ಆಯ್ದ ಭಾಷೆಗಳು ಮತ್ತು ಕಲಿಕೆಯ ಪ್ರಗತಿ.',
  );
  String get setUpLearning =>
      _text('Set up learning', 'लर्निंग सेट करें', 'ಕಲಿಕೆ ಸೆಟಪ್ ಮಾಡಿ');
  String get setUpLearningSubtitle => _text(
    'Choose student level, language, and daily goal',
    'विद्यार्थी का लेवल, भाषा और दैनिक लक्ष्य चुनें',
    'ವಿದ್ಯಾರ್ಥಿಯ ಹಂತ, ಭಾಷೆ ಮತ್ತು ದೈನಂದಿನ ಗುರಿ ಆಯ್ಕೆಮಾಡಿ',
  );
  String get learningFilters =>
      _text('Learning filters', 'लर्निंग फिल्टर', 'ಕಲಿಕೆ ಫಿಲ್ಟರ್‌ಗಳು');
  String recommendedCourses(int count) => _text(
    'Recommended courses ($count)',
    'सुझाए गए कोर्स ($count)',
    'ಶಿಫಾರಸು ಕೋರ್ಸ್‌ಗಳು ($count)',
  );
  String get noLessonsFound => _text(
    'No lessons found for this filter.',
    'इस फिल्टर में कोई पाठ नहीं मिला।',
    'ಈ ಫಿಲ್ಟರ್‌ಗೆ ಪಾಠಗಳು ಸಿಗಲಿಲ್ಲ.',
  );
  String get quickActions =>
      _text('Quick actions', 'त्वरित काम', 'ತ್ವರಿತ ಕ್ರಿಯೆಗಳು');
  String get dailyWords => _text('Daily words', 'आज के शब्द', 'ದಿನದ ಪದಗಳು');
  String get todayGoal => _text("Today's goal", 'आज का लक्ष्य', 'ಇಂದಿನ ಗುರಿ');
  String get goalComplete =>
      _text('Goal complete', 'लक्ष्य पूरा', 'ಗುರಿ ಪೂರ್ಣವಾಗಿದೆ');
  String dailyGoalMinutesLabel(int minutes) => _text(
    '$minutes min daily target',
    '$minutes मिनट दैनिक लक्ष्य',
    '$minutes ನಿಮಿಷ ದಿನದ ಗುರಿ',
  );
  String wordsProgress(int done, int total) =>
      _text('$done/$total words', '$done/$total शब्द', '$done/$total ಪದಗಳು');
  String quizzesProgress(int done, int total) => _text(
    '$done/$total quizzes',
    '$done/$total क्विज़',
    '$done/$total ಪ್ರಶ್ನೋತ್ತರಗಳು',
  );
  String wordsForLevel(int count, String level) => _text(
    '$count words for $level',
    '$level के लिए $count शब्द',
    '$level ಗಾಗಿ $count ಪದಗಳು',
  );
  String get quizChallenge =>
      _text('Quiz challenge', 'क्विज़ चैलेंज', 'ಪ್ರಶ್ನೋತ್ತರ ಸವಾಲು');
  String practiceQuestions(int count) => _text(
    '$count practice questions',
    '$count अभ्यास प्रश्न',
    '$count ಅಭ್ಯಾಸ ಪ್ರಶ್ನೆಗಳು',
  );
  String get learningContent =>
      _text('Learning content', 'लर्निंग सामग्री', 'ಕಲಿಕೆ ವಿಷಯ');
  String helloLearner(String name) =>
      _text('Hello, $name', 'नमस्ते, $name', 'ನಮಸ್ಕಾರ, $name');
  String readyFor(String language, String level) =>
      _text('$language • $level', '$language • $level', '$language • $level');
  String get startFirstLesson =>
      _text('Start lesson', 'पाठ शुरू करें', 'ಪಾಠ ಆರಂಭಿಸಿ');
  String get updateSetup =>
      _text('Update setup', 'सेटअप बदलें', 'ಸೆಟಪ್ ಬದಲಿಸಿ');
  String get quickStart =>
      _text('Quick start', 'जल्दी शुरू करें', 'ತ್ವರಿತ ಆರಂಭ');
  String get findLessons => _text('Find lessons', 'पाठ खोजें', 'ಪಾಠ ಹುಡುಕಿ');
  String get lessons => _text('Lessons', 'पाठ', 'ಪಾಠಗಳು');
  String get wordsTitle => _text('Words', 'शब्द', 'ಪದಗಳು');
  String get quizTitle => _text('Quiz', 'क्विज़', 'ಪ್ರಶ್ನೋತ್ತರ');
  String get notifications => _text('Notifications', 'सूचनाएं', 'ಅಧಿಸೂಚನೆಗಳು');
  String get markAllRead => _text(
    'Mark all read',
    'सब पढ़ा हुआ करें',
    'ಎಲ್ಲವನ್ನೂ ಓದಿದೆ ಎಂದು ಗುರುತಿಸಿ',
  );
  String get noNotifications => _text(
    'No notifications yet.',
    'अभी कोई सूचना नहीं है।',
    'ಇನ್ನೂ ಅಧಿಸೂಚನೆಗಳಿಲ್ಲ.',
  );
  String get unread => _text('Unread', 'नया', 'ಓದದಿರುವುದು');
  String get read => _text('Read', 'पढ़ा हुआ', 'ಓದಿದೆ');
  String get openNotifications =>
      _text('Open notifications', 'सूचनाएं खोलें', 'ಅಧಿಸೂಚನೆಗಳನ್ನು ತೆರೆಯಿರಿ');
  String get justNow => _text('Just now', 'अभी', 'ಈಗಷ್ಟೆ');
  String minutesAgo(int minutes) =>
      _text('$minutes min ago', '$minutes मिनट पहले', '$minutes ನಿಮಿಷ ಹಿಂದೆ');
  String hoursAgo(int hours) =>
      _text('$hours hr ago', '$hours घंटे पहले', '$hours ಗಂಟೆ ಹಿಂದೆ');
  String daysAgo(int days) =>
      _text('$days days ago', '$days दिन पहले', '$days ದಿನಗಳ ಹಿಂದೆ');
  String progressSummary(int courses, int words, int quizzes) => _text(
    '$courses courses • $words words • $quizzes quizzes',
    '$courses कोर्स • $words शब्द • $quizzes क्विज़',
    '$courses ಕೋರ್ಸ್‌ಗಳು • $words ಪದಗಳು • $quizzes ಪ್ರಶ್ನೋತ್ತರಗಳು',
  );

  String get studentProfile =>
      _text('Student profile', 'विद्यार्थी प्रोफाइल', 'ವಿದ್ಯಾರ್ಥಿ ಪ್ರೊಫೈಲ್');
  String get childName => _text('Child name', 'बच्चे का नाम', 'ಮಗುವಿನ ಹೆಸರು');
  String get ageGroup => _text('Age group', 'आयु समूह', 'ವಯೋಮಿತಿ');
  String get languagesAndLevel =>
      _text('Languages and level', 'भाषाएं और लेवल', 'ಭಾಷೆಗಳು ಮತ್ತು ಹಂತ');
  String get homeLanguage => _text('Home language', 'घर की भाषा', 'ಮನೆಯ ಭಾಷೆ');
  String get learningLanguage =>
      _text('Learning language', 'सीखने की भाषा', 'ಕಲಿಕೆಯ ಭಾಷೆ');
  String dailyGoal(int minutes) => _text(
    'Daily goal: $minutes min',
    'दैनिक लक्ष्य: $minutes मिनट',
    'ದಿನದ ಗುರಿ: $minutes ನಿಮಿಷ',
  );
  String get requiredSetupIntro => _text(
    'Set this once so lessons match the student from the first screen.',
    'इसे एक बार सेट करें ताकि पहले स्क्रीन से पाठ विद्यार्थी के अनुसार दिखें।',
    'ಮೊದಲ ಪರದಿಯಿಂದಲೇ ಪಾಠಗಳು ವಿದ್ಯಾರ್ಥಿಗೆ ಹೊಂದಲು ಇದನ್ನು ಒಮ್ಮೆ ಸೆಟ್ ಮಾಡಿ.',
  );

  String get alphabetPractice =>
      _text('Alphabet practice', 'अक्षर अभ्यास', 'ಅಕ್ಷರ ಅಭ್ಯಾಸ');
  String get practiceModes =>
      _text('Practice modes', 'अभ्यास मोड', 'ಅಭ್ಯಾಸ ವಿಧಾನಗಳು');
  String get noAlphabetRows => _text(
    'No alphabet rows found.',
    'कोई अक्षर डेटा नहीं मिला।',
    'ಅಕ್ಷರ ಡೇಟಾ ಸಿಗಲಿಲ್ಲ.',
  );
  String soundCards(int count) => _text(
    '$count sound cards',
    '$count ध्वनि कार्ड',
    '$count ಧ್ವನಿ ಕಾರ್ಡ್‌ಗಳು',
  );
  String quickQuestions(int count) => _text(
    '$count quick questions',
    '$count त्वरित प्रश्न',
    '$count ತ್ವರಿತ ಪ್ರಶ್ನೆಗಳು',
  );
  String get storyReader => _text('Story reader', 'कहानी पढ़ें', 'ಕಥೆ ಓದುಗ');
  String get storyReaderSubtitle => _text(
    'Read and play story audio timeline',
    'कहानी पढ़ें और ऑडियो चलाएं',
    'ಕಥೆ ಓದಿ ಮತ್ತು ಆಡಿಯೋ ಪ್ಲೇ ಮಾಡಿ',
  );

  String get searchHint => _text(
    'Search course, topic, or language',
    'कोर्स, विषय या भाषा खोजें',
    'ಕೋರ್ಸ್, ವಿಷಯ ಅಥವಾ ಭಾಷೆ ಹುಡುಕಿ',
  );
  String coursesTitle(int count) =>
      _text('Courses ($count)', 'कोर्स ($count)', 'ಕೋರ್ಸ್‌ಗಳು ($count)');
  String get noStoriesAvailable => _text(
    'No stories available yet.',
    'अभी कहानियां उपलब्ध नहीं हैं।',
    'ಇನ್ನೂ ಕಥೆಗಳು ಲಭ್ಯವಿಲ್ಲ.',
  );
  String get noMatchingLessons => _text(
    'No matching lessons',
    'मिलते-जुलते पाठ नहीं मिले',
    'ಹೊಂದುವ ಪಾಠಗಳು ಸಿಗಲಿಲ್ಲ',
  );

  String get learningSetup =>
      _text('Learning setup', 'लर्निंग सेटअप', 'ಕಲಿಕೆ ಸೆಟಪ್');
  String get upgradePlan =>
      _text('Upgrade plan', 'प्लान अपग्रेड करें', 'ಯೋಜನೆ ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ');
  String get upgradePlanSubtitle => _text(
    'Open dummy checkout and activate premium',
    'डमी चेकआउट खोलें और प्रीमियम एक्टिव करें',
    'ಡಮ್ಮಿ ಚೆಕ್‌ಔಟ್ ತೆರೆದು ಪ್ರೀಮಿಯಂ ಸಕ್ರಿಯಗೊಳಿಸಿ',
  );
  String get signOutSubtitle => _text(
    'Sign out from this device',
    'इस डिवाइस से साइन आउट करें',
    'ಈ ಸಾಧನದಿಂದ ಸೈನ್ ಔಟ್ ಮಾಡಿ',
  );
  String get accountInformation =>
      _text('Account information', 'अकाउंट जानकारी', 'ಖಾತೆ ಮಾಹಿತಿ');
  String get accountDetails =>
      _text('Account details', 'अकाउंट विवरण', 'ಖಾತೆ ವಿವರಗಳು');
  String get fullName => _text('Full name', 'पूरा नाम', 'ಪೂರ್ಣ ಹೆಸರು');
  String get fullNameRequired =>
      _text('Full name is required', 'पूरा नाम जरूरी है', 'ಪೂರ್ಣ ಹೆಸರು ಅಗತ್ಯ');
  String get invalidEmail =>
      _text('Enter a valid email', 'सही ईमेल डालें', 'ಸರಿಯಾದ ಇಮೇಲ್ ನಮೂದಿಸಿ');
  String get mobileNumber =>
      _text('Mobile number', 'मोबाइल नंबर', 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ');
  String get mobileCannotBeChanged => _text(
    'Mobile number is used for login and cannot be changed here.',
    'मोबाइल नंबर लॉगिन के लिए है और यहां बदला नहीं जा सकता।',
    'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ಲಾಗಿನ್‌ಗಾಗಿ ಬಳಸಲಾಗುತ್ತದೆ ಮತ್ತು ಇಲ್ಲಿ ಬದಲಾಯಿಸಲು ಸಾಧ್ಯವಿಲ್ಲ.',
  );
  String get email => _text('Email', 'ईमेल', 'ಇಮೇಲ್');
  String get school => _text('School', 'स्कूल', 'ಶಾಲೆ');
  String get city => _text('City', 'शहर', 'ನಗರ');
  String get state => _text('State', 'राज्य', 'ರಾಜ್ಯ');
  String courseQuizReady(int courses, int quizzes) => _text(
    '$courses courses and $quizzes quiz questions ready',
    '$courses कोर्स और $quizzes क्विज़ प्रश्न तैयार',
    '$courses ಕೋರ್ಸ್‌ಗಳು ಮತ್ತು $quizzes ಪ್ರಶ್ನೆಗಳು ಸಿದ್ಧ',
  );

  String lessonWord(int index, int total) => _text(
    'Lesson word $index of $total',
    'पाठ शब्द $index / $total',
    'ಪಾಠದ ಪದ $index / $total',
  );
  String get lessonWords => _text('Lesson words', 'पाठ शब्द', 'ಪಾಠದ ಪದಗಳು');
  String get emptyLesson => _text(
    'Lesson content is coming soon.',
    'पाठ सामग्री जल्द आएगी।',
    'ಪಾಠದ ವಿಷಯ ಶೀಘ್ರದಲ್ಲೇ ಬರುತ್ತದೆ.',
  );
  String get practiceHint => _text(
    'Look at the picture, tap listen, then say the word out loud.',
    'चित्र देखें, सुनें पर टैप करें, फिर शब्द जोर से बोलें।',
    'ಚಿತ್ರ ನೋಡಿ, ಕೇಳಿ ಟ್ಯಾಪ್ ಮಾಡಿ, ನಂತರ ಪದವನ್ನು ಜೋರಾಗಿ ಹೇಳಿ.',
  );
  String get previousWord => _text('Previous word', 'पिछला शब्द', 'ಹಿಂದಿನ ಪದ');
  String get nextWord => _text('Next word', 'अगला शब्द', 'ಮುಂದಿನ ಪದ');
  String playWord(String word) =>
      _text('Play $word', '$word चलाएं', '$word ಪ್ಲೇ ಮಾಡಿ');

  String get quizPractice =>
      _text('Quiz practice', 'क्विज़ अभ्यास', 'ಪ್ರಶ್ನೋತ್ತರ ಅಭ್ಯಾಸ');
  String get quizComplete =>
      _text('Quiz complete', 'क्विज़ पूरा हुआ', 'ಪ್ರಶ್ನೋತ್ತರ ಪೂರ್ಣವಾಗಿದೆ');
  String questionProgress(int current, int total) => _text(
    'Question $current of $total',
    'प्रश्न $current / $total',
    'ಪ್ರಶ್ನೆ $current / $total',
  );
  String get greatJob => _text('Great job!', 'बहुत अच्छा!', 'ಚೆನ್ನಾಗಿದೆ!');
  String quizScore(int correct, int total) => _text(
    '$correct of $total correct',
    '$total में से $correct सही',
    '$total ರಲ್ಲಿ $correct ಸರಿಯಾಗಿದೆ',
  );
  String get practiceAgain =>
      _text('Practice again', 'फिर अभ्यास करें', 'ಮತ್ತೆ ಅಭ್ಯಾಸ ಮಾಡಿ');
  String get restartPractice =>
      _text('Restart', 'फिर शुरू करें', 'ಮತ್ತೆ ಆರಂಭಿಸಿ');
  String get resumePractice =>
      _text('Resuming...', 'फिर से शुरू हो रहा है...', 'ಮುಂದುವರಿಯುತ್ತಿದೆ...');
  String get continueLearning => _text('Continue', 'जारी रखें', 'ಮುಂದುವರಿಸಿ');
  String get doneReading =>
      _text('Done reading', 'पढ़ना पूरा', 'ಓದುವುದು ಮುಗಿದಿದೆ');
  String get backHome => _text('Back home', 'होम पर जाएं', 'ಮನೆಗೆ ಹಿಂತಿರುಗಿ');
  String get noQuizQuestions => _text(
    'No quiz questions available yet.',
    'अभी क्विज़ प्रश्न उपलब्ध नहीं हैं।',
    'ಇನ್ನೂ ಪ್ರಶ್ನೆಗಳು ಲಭ್ಯವಿಲ್ಲ.',
  );
  String get nextQuestion =>
      _text('Next question', 'अगला प्रश्न', 'ಮುಂದಿನ ಪ್ರಶ್ನೆ');
  String get soundCard => _text('Sound card', 'ध्वनि कार्ड', 'ಧ್ವನಿ ಕಾರ್ಡ್');
  String soundCardProgress(int index, int total) => _text(
    'Sound card $index of $total',
    'ध्वनि कार्ड $index / $total',
    'ಧ್ವನಿ ಕಾರ್ಡ್ $index / $total',
  );
  String get previousSound =>
      _text('Previous sound', 'पिछली ध्वनि', 'ಹಿಂದಿನ ಧ್ವನಿ');
  String get nextSound => _text('Next sound', 'अगली ध्वनि', 'ಮುಂದಿನ ಧ್ವನಿ');
  String get playSentence =>
      _text('Play sentence', 'वाक्य चलाएं', 'ವಾಕ್ಯ ಪ್ಲೇ ಮಾಡಿ');
  String get noPhonics => _text(
    'No phonics activities available yet.',
    'अभी ध्वनि अभ्यास उपलब्ध नहीं है।',
    'ಇನ್ನೂ ಧ್ವನಿ ಅಭ್ಯಾಸಗಳು ಲಭ್ಯವಿಲ್ಲ.',
  );
  String get playStory => _text('Play story', 'कहानी चलाएं', 'ಕಥೆ ಪ್ಲೇ ಮಾಡಿ');

  String get upgradePlanPage =>
      _text('Upgrade plan', 'प्लान अपग्रेड करें', 'ಯೋಜನೆ ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ');
  String get chooseLearningPlan => _text(
    'Choose a learning plan',
    'लर्निंग प्लान चुनें',
    'ಕಲಿಕೆ ಯೋಜನೆ ಆಯ್ಕೆಮಾಡಿ',
  );
  String get dummyCheckoutMessage => _text(
    'This is a dummy checkout. Replace the provider calls later with Razorpay, Stripe, or your payment gateway.',
    'यह डमी चेकआउट है। बाद में Razorpay, Stripe या अपने पेमेंट गेटवे से बदलें।',
    'ಇದು ಡಮ್ಮಿ ಚೆಕ್‌ಔಟ್. ನಂತರ Razorpay, Stripe ಅಥವಾ ನಿಮ್ಮ ಪೇಮೆಂಟ್ ಗೇಟ್‌ವೇ ಬಳಸಿ.',
  );
  String get noPaidPlans => _text(
    'No paid plans found.',
    'कोई पेड प्लान नहीं मिला।',
    'ಪೇಡ್ ಯೋಜನೆಗಳು ಸಿಗಲಿಲ್ಲ.',
  );
  String get processing => _text(
    'Processing...',
    'प्रोसेस हो रहा है...',
    'ಪ್ರಕ್ರಿಯೆ ನಡೆಯುತ್ತಿದೆ...',
  );
  String get payWithDummy =>
      _text('Pay with dummy', 'डमी से पे करें', 'ಡಮ್ಮಿಯಿಂದ ಪಾವತಿಸಿ');
  String get dummyPaymentComplete => _text(
    'Dummy payment complete. Premium unlocked.',
    'डमी पेमेंट पूरा। प्रीमियम अनलॉक हुआ।',
    'ಡಮ್ಮಿ ಪಾವತಿ ಪೂರ್ಣ. ಪ್ರೀಮಿಯಂ ಅನ್‌ಲಾಕ್ ಆಯಿತು.',
  );
  String get subscriptionActivated => _text(
    'Subscription activated successfully.',
    'सब्सक्रिप्शन सफलतापूर्वक एक्टिव हुआ।',
    'ಚಂದಾದಾರಿಕೆ ಯಶಸ್ವಿಯಾಗಿ ಸಕ್ರಿಯಗೊಂಡಿದೆ.',
  );
  String periodAmount(String period, String amount) => _text(
    '$period • INR $amount',
    '$period • INR $amount',
    '$period • INR $amount',
  );

  String get contentPending =>
      _text('Content pending', 'सामग्री बाकी है', 'ವಿಷಯ ಬಾಕಿ ಇದೆ');
  String wordsAvailable(int count) => _text(
    '$count words available',
    '$count शब्द उपलब्ध',
    '$count ಪದಗಳು ಲಭ್ಯ',
  );
  String coursePracticeDescription(int count, String category) => _text(
    '$count words for ${category.toLowerCase()} practice.',
    '$category अभ्यास के लिए $count शब्द।',
    '$category ಅಭ್ಯಾಸಕ್ಕೆ $count ಪದಗಳು.',
  );

  String _text(String english, String hindi, String kannada) {
    if (_isHindi) return hindi;
    if (_isKannada) return kannada;
    return english;
  }
}
