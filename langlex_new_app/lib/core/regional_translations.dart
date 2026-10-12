// Interface translations; API language names remain stable identifiers.
const regionalTranslations = <String, List<String>>{
  "Let’s explore!": ["चलू सिखी!", "আহা শিকোঁ!"],
  "Knowledge": ["ज्ञान", "জ্ঞান"],
  "Alphabets": ["अक्षर", "বৰ্ণমালা"],
  "Letters & sounds": ["अक्षर आ ध्वनि", "আখৰ আৰু ধ্বনি"],
  "Search letters or words": ["अक्षर वा शब्द खोजू", "আখৰ বা শব্দ বিচাৰক"],
  "{0} letters": ["{0} अक्षर", "{0}টা আখৰ"],
  "{0} letter": ["{0} अक्षर", "{0}টা আখৰ"],
  "{0} example": ["{0} उदाहरण", "{0}টা উদাহৰণ"],
  "{0} examples": ["{0} उदाहरण", "{0}টা উদাহৰণ"],
  "Sounds": ["ध्वनि", "ধ্বনি"],
  "Start": ["शुरू करू", "আৰম্ভ কৰক"],
  "{0} sounds": ["{0} ध्वनि", "{0}টা ধ্বনি"],
  "Quizzes": ["प्रश्नोत्तरी", "কুইজ"],
  "Read and listen": ["पढ़ू आ सुनू", "পঢ়ক আৰু শুনক"],
  "Letters, animals and more": [
    "अक्षर, जानवर आ बहुत किछु",
    "আখৰ, জীৱ-জন্তু আৰু বহুতো",
  ],
  "Play and discover": ["खेलू आ जानू", "খেলক আৰু আৱিষ্কাৰ কৰক"],
  "Choose a story to read and hear.": [
    "पढ़बा आ सुनबा लेल कथा चुनू।",
    "পঢ়িবলৈ আৰু শুনিবলৈ এটা সাধু বাছক।",
  ],
  "What shall we discover today?": ["आइ की सीखब?", "আজি আমি কি শিকিম?"],
  "Explore topics": ["विषय देखू", "বিষয়বোৰ চাওক"],
  "Meet the letters and their sounds": [
    "अक्षर आ ओकर ध्वनि जानू",
    "আখৰ আৰু সিহঁতৰ ধ্বনি চিনক",
  ],
  "Listen and say it aloud": ["सुनू आ जोर सँ बाजू", "শুনক আৰু ডাঙৰকৈ কওক"],
  "Search stories": ["कथा खोजू", "সাধু বিচাৰক"],
  "Search topics": ["विषय खोजू", "বিষয় বিচাৰক"],
  "Search": ["खोजू", "বিচাৰক"],
  "Search learning content": ["सीखबाक सामग्री खोजू", "শিকাৰ বিষয়বস্তু বিচাৰক"],
  "Learn": ["सिखू", "শিকক"],
  "Library": ["पुस्तकालय", "পুথিভঁৰাল"],
  "Practice": ["अभ्यास", "অনুশীলন"],
  "Profile": ["प्रोफाइल", "প্ৰফাইল"],
  "Retry": ["फेर प्रयास करू", "পুনৰ চেষ্টা কৰক"],
  "All": ["सभ", "সকলো"],
  "Loading": ["लोड भऽ रहल अछि", "ল’ড হৈ আছে"],
  "Loading lessons...": ["पाठ लोड भऽ रहल अछि...", "পাঠ ল’ড হৈ আছে..."],
  "Loading practice content...": [
    "अभ्यास सामग्री लोड भऽ रहल अछि...",
    "অনুশীলনৰ বিষয়বস্তু ল’ড হৈ আছে...",
  ],
  "Loading library...": [
    "पुस्तकालय लोड भऽ रहल अछि...",
    "পুথিভঁৰাল ল’ড হৈ আছে...",
  ],
  "Could not load learning content.": [
    "सीखबाक सामग्री लोड नहि भेल।",
    "শিকাৰ বিষয়বস্তু ল’ড কৰিব পৰা নগ’ল।",
  ],
  "Could not save learning setup.": [
    "सीखबाक सेटअप सहेजल नहि गेल।",
    "শিকাৰ ছেটআপ সংৰক্ষণ কৰিব পৰা নগ’ল।",
  ],
  "Learning setup saved": [
    "सीखबाक सेटअप सहेजल गेल",
    "শিকাৰ ছেটআপ সংৰক্ষিত হ’ল",
  ],
  "Save setup": ["सेटअप सहेजू", "ছেটআপ সংৰক্ষণ কৰক"],
  "Saving...": ["सहेजल जा रहल अछि...", "সংৰক্ষণ হৈ আছে..."],
  "Edit": ["बदलू", "সম্পাদনা কৰক"],
  "Edit profile": ["प्रोफाइल बदलू", "প্ৰফাইল সম্পাদনা কৰক"],
  "Update parent and school details.": [
    "अभिभावक आ विद्यालयक विवरण बदलू।",
    "অভিভাৱক আৰু বিদ্যালয়ৰ তথ্য সলনি কৰক।",
  ],
  "Save changes": ["बदलाव सहेजू", "সলনি সংৰক্ষণ কৰক"],
  "Profile updated": ["प्रोफाइल बदलल गेल", "প্ৰফাইল সলনি হ’ল"],
  "Could not update profile.": [
    "प्रोफाइल बदलल नहि गेल।",
    "প্ৰফাইল সলনি কৰিব পৰা নগ’ল।",
  ],
  "Logout": ["लॉग आउट", "লগ আউট"],
  "Free": ["निःशुल्क", "বিনামূলীয়া"],
  "Premium": ["प्रीमियम", "প্ৰিমিয়াম"],
  "Login": ["लॉग इन", "লগ ইন"],
  "Home": ["मुखपृष्ठ", "মুখ্যপৃষ্ঠা"],
  "Learning": ["सीखब", "শিক্ষণ"],
  "Level": ["स्तर", "স্তৰ"],
  "Plan": ["योजना", "পৰিকল্পনা"],
  "Student": ["विद्यार्थी", "শিক্ষাৰ্থী"],
  "LangLex Learner": ["LangLex विद्यार्थी", "LangLex শিক্ষাৰ্থী"],
  "Profile active": ["प्रोफाइल सक्रिय अछि", "প্ৰফাইল সক্ৰিয়"],
  "Interests": ["रुचि", "আগ্ৰহ"],
  "Courses": ["पाठ्यक्रम", "পাঠ্যক্ৰম"],
  "Stories": ["कथा", "সাধু"],
  "Questions": ["प्रश्न", "প্ৰশ্ন"],
  "quizzes": ["प्रश्नोत्तरी", "কুইজ"],
  "words": ["शब्द", "শব্দ"],
  "min": ["मिनट", "মিনিট"],
  "Listen": ["सुनू", "শুনক"],
  "Audio": ["ऑडियो", "অডিঅ’"],
  "No audio": ["ऑडियो नहि अछि", "অডিঅ’ নাই"],
  "Word": ["शब्द", "শব্দ"],
  "Sentence": ["वाक्य", "বাক্য"],
  "Story": ["कथा", "সাধু"],
  "Phonics": ["ध्वनि अभ्यास", "ধ্বনি অনুশীলন"],
  "Quiz": ["प्रश्नोत्तरी", "কুইজ"],
  "Vocabulary": ["शब्दावली", "শব্দভাণ্ডাৰ"],
  "Choose a language, level, and course to begin.": [
    "शुरू करबा लेल भाषा, स्तर आ पाठ्यक्रम चुनू।",
    "আৰম্ভ কৰিবলৈ ভাষা, স্তৰ আৰু পাঠ্যক্ৰম বাছক।",
  ],
  "Letters, phonics, stories, and quizzes.": [
    "अक्षर, ध्वनि, कथा आ प्रश्नोत्तरी।",
    "আখৰ, ধ্বনি, সাধু আৰু কুইজ।",
  ],
  "Browse courses, stories, alphabets, and quizzes.": [
    "पाठ्यक्रम, कथा, अक्षर आ प्रश्नोत्तरी देखू।",
    "পাঠ্যক্ৰম, সাধু, বৰ্ণমালা আৰু কুইজ চাওক।",
  ],
  "Account, selected languages, and learning progress.": [
    "खाता, चुनल भाषा आ सीखबाक प्रगति।",
    "একাউণ্ট, বাছনি কৰা ভাষা আৰু শিকাৰ অগ্ৰগতি।",
  ],
  "Set up learning": ["सीखबाक व्यवस्था करू", "শিকাৰ ছেটআপ কৰক"],
  "Choose student level and language": [
    "विद्यार्थीक स्तर आ भाषा चुनू",
    "শিক্ষাৰ্থীৰ স্তৰ আৰু ভাষা বাছক",
  ],
  "Learning filters": ["सीखबाक फिल्टर", "শিকাৰ ফিল্টাৰ"],
  "Recommended courses ({0})": [
    "सुझाओल पाठ्यक्रम ({0})",
    "পৰামৰ্শ দিয়া পাঠ্যক্ৰম ({0})",
  ],
  "No lessons found for this filter.": [
    "एहि फिल्टर लेल पाठ नहि भेटल।",
    "এই ফিল্টাৰত কোনো পাঠ পোৱা নগ’ল।",
  ],
  "Quick actions": ["त्वरित काम", "দ্ৰুত কাৰ্য"],
  "Daily words": ["दैनिक शब्द", "দৈনিক শব্দ"],
  "{0} words for {1}": ["{1} लेल {0} शब्द", "{1}ৰ বাবে {0} শব্দ"],
  "Quiz challenge": ["प्रश्नोत्तरी चुनौती", "কুইজ প্ৰত্যাহ্বান"],
  "{0} practice questions": ["{0} अभ्यास प्रश्न", "{0}টা অনুশীলনৰ প্ৰশ্ন"],
  "Learning content": ["सीखबाक सामग्री", "শিকাৰ বিষয়বস্তু"],
  "Hello, {0}": ["नमस्कार, {0}", "নমস্কাৰ, {0}"],
  "{0} • {1}": ["{0} • {1}", "{0} • {1}"],
  "Start lesson": ["पाठ शुरू करू", "পাঠ আৰম্ভ কৰক"],
  "Update setup": ["सेटअप बदलू", "ছেটআপ সলনি কৰক"],
  "Quick start": ["जल्दी शुरू करू", "দ্ৰুত আৰম্ভণি"],
  "Find lessons": ["पाठ खोजू", "পাঠ বিচাৰক"],
  "Lessons": ["पाठ", "পাঠ"],
  "Words": ["शब्द", "শব্দ"],
  "Notifications": ["सूचना", "জাননী"],
  "Mark all read": ["सभ पढ़ल चिन्हित करू", "সকলো পঢ়া বুলি চিহ্নিত কৰক"],
  "No notifications yet.": [
    "एखन धरि कोनो सूचना नहि।",
    "এতিয়ালৈকে কোনো জাননী নাই।",
  ],
  "Unread": ["अनपढ़ल", "নপঢ়া"],
  "Read": ["पढ़ल", "পঢ়া"],
  "Open notifications": ["सूचना खोलू", "জাননী খোলক"],
  "Just now": ["अखने", "এইমাত্ৰ"],
  "{0} min ago": ["{0} मिनट पहिने", "{0} মিনিট আগতে"],
  "{0} hr ago": ["{0} घंटा पहिने", "{0} ঘণ্টা আগতে"],
  "{0} days ago": ["{0} दिन पहिने", "{0} দিন আগতে"],
  "{0} courses • {1} words • {2} quizzes": [
    "{0} पाठ्यक्रम • {1} शब्द • {2} प्रश्नोत्तरी",
    "{0}টা পাঠ্যক্ৰম • {1}টা শব্দ • {2}টা কুইজ",
  ],
  "Student profile": ["विद्यार्थीक प्रोफाइल", "শিক্ষাৰ্থীৰ প্ৰফাইল"],
  "Child name": ["बच्चाक नाम", "শিশুৰ নাম"],
  "Languages and level": ["भाषा आ स्तर", "ভাষা আৰু স্তৰ"],
  "Home language": ["भाषा", "ভাষা"],
  "Learning language": ["भाषा", "ভাষা"],
  "Set this once so lessons match the student from the first screen.": [
    "एक बेर सेट करू जाहि सँ पाठ विद्यार्थीक अनुरूप हो।",
    "শিক্ষাৰ্থীৰ লগত পাঠ মিলাবলৈ এবাৰ ছেট কৰক।",
  ],
  "Alphabet practice": ["अक्षर अभ्यास", "বৰ্ণমালাৰ অনুশীলন"],
  "Practice modes": ["अभ्यासक तरीका", "অনুশীলনৰ ধৰণ"],
  "No alphabet rows found.": ["अक्षर नहि भेटल।", "কোনো আখৰ পোৱা নগ’ল।"],
  "{0} sound cards": ["{0} ध्वनि कार्ड", "{0}টা ধ্বনি কাৰ্ড"],
  "{0} quick questions": ["{0} छोट प्रश्न", "{0}টা চুটি প্ৰশ্ন"],
  "Story reader": ["कथा पाठक", "সাধু পঢ়ক"],
  "Read and play story audio timeline": [
    "कथा पढ़ू आ ऑडियो सुनू",
    "সাধু পঢ়ক আৰু অডিঅ’ শুনক",
  ],
  "Search course, topic, or language": [
    "पाठ्यक्रम, विषय वा भाषा खोजू",
    "পাঠ্যক্ৰম, বিষয় বা ভাষা বিচাৰক",
  ],
  "Courses ({0})": ["पाठ्यक्रम ({0})", "পাঠ্যক্ৰম ({0})"],
  "No stories available yet.": [
    "एखन धरि कथा उपलब्ध नहि अछि।",
    "এতিয়ালৈকে কোনো সাধু উপলব্ধ নাই।",
  ],
  "No matching lessons": ["मेल खाइत पाठ नहि", "মিল থকা পাঠ নাই"],
  "Learning setup": ["सीखबाक सेटअप", "শিকাৰ ছেটআপ"],
  "Upgrade plan": ["योजना बढ़ाउ", "পৰিকল্পনা উন্নীত কৰক"],
  "Open dummy checkout and activate premium": [
    "डमी भुगतान खोलू आ प्रीमियम सक्रिय करू",
    "ডামি চেকআউট খোলক আৰু প্ৰিমিয়াম সক্ৰিয় কৰক",
  ],
  "Sign out from this device": [
    "एहि डिवाइस सँ साइन आउट करू",
    "এই ডিভাইচৰ পৰা ছাইন আউট কৰক",
  ],
  "Account information": ["खाताक जानकारी", "একাউণ্টৰ তথ্য"],
  "Account details": ["खाताक विवरण", "একাউণ্টৰ বিৱৰণ"],
  "Full name": ["पूरा नाम", "সম্পূৰ্ণ নাম"],
  "Full name is required": ["पूरा नाम आवश्यक अछि", "সম্পূৰ্ণ নাম প্ৰয়োজন"],
  "Enter a valid email": ["सही ईमेल भरू", "সঠিক ইমেইল দিয়ক"],
  "Mobile number": ["मोबाइल नंबर", "ম’বাইল নম্বৰ"],
  "Mobile number is used for login and cannot be changed here.": [
    "मोबाइल नंबर लॉगिन लेल अछि आ एतय बदलल नहि जा सकैत अछि।",
    "ম’বাইল নম্বৰ লগ ইন কৰিবলৈ ব্যৱহাৰ হয় আৰু ইয়াত সলনি কৰিব নোৱাৰি।",
  ],
  "Email": ["ईमेल", "ইমেইল"],
  "School": ["विद्यालय", "বিদ্যালয়"],
  "City": ["शहर", "চহৰ"],
  "State": ["राज्य", "ৰাজ্য"],
  "{0} courses and {1} quiz questions ready": [
    "{0} पाठ्यक्रम आ {1} प्रश्न तैयार अछि",
    "{0}টা পাঠ্যক্ৰম আৰু {1}টা কুইজ প্ৰশ্ন সাজু",
  ],
  "Lesson word {0} of {1}": [
    "पाठक शब्द {0}, कुल {1}",
    "পাঠৰ শব্দ {0}, মুঠ {1}",
  ],
  "Lesson words": ["पाठक शब्द", "পাঠৰ শব্দ"],
  "Lesson content is coming soon.": [
    "पाठक सामग्री जल्दि आबि रहल अछि।",
    "পাঠৰ বিষয়বস্তু সোনকালে আহিব।",
  ],
  "Look at the picture, tap listen, then say the word out loud.": [
    "चित्र देखू, सुनू पर टैप करू, फेर शब्द जोर सँ बाजू।",
    "ছবিখন চাওক, শুনকত টেপ কৰক, তাৰ পিছত শব্দটো ডাঙৰকৈ কওক।",
  ],
  "Previous word": ["पछिला शब्द", "আগৰ শব্দ"],
  "Next word": ["अगिला शब्द", "পৰৱৰ্তী শব্দ"],
  "Play {0}": ["{0} सुनू", "{0} শুনক"],
  "Quiz practice": ["प्रश्नोत्तरी अभ्यास", "কুইজ অনুশীলন"],
  "Quiz complete": ["प्रश्नोत्तरी पूरा भेल", "কুইজ সম্পূৰ্ণ"],
  "Question {0} of {1}": ["प्रश्न {0}, कुल {1}", "প্ৰশ্ন {0}, মুঠ {1}"],
  "Great job!": ["बहुत नीक!", "বৰ ভাল!"],
  "{0} of {1} correct": ["{1} मे सँ {0} सही", "{1}টাৰ ভিতৰত {0}টা শুদ্ধ"],
  "Practice again": ["फेर अभ्यास करू", "পুনৰ অনুশীলন কৰক"],
  "Restart": ["फेर शुरू करू", "পুনৰ আৰম্ভ কৰক"],
  "Resuming...": ["फेर चालू भऽ रहल अछि...", "পুনৰ আৰম্ভ হৈছে..."],
  "Continue": ["आगाँ बढ़ू", "আগবাঢ়ক"],
  "Done reading": ["पढ़ि लेलहुँ", "পঢ়া হ’ল"],
  "Back home": ["मुखपृष्ठ पर जाउ", "মুখ্যপৃষ্ঠালৈ যাওক"],
  "No quiz questions available yet.": [
    "एखन धरि प्रश्न उपलब्ध नहि अछि।",
    "এতিয়ালৈকে কুইজৰ প্ৰশ্ন উপলব্ধ নাই।",
  ],
  "Next question": ["अगिला प्रश्न", "পৰৱৰ্তী প্ৰশ্ন"],
  "Sound card": ["ध्वनि कार्ड", "ধ্বনি কাৰ্ড"],
  "Sound card {0} of {1}": [
    "ध्वनि कार्ड {0}, कुल {1}",
    "ধ্বনি কাৰ্ড {0}, মুঠ {1}",
  ],
  "Previous sound": ["पछिला ध्वनि", "আগৰ ধ্বনি"],
  "Next sound": ["अगिला ध्वनि", "পৰৱৰ্তী ধ্বনি"],
  "Play sentence": ["वाक्य सुनू", "বাক্য শুনক"],
  "No phonics activities available yet.": [
    "एखन धरि ध्वनि अभ्यास उपलब्ध नहि अछि।",
    "এতিয়ালৈকে ধ্বনি অনুশীলন উপলব্ধ নাই।",
  ],
  "Play story": ["कथा सुनू", "সাধু শুনক"],
  "Choose a learning plan": ["सीखबाक योजना चुनू", "শিকাৰ পৰিকল্পনা বাছক"],
  "This is a dummy checkout. Replace the provider calls later with Razorpay, Stripe, or your payment gateway.": [
    "ई डमी भुगतान अछि। बाद मे Razorpay, Stripe वा अपन भुगतान सेवा जोड़ू।",
    "এয়া ডামি চেকআউট। পিছত Razorpay, Stripe বা আপোনাৰ পেমেণ্ট সেৱা যোগ কৰক।",
  ],
  "No paid plans found.": [
    "कोनो सशुल्क योजना नहि भेटल।",
    "কোনো সশুল্ক পৰিকল্পনা পোৱা নগ’ল।",
  ],
  "Processing...": ["प्रक्रिया भऽ रहल अछि...", "প্ৰক্ৰিয়া চলি আছে..."],
  "Pay with dummy": ["डमी सँ भुगतान करू", "ডামিৰে পৰিশোধ কৰক"],
  "Dummy payment complete. Premium unlocked.": [
    "डमी भुगतान पूरा भेल। प्रीमियम खुलल।",
    "ডামি পৰিশোধ সম্পূৰ্ণ। প্ৰিমিয়াম মুকলি হ’ল।",
  ],
  "Subscription activated successfully.": [
    "सदस्यता सक्रिय भेल।",
    "সদস্যতা সফলভাৱে সক্ৰিয় হ’ল।",
  ],
  "{0} • INR {1}": ["{0} • INR {1}", "{0} • INR {1}"],
  "Content pending": ["सामग्री बाकी अछि", "বিষয়বস্তু বাকী আছে"],
  "{0} words available": ["{0} शब्द उपलब्ध अछि", "{0}টা শব্দ উপলব্ধ"],
  "{0} words": ["{0} शब्द", "{0}টা শব্দ"],
  "{0} words for {1} practice.": [
    "{1} अभ्यास लेल {0} शब्द।",
    "{1} অনুশীলনৰ বাবে {0}টা শব্দ।",
  ],
  "Language": ["भाषा", "ভাষা"],
  "Choose your 3 languages": ["अपन 3 भाषा चुनू", "আপোনাৰ ৩টা ভাষা বাছক"],
  "Pick three languages for your learning journey. The first one you pick will be your starting language.":
      [
        "सीखबा लेल तीन भाषा चुनू। पहिल चुनल भाषा सँ शुरुआत होएत।",
        "শিকিবলৈ তিনিটা ভাষা বাছক। প্ৰথমে বাছনি কৰা ভাষাৰে আৰম্ভ হ’ব।",
      ],
  "These three languages stay with your account. Switch between them anytime from Home.": [
    "ई तीन भाषा अहाँक खाता मे रहत। मुखपृष्ठ सँ कहियो बदलू।",
    "এই তিনিটা ভাষা আপোনাৰ একাউণ্টত থাকিব। মুখ্যপৃষ্ঠাৰ পৰা যিকোনো সময়ত সলনি কৰক।",
  ],
  "Your app and learning content use the same language.": [
    "ऐप आ सीखबाक सामग्री एकहि भाषा मे रहत।",
    "এপ আৰু শিকাৰ বিষয়বস্তুৰ ভাষা একেই থাকিব।",
  ],
  "Start learning": ["सीखब शुरू करू", "শিকিবলৈ আৰম্ভ কৰক"],
};

String? regionalText(String english, String language) {
  final index = language.toLowerCase() == 'maithili' ? 0 : 1;
  final exact = regionalTranslations[english];
  if (exact != null) return exact[index];
  for (final entry in _dynamicTranslations) {
    final match = entry.pattern.firstMatch(english);
    if (match == null) continue;
    var result = entry.values[index];
    for (var i = 1; i <= match.groupCount; i++) {
      result = result.replaceAll('{${i - 1}}', match.group(i)!);
    }
    return result;
  }
  return null;
}

final _dynamicTranslations =
    (regionalTranslations.entries
            .where((entry) => entry.key.contains('{0}'))
            .toList()
          ..sort((a, b) => b.key.length.compareTo(a.key.length)))
        .map((entry) {
          final parts = entry.key.split(RegExp(r'\{\d+\}'));
          return (
            pattern: RegExp('^${parts.map(RegExp.escape).join('(.*?)')}\$'),
            values: entry.value,
          );
        })
        .toList();
