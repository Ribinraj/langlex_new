const env = require('../config/env');
const { createBootstrapConnection, pool } = require('./db');
const { hashPassword } = require('../../shared/utils/password');

const databaseName = env.db.database.replace(/`/g, '``');

const ensureColumn = async (tableName, columnName, definition) => {
  const [rows] = await pool.execute(
    `SELECT COLUMN_NAME
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?
     LIMIT 1`,
    [env.db.database, tableName, columnName],
  );

  if (rows.length === 0) {
    await pool.query(
      `ALTER TABLE \`${tableName}\` ADD COLUMN \`${columnName}\` ${definition}`,
    );
  }
};

const createLearningTables = async () => {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS categories (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      title VARCHAR(255) NOT NULL,
      created VARCHAR(255) NOT NULL,
      image VARCHAR(255) NOT NULL,
      language VARCHAR(255) NOT NULL,
      PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS subcategories (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      title VARCHAR(255) NOT NULL,
      created VARCHAR(255) NOT NULL,
      image VARCHAR(255) NOT NULL,
      p_cat VARCHAR(255) NOT NULL,
      language VARCHAR(255) NOT NULL,
      PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS courses (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      title VARCHAR(255) NOT NULL,
      created VARCHAR(255) NOT NULL,
      image VARCHAR(255) NOT NULL,
      language VARCHAR(255) NOT NULL,
      show_plan VARCHAR(255) NOT NULL DEFAULT '0',
      PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS Content (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      content VARCHAR(255) NOT NULL,
      created VARCHAR(255) NOT NULL,
      content_image VARCHAR(255) NOT NULL,
      content_audio VARCHAR(255) NOT NULL,
      word_audio VARCHAR(255) NOT NULL,
      course VARCHAR(255) NOT NULL,
      subcategory VARCHAR(255) NOT NULL,
      category VARCHAR(255) NOT NULL,
      language VARCHAR(255) NOT NULL,
      PRIMARY KEY (id),
      KEY content_course_index (course),
      KEY content_category_index (category)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS Alphabets (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      letter VARCHAR(255) NOT NULL,
      ill_word VARCHAR(255) NOT NULL,
      ill_image VARCHAR(255) NOT NULL,
      letter_sound VARCHAR(255) NOT NULL,
      word_audio VARCHAR(255) NOT NULL,
      letter_type VARCHAR(255) NOT NULL,
      coursename VARCHAR(255) NOT NULL,
      subcategory VARCHAR(255) NOT NULL,
      category VARCHAR(255) NOT NULL,
      language VARCHAR(255) NOT NULL,
      title_image VARCHAR(255) NOT NULL,
      level VARCHAR(255) NOT NULL,
      created VARCHAR(255) NOT NULL,
      PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS quizz (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      Question VARCHAR(255) NOT NULL,
      ca VARCHAR(255) NOT NULL,
      o1 VARCHAR(255) NOT NULL,
      o2 VARCHAR(255) NOT NULL,
      o3 VARCHAR(255) NOT NULL,
      Instruction VARCHAR(255) NOT NULL,
      audio VARCHAR(255) NOT NULL,
      image VARCHAR(255) NOT NULL,
      RAFeed VARCHAR(255) NOT NULL,
      WAFeed VARCHAR(255) NOT NULL,
      difflvl VARCHAR(255) NOT NULL,
      topic VARCHAR(255) NOT NULL,
      QType VARCHAR(255) NOT NULL,
      created VARCHAR(255) NOT NULL,
      Language VARCHAR(255) NOT NULL,
      q_audio VARCHAR(255) NOT NULL,
      raf_audio VARCHAR(255) NOT NULL,
      waf_audio VARCHAR(255) NOT NULL,
      PRIMARY KEY (id),
      KEY quizz_topic_index (topic)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS phonics_category (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      title VARCHAR(255) NOT NULL,
      image VARCHAR(255) NOT NULL,
      created VARCHAR(255) NOT NULL,
      language VARCHAR(255) NOT NULL,
      PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS phonics_courses (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      title VARCHAR(255) NOT NULL,
      image VARCHAR(255) NOT NULL,
      created VARCHAR(255) NOT NULL,
      language VARCHAR(255) NOT NULL,
      subcategory VARCHAR(255) NOT NULL,
      PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS Phonics (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      sentence VARCHAR(255) NOT NULL,
      word VARCHAR(255) NOT NULL,
      image VARCHAR(255) NOT NULL,
      sentence_sound VARCHAR(255) NOT NULL,
      word_audio VARCHAR(255) NOT NULL,
      coursename VARCHAR(255) NOT NULL,
      language VARCHAR(255) NOT NULL,
      category VARCHAR(255) NOT NULL,
      subcategory VARCHAR(255) NOT NULL,
      created VARCHAR(255) NOT NULL,
      title_image VARCHAR(255) NOT NULL,
      level VARCHAR(255) NOT NULL,
      PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS stories (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      title VARCHAR(255) NOT NULL,
      text LONGTEXT NOT NULL,
      created VARCHAR(255) NOT NULL,
      language VARCHAR(255) NOT NULL,
      image VARCHAR(255) NOT NULL,
      audio VARCHAR(255) NOT NULL,
      title_image VARCHAR(255) NOT NULL,
      grade VARCHAR(255) NOT NULL,
      audio_text_map VARCHAR(255) NOT NULL,
      show_plan VARCHAR(255) NOT NULL,
      title_audio VARCHAR(255) NOT NULL,
      PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS site_language (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      lang1 VARCHAR(255) NOT NULL,
      lang2 VARCHAR(255) NOT NULL,
      lang3 VARCHAR(255) NOT NULL,
      lang4 VARCHAR(255) NOT NULL,
      language VARCHAR(255) NOT NULL,
      PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS subsc_plans (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      name VARCHAR(255) NOT NULL,
      type VARCHAR(255) NOT NULL,
      amount VARCHAR(255) NOT NULL,
      permission LONGTEXT NOT NULL,
      plan_timeperiod VARCHAR(255) NOT NULL,
      PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS payment_orders (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      user_id BIGINT UNSIGNED NOT NULL,
      plan_id BIGINT UNSIGNED NOT NULL,
      provider VARCHAR(80) NOT NULL DEFAULT 'dummy',
      provider_order_id VARCHAR(120) NOT NULL,
      amount VARCHAR(255) NOT NULL,
      currency VARCHAR(12) NOT NULL DEFAULT 'INR',
      status VARCHAR(40) NOT NULL DEFAULT 'created',
      metadata JSON NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      UNIQUE KEY payment_orders_provider_order_unique (provider_order_id),
      KEY payment_orders_user_id_index (user_id),
      KEY payment_orders_plan_id_index (plan_id),
      CONSTRAINT payment_orders_user_id_foreign
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS user_subscriptions (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      user_id BIGINT UNSIGNED NOT NULL,
      plan_id BIGINT UNSIGNED NOT NULL,
      payment_order_id BIGINT UNSIGNED NULL,
      status VARCHAR(40) NOT NULL DEFAULT 'active',
      started_at DATETIME NOT NULL,
      expires_at DATETIME NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      KEY user_subscriptions_user_id_index (user_id),
      KEY user_subscriptions_plan_id_index (plan_id),
      CONSTRAINT user_subscriptions_user_id_foreign
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
      CONSTRAINT user_subscriptions_payment_order_id_foreign
        FOREIGN KEY (payment_order_id) REFERENCES payment_orders(id)
        ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS user_learning_setups (
      user_id BIGINT UNSIGNED NOT NULL,
      child_name VARCHAR(120) NULL,
      age_group VARCHAR(80) NOT NULL,
      primary_language VARCHAR(80) NOT NULL,
      learning_language VARCHAR(80) NOT NULL,
      level VARCHAR(80) NOT NULL,
      interests JSON NULL,
      daily_goal_minutes INT UNSIGNED NOT NULL DEFAULT 15,
      plan_id BIGINT UNSIGNED NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (user_id),
      KEY user_learning_setups_plan_id_index (plan_id),
      CONSTRAINT user_learning_setups_user_id_foreign
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS user_daily_learning_events (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      user_id BIGINT UNSIGNED NOT NULL,
      activity_date DATE NOT NULL,
      activity_type VARCHAR(40) NOT NULL,
      activity_key VARCHAR(160) NOT NULL,
      estimated_minutes INT UNSIGNED NOT NULL DEFAULT 1,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      UNIQUE KEY user_daily_learning_events_unique (
        user_id,
        activity_date,
        activity_type,
        activity_key
      ),
      KEY user_daily_learning_events_user_date_index (user_id, activity_date),
      CONSTRAINT user_daily_learning_events_user_id_foreign
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS user_content_progress (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      user_id BIGINT UNSIGNED NOT NULL,
      content_type VARCHAR(40) NOT NULL,
      content_key VARCHAR(160) NOT NULL,
      status VARCHAR(40) NOT NULL DEFAULT 'in_progress',
      position INT UNSIGNED NOT NULL DEFAULT 0,
      total_items INT UNSIGNED NOT NULL DEFAULT 0,
      score INT UNSIGNED NOT NULL DEFAULT 0,
      metadata JSON NULL,
      last_practiced_at DATETIME NULL,
      completed_at DATETIME NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      UNIQUE KEY user_content_progress_unique (user_id, content_type, content_key),
      KEY user_content_progress_user_type_index (user_id, content_type),
      CONSTRAINT user_content_progress_user_id_foreign
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS user_content_progress_items (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      user_id BIGINT UNSIGNED NOT NULL,
      content_type VARCHAR(40) NOT NULL,
      content_key VARCHAR(160) NOT NULL,
      item_key VARCHAR(180) NOT NULL,
      position INT UNSIGNED NOT NULL DEFAULT 0,
      is_correct BOOLEAN NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      UNIQUE KEY user_content_progress_items_unique (
        user_id,
        content_type,
        content_key,
        item_key
      ),
      KEY user_content_progress_items_lookup_index (user_id, content_type, content_key),
      CONSTRAINT user_content_progress_items_user_id_foreign
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS notifications (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      user_id BIGINT UNSIGNED NULL,
      title VARCHAR(160) NOT NULL,
      body VARCHAR(500) NOT NULL,
      type VARCHAR(60) NOT NULL DEFAULT 'info',
      data JSON NULL,
      is_read BOOLEAN NOT NULL DEFAULT FALSE,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      read_at DATETIME NULL,
      PRIMARY KEY (id),
      KEY notifications_user_id_created_at_index (user_id, created_at),
      KEY notifications_user_id_is_read_index (user_id, is_read),
      CONSTRAINT notifications_user_id_foreign
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS admin_users (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      full_name VARCHAR(120) NOT NULL,
      email VARCHAR(191) NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      role VARCHAR(60) NOT NULL DEFAULT 'super_admin',
      is_active BOOLEAN NOT NULL DEFAULT TRUE,
      last_login_at DATETIME NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      UNIQUE KEY admin_users_email_unique (email)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);
};

const seedAdminUser = async () => {
  const email = env.admin.email.trim().toLowerCase();
  const [rows] = await pool.execute(
    `SELECT id FROM admin_users WHERE email = ? LIMIT 1`,
    [email],
  );

  if (rows.length > 0) return;

  const passwordHash = await hashPassword(env.admin.password);
  await pool.execute(
    `INSERT INTO admin_users (full_name, email, password_hash, role)
     VALUES (?, ?, ?, 'super_admin')`,
    [env.admin.name, email, passwordHash],
  );
};

const upsertRows = async (tableName, columns, rows) => {
  if (rows.length === 0) return;

  const escapedColumns = columns.map((column) => `\`${column}\``).join(', ');
  const placeholders = rows
    .map(() => `(${columns.map(() => '?').join(', ')})`)
    .join(', ');
  const updates = columns
    .filter((column) => column !== 'id')
    .map((column) => `\`${column}\` = VALUES(\`${column}\`)`)
    .join(', ');

  await pool.query(
    `INSERT INTO \`${tableName}\` (${escapedColumns}) VALUES ${placeholders}
     ON DUPLICATE KEY UPDATE ${updates}`,
    rows.flat(),
  );
};

const imageKeyword = (label) => {
  const stopWords = new Set([
    'a',
    'an',
    'the',
    'for',
    'learn',
    'basic',
    'common',
    'quiz',
    'sound',
    'sounds',
    'word',
    'words',
    'family',
  ]);
  const words = String(label)
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter((word) => word && !stopWords.has(word));

  return words.length ? words.slice(-2).join(',') : 'kids,learning';
};

const imageLock = (label) =>
  [...String(label)].reduce((hash, char) => hash + char.charCodeAt(0), 0) %
    10000 +
  1;

const dummyImage = (label) =>
  `https://loremflickr.com/640/420/${imageKeyword(label)}?lock=${imageLock(label)}`;

const wordAudio = (slug) => `/media/audio/words/${slug}.wav`;

const soundAudio = (slug) => `/media/audio/sounds/${slug}.wav`;

const letterAudio = (slug) => `/media/audio/letters/${slug}.wav`;

const storyAudio = (slug) => `/media/audio/stories/${slug}.wav`;

const sentenceAudio = (slug) => `/media/audio/sentences/${slug}.wav`;

const seedLearningData = async () => {
  await upsertRows(
    'categories',
    ['id', 'title', 'created', 'image', 'language'],
    [
      [1, 'Animals', '2026-07-09', '/media/images/categories/animals.png', 'English'],
      [2, 'Alphabets', '2026-07-09', '/media/images/categories/alphabets.png', 'English'],
      [3, 'Numbers', '2026-07-09', '/media/images/categories/numbers.png', 'English'],
      [4, 'Colors', '2026-07-09', '/media/images/categories/colors.png', 'English'],
      [5, 'Fruits', '2026-07-09', '/media/images/categories/fruits.png', 'English'],
      [6, 'Vegetables', '2026-07-09', '/media/images/categories/vegetables.png', 'English'],
    ],
  );

  await upsertRows(
    'subcategories',
    ['id', 'title', 'created', 'image', 'p_cat', 'language'],
    [
      [1, 'Pet Animals', '2026-07-09', '/media/images/subcategories/pet-animals.png', 'Animals', 'English'],
      [2, 'Wild Animals', '2026-07-09', '/media/images/subcategories/wild-animals.png', 'Animals', 'English'],
      [3, 'Farm Animals', '2026-07-09', '/media/images/subcategories/farm-animals.png', 'Animals', 'English'],
      [4, 'Numbers 1 to 10', '2026-07-09', '/media/images/subcategories/numbers-1-10.png', 'Numbers', 'English'],
      [5, 'Basic Colors', '2026-07-09', '/media/images/subcategories/basic-colors.png', 'Colors', 'English'],
      [6, 'Common Fruits', '2026-07-09', '/media/images/subcategories/common-fruits.png', 'Fruits', 'English'],
      [7, 'Common Vegetables', '2026-07-09', '/media/images/subcategories/common-vegetables.png', 'Vegetables', 'English'],
    ],
  );

  await upsertRows(
    'courses',
    ['id', 'title', 'created', 'image', 'language', 'show_plan'],
    [
      [1, 'Learn Pet Animals', '2026-07-09', '/media/images/courses/pet-animals.png', 'English', '0'],
      [2, 'Learn Alphabets', '2026-07-09', '/media/images/courses/alphabets.png', 'English', '0'],
      [3, 'Learn Farm Animals', '2026-07-09', '/media/images/courses/farm-animals.png', 'English', '0'],
      [4, 'Learn Numbers', '2026-07-09', '/media/images/courses/numbers.png', 'English', '0'],
      [5, 'Learn Colors', '2026-07-09', '/media/images/courses/colors.png', 'English', '0'],
      [6, 'Learn Fruits', '2026-07-09', '/media/images/courses/fruits.png', 'English', '1'],
      [7, 'Learn Vegetables', '2026-07-09', '/media/images/courses/vegetables.png', 'English', '1'],
    ],
  );

  await upsertRows(
    'Content',
    [
      'id',
      'content',
      'created',
      'content_image',
      'content_audio',
      'word_audio',
      'course',
      'subcategory',
      'category',
      'language',
    ],
    [
      [1, 'Cat', '2026-07-09', '/media/images/content/cat.png', '/media/audio/sounds/cat.wav', '/media/audio/words/cat.wav', 'Learn Pet Animals', 'Pet Animals', 'Animals', 'English'],
      [2, 'Dog', '2026-07-09', '/media/images/content/dog.png', '/media/audio/sounds/dog.wav', '/media/audio/words/dog.wav', 'Learn Pet Animals', 'Pet Animals', 'Animals', 'English'],
      [3, 'Cow', '2026-07-09', '/media/images/content/cow.png', '/media/audio/sounds/cow.wav', '/media/audio/words/cow.wav', 'Learn Farm Animals', 'Farm Animals', 'Animals', 'English'],
      [4, 'Horse', '2026-07-09', '/media/images/content/horse.png', '/media/audio/sounds/horse.wav', '/media/audio/words/horse.wav', 'Learn Farm Animals', 'Farm Animals', 'Animals', 'English'],
      [5, 'One', '2026-07-09', '/media/images/content/one.png', '/media/audio/sounds/one.wav', '/media/audio/words/one.wav', 'Learn Numbers', 'Numbers 1 to 10', 'Numbers', 'English'],
      [6, 'Two', '2026-07-09', '/media/images/content/two.png', '/media/audio/sounds/two.wav', '/media/audio/words/two.wav', 'Learn Numbers', 'Numbers 1 to 10', 'Numbers', 'English'],
      [7, 'Red', '2026-07-09', '/media/images/content/red.png', '/media/audio/sounds/red.wav', '/media/audio/words/red.wav', 'Learn Colors', 'Basic Colors', 'Colors', 'English'],
      [8, 'Blue', '2026-07-09', '/media/images/content/blue.png', '/media/audio/sounds/blue.wav', '/media/audio/words/blue.wav', 'Learn Colors', 'Basic Colors', 'Colors', 'English'],
      [9, 'Apple', '2026-07-09', '/media/images/content/apple.png', '/media/audio/sounds/apple.wav', '/media/audio/words/apple.wav', 'Learn Fruits', 'Common Fruits', 'Fruits', 'English'],
      [10, 'Mango', '2026-07-09', '/media/images/content/mango.png', '/media/audio/sounds/mango.wav', '/media/audio/words/mango.wav', 'Learn Fruits', 'Common Fruits', 'Fruits', 'English'],
      [11, 'Carrot', '2026-07-09', '/media/images/content/carrot.png', '/media/audio/sounds/carrot.wav', '/media/audio/words/carrot.wav', 'Learn Vegetables', 'Common Vegetables', 'Vegetables', 'English'],
      [12, 'Tomato', '2026-07-09', '/media/images/content/tomato.png', '/media/audio/sounds/tomato.wav', '/media/audio/words/tomato.wav', 'Learn Vegetables', 'Common Vegetables', 'Vegetables', 'English'],
    ],
  );

  await upsertRows(
    'Alphabets',
    [
      'id',
      'letter',
      'ill_word',
      'ill_image',
      'letter_sound',
      'word_audio',
      'letter_type',
      'coursename',
      'subcategory',
      'category',
      'language',
      'title_image',
      'level',
      'created',
    ],
    [
      [1, 'A', 'Apple', '/media/images/alphabets/apple.png', '/media/audio/letters/a.wav', '/media/audio/words/apple.wav', 'Vowel', 'Learn Alphabets', 'Alphabet Letter Recognition', 'Alphabets', 'English', '/media/images/courses/alphabets.png', 'Beginner', '2026-07-09'],
      [2, 'B', 'Ball', '/media/images/alphabets/ball.png', '/media/audio/letters/b.wav', '/media/audio/words/ball.wav', 'Consonant', 'Learn Alphabets', 'Alphabet Letter Recognition', 'Alphabets', 'English', '/media/images/courses/alphabets.png', 'Beginner', '2026-07-09'],
      [3, 'C', 'Cat', '/media/images/alphabets/cat.png', '/media/audio/letters/c.wav', '/media/audio/words/cat.wav', 'Consonant', 'Learn Alphabets', 'Alphabet Letter Recognition', 'Alphabets', 'English', '/media/images/courses/alphabets.png', 'Beginner', '2026-07-09'],
      [4, 'D', 'Dog', '/media/images/alphabets/dog.png', '/media/audio/letters/d.wav', '/media/audio/words/dog.wav', 'Consonant', 'Learn Alphabets', 'Alphabet Letter Recognition', 'Alphabets', 'English', '/media/images/courses/alphabets.png', 'Beginner', '2026-07-09'],
      [5, 'E', 'Elephant', '/media/images/alphabets/elephant.png', '/media/audio/letters/e.wav', '/media/audio/words/elephant.wav', 'Vowel', 'Learn Alphabets', 'Alphabet Letter Recognition', 'Alphabets', 'English', '/media/images/courses/alphabets.png', 'Beginner', '2026-07-09'],
      [6, 'F', 'Fish', '/media/images/alphabets/fish.png', '/media/audio/letters/f.wav', '/media/audio/words/fish.wav', 'Consonant', 'Learn Alphabets', 'Alphabet Letter Recognition', 'Alphabets', 'English', '/media/images/courses/alphabets.png', 'Beginner', '2026-07-09'],
    ],
  );

  await upsertRows(
    'quizz',
    [
      'id',
      'Question',
      'ca',
      'o1',
      'o2',
      'o3',
      'Instruction',
      'audio',
      'image',
      'RAFeed',
      'WAFeed',
      'difflvl',
      'topic',
      'QType',
      'created',
      'Language',
      'q_audio',
      'raf_audio',
      'waf_audio',
    ],
    [
      [1, 'Which animal says meow?', 'Cat', 'Dog', 'Cow', 'Fish', 'Choose the correct answer', '', '/media/images/content/cat.png', 'Great job', 'Try again', 'easy', 'Pet Animals', 'mcq', '2026-07-09', 'English', '', '', ''],
      [2, 'Which letter starts Apple?', 'A', 'B', 'C', 'D', 'Choose the correct answer', '', '/media/images/alphabets/apple.png', 'Great job', 'Try again', 'easy', 'Alphabet Letter Recognition', 'mcq', '2026-07-09', 'English', '', '', ''],
      [3, 'Which animal gives milk?', 'Cow', 'Cat', 'Fish', 'Lion', 'Choose the correct answer', '', '/media/images/content/cow.png', 'Great job', 'Try again', 'easy', 'Farm Animals', 'mcq', '2026-07-09', 'English', '', '', ''],
      [4, 'Which number comes after one?', 'Two', 'Three', 'Four', 'Five', 'Choose the correct answer', '', '/media/images/content/two.png', 'Great job', 'Try again', 'easy', 'Numbers 1 to 10', 'mcq', '2026-07-09', 'English', '', '', ''],
      [5, 'Which color is shown?', 'Red', 'Blue', 'Green', 'Yellow', 'Choose the correct answer', '', '/media/images/content/red.png', 'Great job', 'Try again', 'easy', 'Basic Colors', 'mcq', '2026-07-09', 'English', '', '', ''],
      [6, 'Which fruit is yellow?', 'Mango', 'Carrot', 'Tomato', 'Dog', 'Choose the correct answer', '', '/media/images/content/mango.png', 'Great job', 'Try again', 'easy', 'Common Fruits', 'mcq', '2026-07-09', 'English', '', '', ''],
      [7, 'Which vegetable is orange?', 'Carrot', 'Apple', 'Mango', 'Blue', 'Choose the correct answer', '', '/media/images/content/carrot.png', 'Great job', 'Try again', 'easy', 'Common Vegetables', 'mcq', '2026-07-09', 'English', '', '', ''],
      [8, 'Which letter starts Fish?', 'F', 'A', 'B', 'E', 'Choose the correct answer', '', '/media/images/alphabets/fish.png', 'Great job', 'Try again', 'easy', 'Alphabet Letter Recognition', 'mcq', '2026-07-09', 'English', '', '', ''],
    ],
  );

  await upsertRows(
    'phonics_category',
    ['id', 'title', 'image', 'created', 'language'],
    [
      [1, 'Phonics Basics', '/media/images/phonics/basics.png', '2026-07-09', 'English'],
      [2, 'Blending Sounds', '/media/images/phonics/blending.png', '2026-07-09', 'English'],
    ],
  );

  await upsertRows(
    'phonics_courses',
    ['id', 'title', 'image', 'created', 'language', 'subcategory'],
    [
      [1, 'Short A Sound', '/media/images/phonics/short-a.png', '2026-07-09', 'English', 'Short Sounds'],
      [2, 'Long E Sound', '/media/images/phonics/long-e.png', '2026-07-09', 'English', 'Long Sounds'],
      [3, 'BL Blend', '/media/images/phonics/bl-blend.png', '2026-07-09', 'English', 'Two Letter Blends'],
    ],
  );

  await upsertRows(
    'Phonics',
    [
      'id',
      'sentence',
      'word',
      'image',
      'sentence_sound',
      'word_audio',
      'coursename',
      'language',
      'category',
      'subcategory',
      'created',
      'title_image',
      'level',
    ],
    [
      [1, 'A cat sat on a mat.', 'cat', '/media/images/phonics/cat.png', '/media/audio/sentences/cat-sat.wav', '/media/audio/words/cat.wav', 'Short A Sound', 'English', 'Phonics Basics', 'Short Sounds', '2026-07-09', '/media/images/phonics/short-a.png', 'Beginner'],
      [2, 'The bee is on the leaf.', 'bee', '/media/images/phonics/bee.png', '/media/audio/sentences/bee-leaf.wav', '/media/audio/words/bee.wav', 'Long E Sound', 'English', 'Phonics Basics', 'Long Sounds', '2026-07-09', '/media/images/phonics/long-e.png', 'Beginner'],
      [3, 'The blue block is big.', 'blue', '/media/images/phonics/blue-block.png', '/media/audio/sentences/blue-block.wav', '/media/audio/words/blue.wav', 'BL Blend', 'English', 'Blending Sounds', 'Two Letter Blends', '2026-07-09', '/media/images/phonics/bl-blend.png', 'Beginner'],
    ],
  );

  await upsertRows('subsc_plans', ['id', 'name', 'type', 'amount', 'permission', 'plan_timeperiod'], [
    [1, 'Free Trial', 'free', '0', '{"courses":"limited"}', '7 days'],
    [2, 'Monthly Learning', 'paid', '199', '{"courses":"all"}', '30 days'],
    [3, 'Quarterly Learning', 'paid', '499', '{"courses":"all","stories":"all"}', '90 days'],
    [4, 'Annual Learning', 'paid', '1499', '{"courses":"all","stories":"all","quizzes":"all"}', '365 days'],
  ]);

  await upsertRows(
    'stories',
    [
      'id',
      'title',
      'text',
      'created',
      'language',
      'image',
      'audio',
      'title_image',
      'grade',
      'audio_text_map',
      'show_plan',
      'title_audio',
    ],
    [
      [1, 'The Red Ball', 'A small story for local testing.', '2026-07-09', 'English', '/media/images/stories/red-ball.png', '/media/audio/stories/red-ball.wav', '/media/images/stories/red-ball-title.png', 'Beginner', '{}', '0', '/media/audio/stories/red-ball-title.wav'],
      [2, 'Mango Day', 'Mira finds a ripe mango and shares it with her friend.', '2026-07-09', 'English', '/media/images/stories/mango-day.png', '/media/audio/stories/mango-day.wav', '/media/images/stories/mango-day-title.png', 'Beginner', '{}', '0', '/media/audio/stories/mango-day-title.wav'],
      [3, 'The Blue Kite', 'A blue kite flies high above the park.', '2026-07-09', 'English', '/media/images/stories/blue-kite.png', '/media/audio/stories/blue-kite.wav', '/media/images/stories/blue-kite-title.png', 'Beginner', '{}', '1', '/media/audio/stories/blue-kite-title.wav'],
    ],
  );
};

const seedExpandedTestData = async () => {
  await upsertRows(
    'categories',
    ['id', 'title', 'created', 'image', 'language'],
    [
      [1, 'Animals', '2026-07-09', dummyImage('Animals', '6FA890'), 'English'],
      [2, 'Alphabets', '2026-07-09', dummyImage('Alphabets', '9B6EE8'), 'English'],
      [3, 'Numbers', '2026-07-09', dummyImage('Numbers', '4A8F7A'), 'English'],
      [4, 'Colors', '2026-07-09', dummyImage('Colors', 'DB9A3C'), 'English'],
      [5, 'Fruits', '2026-07-09', dummyImage('Fruits', 'E05C8A'), 'English'],
      [6, 'Vegetables', '2026-07-09', dummyImage('Vegetables', '5E9F6B'), 'English'],
      [7, 'Shapes', '2026-07-09', dummyImage('Shapes', '6E90E8'), 'English'],
      [8, 'Body Parts', '2026-07-09', dummyImage('Body Parts', 'E879A7'), 'English'],
      [9, 'Vehicles', '2026-07-09', dummyImage('Vehicles', '7A87B8'), 'English'],
    ],
  );

  await upsertRows(
    'subcategories',
    ['id', 'title', 'created', 'image', 'p_cat', 'language'],
    [
      [8, 'Basic Shapes', '2026-07-09', dummyImage('Basic Shapes', '6E90E8'), 'Shapes', 'English'],
      [9, 'My Body', '2026-07-09', dummyImage('My Body', 'E879A7'), 'Body Parts', 'English'],
      [10, 'Road Vehicles', '2026-07-09', dummyImage('Road Vehicles', '7A87B8'), 'Vehicles', 'English'],
      [11, 'Birds', '2026-07-09', dummyImage('Birds', '6FA890'), 'Animals', 'English'],
      [12, 'Weather Words', '2026-07-09', dummyImage('Weather', '4A8F7A'), 'Knowledge', 'English'],
    ],
  );

  await upsertRows(
    'courses',
    ['id', 'title', 'created', 'image', 'language', 'show_plan'],
    [
      [1, 'Learn Pet Animals', '2026-07-09', dummyImage('Pet Animals', '6FA890'), 'English', '0'],
      [2, 'Learn Alphabets', '2026-07-09', dummyImage('Alphabets', '9B6EE8'), 'English', '0'],
      [3, 'Learn Farm Animals', '2026-07-09', dummyImage('Farm Animals', '6FA890'), 'English', '0'],
      [4, 'Learn Numbers', '2026-07-09', dummyImage('Numbers', '4A8F7A'), 'English', '0'],
      [5, 'Learn Colors', '2026-07-09', dummyImage('Colors', 'DB9A3C'), 'English', '0'],
      [6, 'Learn Fruits', '2026-07-09', dummyImage('Fruits', 'E05C8A'), 'English', '1'],
      [7, 'Learn Vegetables', '2026-07-09', dummyImage('Vegetables', '5E9F6B'), 'English', '1'],
      [8, 'Learn Shapes', '2026-07-09', dummyImage('Shapes', '6E90E8'), 'English', '0'],
      [9, 'Learn Body Parts', '2026-07-09', dummyImage('Body Parts', 'E879A7'), 'English', '0'],
      [10, 'Learn Vehicles', '2026-07-09', dummyImage('Vehicles', '7A87B8'), 'English', '1'],
    ],
  );

  await upsertRows(
    'Content',
    [
      'id',
      'content',
      'created',
      'content_image',
      'content_audio',
      'word_audio',
      'course',
      'subcategory',
      'category',
      'language',
    ],
    [
      [1, 'Cat', '2026-07-09', dummyImage('Cat', '6FA890'), soundAudio('cat'), wordAudio('cat'), 'Learn Pet Animals', 'Pet Animals', 'Animals', 'English'],
      [2, 'Dog', '2026-07-09', dummyImage('Dog', '6FA890'), soundAudio('dog'), wordAudio('dog'), 'Learn Pet Animals', 'Pet Animals', 'Animals', 'English'],
      [3, 'Cow', '2026-07-09', dummyImage('Cow', '6FA890'), soundAudio('cow'), wordAudio('cow'), 'Learn Farm Animals', 'Farm Animals', 'Animals', 'English'],
      [4, 'Horse', '2026-07-09', dummyImage('Horse', '6FA890'), soundAudio('horse'), wordAudio('horse'), 'Learn Farm Animals', 'Farm Animals', 'Animals', 'English'],
      [5, 'One', '2026-07-09', dummyImage('One', '4A8F7A'), soundAudio('one'), wordAudio('one'), 'Learn Numbers', 'Numbers 1 to 10', 'Numbers', 'English'],
      [6, 'Two', '2026-07-09', dummyImage('Two', '4A8F7A'), soundAudio('two'), wordAudio('two'), 'Learn Numbers', 'Numbers 1 to 10', 'Numbers', 'English'],
      [7, 'Red', '2026-07-09', dummyImage('Red', 'DB9A3C'), soundAudio('red'), wordAudio('red'), 'Learn Colors', 'Basic Colors', 'Colors', 'English'],
      [8, 'Blue', '2026-07-09', dummyImage('Blue', 'DB9A3C'), soundAudio('blue'), wordAudio('blue'), 'Learn Colors', 'Basic Colors', 'Colors', 'English'],
      [9, 'Apple', '2026-07-09', dummyImage('Apple', 'E05C8A'), soundAudio('apple'), wordAudio('apple'), 'Learn Fruits', 'Common Fruits', 'Fruits', 'English'],
      [10, 'Mango', '2026-07-09', dummyImage('Mango', 'E05C8A'), soundAudio('mango'), wordAudio('mango'), 'Learn Fruits', 'Common Fruits', 'Fruits', 'English'],
      [11, 'Carrot', '2026-07-09', dummyImage('Carrot', '5E9F6B'), soundAudio('carrot'), wordAudio('carrot'), 'Learn Vegetables', 'Common Vegetables', 'Vegetables', 'English'],
      [12, 'Tomato', '2026-07-09', dummyImage('Tomato', '5E9F6B'), soundAudio('tomato'), wordAudio('tomato'), 'Learn Vegetables', 'Common Vegetables', 'Vegetables', 'English'],
      [13, 'A', '2026-07-09', dummyImage('A for Apple', '9B6EE8'), letterAudio('a'), wordAudio('apple'), 'Learn Alphabets', 'Alphabet Letter Recognition', 'Alphabets', 'English'],
      [14, 'B', '2026-07-09', dummyImage('B for Ball', '9B6EE8'), letterAudio('b'), wordAudio('ball'), 'Learn Alphabets', 'Alphabet Letter Recognition', 'Alphabets', 'English'],
      [15, 'C', '2026-07-09', dummyImage('C for Cat', '9B6EE8'), letterAudio('c'), wordAudio('cat'), 'Learn Alphabets', 'Alphabet Letter Recognition', 'Alphabets', 'English'],
      [16, 'Circle', '2026-07-09', dummyImage('Circle', '6E90E8'), soundAudio('circle'), wordAudio('circle'), 'Learn Shapes', 'Basic Shapes', 'Shapes', 'English'],
      [17, 'Square', '2026-07-09', dummyImage('Square', '6E90E8'), soundAudio('square'), wordAudio('square'), 'Learn Shapes', 'Basic Shapes', 'Shapes', 'English'],
      [18, 'Triangle', '2026-07-09', dummyImage('Triangle', '6E90E8'), soundAudio('triangle'), wordAudio('triangle'), 'Learn Shapes', 'Basic Shapes', 'Shapes', 'English'],
      [19, 'Eye', '2026-07-09', dummyImage('Eye', 'E879A7'), soundAudio('eye'), wordAudio('eye'), 'Learn Body Parts', 'My Body', 'Body Parts', 'English'],
      [20, 'Hand', '2026-07-09', dummyImage('Hand', 'E879A7'), soundAudio('hand'), wordAudio('hand'), 'Learn Body Parts', 'My Body', 'Body Parts', 'English'],
      [21, 'Leg', '2026-07-09', dummyImage('Leg', 'E879A7'), soundAudio('leg'), wordAudio('leg'), 'Learn Body Parts', 'My Body', 'Body Parts', 'English'],
      [22, 'Car', '2026-07-09', dummyImage('Car', '7A87B8'), soundAudio('car'), wordAudio('car'), 'Learn Vehicles', 'Road Vehicles', 'Vehicles', 'English'],
      [23, 'Bus', '2026-07-09', dummyImage('Bus', '7A87B8'), soundAudio('bus'), wordAudio('bus'), 'Learn Vehicles', 'Road Vehicles', 'Vehicles', 'English'],
      [24, 'Bike', '2026-07-09', dummyImage('Bike', '7A87B8'), soundAudio('bike'), wordAudio('bike'), 'Learn Vehicles', 'Road Vehicles', 'Vehicles', 'English'],
      [25, 'Green', '2026-07-09', dummyImage('Green', '5E9F6B'), soundAudio('green'), wordAudio('green'), 'Learn Colors', 'Basic Colors', 'Colors', 'English'],
      [26, 'Banana', '2026-07-09', dummyImage('Banana', 'E05C8A'), soundAudio('banana'), wordAudio('banana'), 'Learn Fruits', 'Common Fruits', 'Fruits', 'English'],
      [27, 'Onion', '2026-07-09', dummyImage('Onion', '5E9F6B'), soundAudio('onion'), wordAudio('onion'), 'Learn Vegetables', 'Common Vegetables', 'Vegetables', 'English'],
    ],
  );

  await upsertRows(
    'Alphabets',
    [
      'id',
      'letter',
      'ill_word',
      'ill_image',
      'letter_sound',
      'word_audio',
      'letter_type',
      'coursename',
      'subcategory',
      'category',
      'language',
      'title_image',
      'level',
      'created',
    ],
    [
      [7, 'G', 'Grapes', dummyImage('Grapes', '9B6EE8'), letterAudio('g'), wordAudio('grapes'), 'Consonant', 'Learn Alphabets', 'Alphabet Letter Recognition', 'Alphabets', 'English', dummyImage('Alphabets', '9B6EE8'), 'Beginner', '2026-07-09'],
      [8, 'H', 'House', dummyImage('House', '9B6EE8'), letterAudio('h'), wordAudio('house'), 'Consonant', 'Learn Alphabets', 'Alphabet Letter Recognition', 'Alphabets', 'English', dummyImage('Alphabets', '9B6EE8'), 'Beginner', '2026-07-09'],
      [9, 'I', 'Ice Cream', dummyImage('Ice Cream', '9B6EE8'), letterAudio('i'), wordAudio('ice-cream'), 'Vowel', 'Learn Alphabets', 'Alphabet Letter Recognition', 'Alphabets', 'English', dummyImage('Alphabets', '9B6EE8'), 'Beginner', '2026-07-09'],
      [10, 'J', 'Jug', dummyImage('Jug', '9B6EE8'), letterAudio('j'), wordAudio('jug'), 'Consonant', 'Learn Alphabets', 'Alphabet Letter Recognition', 'Alphabets', 'English', dummyImage('Alphabets', '9B6EE8'), 'Beginner', '2026-07-09'],
    ],
  );

  await upsertRows(
    'quizz',
    [
      'id',
      'Question',
      'ca',
      'o1',
      'o2',
      'o3',
      'Instruction',
      'audio',
      'image',
      'RAFeed',
      'WAFeed',
      'difflvl',
      'topic',
      'QType',
      'created',
      'Language',
      'q_audio',
      'raf_audio',
      'waf_audio',
    ],
    [
      [9, 'Which shape is round?', 'Circle', 'Square', 'Triangle', 'Bus', 'Choose the correct shape', '', dummyImage('Circle Quiz', '6E90E8'), 'Correct, circle is round.', 'Look again at the shape.', 'easy', 'Basic Shapes', 'mcq', '2026-07-09', 'English', '', '', ''],
      [10, 'Which one is a vehicle?', 'Car', 'Apple', 'Hand', 'Red', 'Choose the vehicle', '', dummyImage('Vehicle Quiz', '7A87B8'), 'Great, car is a vehicle.', 'Try another option.', 'easy', 'Road Vehicles', 'mcq', '2026-07-09', 'English', '', '', ''],
      [11, 'Which body part helps us see?', 'Eye', 'Hand', 'Leg', 'Bus', 'Choose the body part', '', dummyImage('Eye Quiz', 'E879A7'), 'Yes, eyes help us see.', 'Think about seeing.', 'easy', 'My Body', 'mcq', '2026-07-09', 'English', '', '', ''],
      [12, 'Which fruit is long and yellow?', 'Banana', 'Carrot', 'Tomato', 'Cat', 'Choose the fruit', '', dummyImage('Banana Quiz', 'E05C8A'), 'Nice work.', 'Try again.', 'easy', 'Common Fruits', 'mcq', '2026-07-09', 'English', '', '', ''],
      [13, 'Which color is the grass?', 'Green', 'Blue', 'Red', 'Yellow', 'Choose the color', '', dummyImage('Green Quiz', '5E9F6B'), 'Green is right.', 'Look for grass color.', 'easy', 'Basic Colors', 'mcq', '2026-07-09', 'English', '', '', ''],
      [14, 'Which letter starts House?', 'H', 'G', 'I', 'J', 'Choose the starting letter', '', dummyImage('House Quiz', '9B6EE8'), 'House starts with H.', 'Try listening to the first sound.', 'easy', 'Alphabet Letter Recognition', 'mcq', '2026-07-09', 'English', '', '', ''],
    ],
  );

  await upsertRows(
    'phonics_category',
    ['id', 'title', 'image', 'created', 'language'],
    [
      [1, 'Phonics Basics', dummyImage('Phonics Basics', '6FA890'), '2026-07-09', 'English'],
      [2, 'Blending Sounds', dummyImage('Blending Sounds', '9B6EE8'), '2026-07-09', 'English'],
      [3, 'Ending Sounds', dummyImage('Ending Sounds', '6FA890'), '2026-07-09', 'English'],
      [4, 'Rhyming Words', dummyImage('Rhyming Words', 'DB9A3C'), '2026-07-09', 'English'],
    ],
  );

  await upsertRows(
    'phonics_courses',
    ['id', 'title', 'image', 'created', 'language', 'subcategory'],
    [
      [1, 'Short A Sound', dummyImage('Short A Sound', '6FA890'), '2026-07-09', 'English', 'Short Sounds'],
      [2, 'Long E Sound', dummyImage('Long E Sound', '9B6EE8'), '2026-07-09', 'English', 'Long Sounds'],
      [3, 'BL Blend', dummyImage('BL Blend', '6E90E8'), '2026-07-09', 'English', 'Two Letter Blends'],
      [4, 'AT Family', dummyImage('AT Family', '6FA890'), '2026-07-09', 'English', 'Word Families'],
      [5, 'OP Family', dummyImage('OP Family', 'DB9A3C'), '2026-07-09', 'English', 'Word Families'],
      [6, 'SH Sound', dummyImage('SH Sound', '9B6EE8'), '2026-07-09', 'English', 'Digraphs'],
    ],
  );

  await upsertRows(
    'Phonics',
    [
      'id',
      'sentence',
      'word',
      'image',
      'sentence_sound',
      'word_audio',
      'coursename',
      'language',
      'category',
      'subcategory',
      'created',
      'title_image',
      'level',
    ],
    [
      [1, 'A cat sat on a mat.', 'cat', dummyImage('Cat', '6FA890'), sentenceAudio('cat-sat'), wordAudio('cat'), 'Short A Sound', 'English', 'Phonics Basics', 'Short Sounds', '2026-07-09', dummyImage('Short A Sound', '6FA890'), 'Beginner'],
      [2, 'The bee is on the leaf.', 'bee', dummyImage('Bee', 'DB9A3C'), sentenceAudio('bee-leaf'), wordAudio('bee'), 'Long E Sound', 'English', 'Phonics Basics', 'Long Sounds', '2026-07-09', dummyImage('Long E Sound', '9B6EE8'), 'Beginner'],
      [3, 'The blue block is big.', 'blue', dummyImage('Blue Block', '6E90E8'), sentenceAudio('blue-block'), wordAudio('blue'), 'BL Blend', 'English', 'Blending Sounds', 'Two Letter Blends', '2026-07-09', dummyImage('BL Blend', '6E90E8'), 'Beginner'],
      [4, 'The cat has a hat.', 'hat', dummyImage('Hat', '6FA890'), sentenceAudio('cat-hat'), wordAudio('hat'), 'AT Family', 'English', 'Rhyming Words', 'Word Families', '2026-07-09', dummyImage('AT Family', '6FA890'), 'Beginner'],
      [5, 'The frog can hop.', 'hop', dummyImage('Hop', 'DB9A3C'), sentenceAudio('frog-hop'), wordAudio('hop'), 'OP Family', 'English', 'Rhyming Words', 'Word Families', '2026-07-09', dummyImage('OP Family', 'DB9A3C'), 'Beginner'],
      [6, 'The ship is big.', 'ship', dummyImage('Ship', '9B6EE8'), sentenceAudio('ship-big'), wordAudio('ship'), 'SH Sound', 'English', 'Ending Sounds', 'Digraphs', '2026-07-09', dummyImage('SH Sound', '9B6EE8'), 'Beginner'],
    ],
  );

  await upsertRows(
    'subsc_plans',
    ['id', 'name', 'type', 'amount', 'permission', 'plan_timeperiod'],
    [
      [5, 'Family Learning', 'paid', '2499', '{"courses":"all","stories":"all","quizzes":"all","children":"3"}', '365 days'],
    ],
  );

  await upsertRows(
    'stories',
    [
      'id',
      'title',
      'text',
      'created',
      'language',
      'image',
      'audio',
      'title_image',
      'grade',
      'audio_text_map',
      'show_plan',
      'title_audio',
    ],
    [
      [1, 'The Red Ball', 'A small story for local testing.', '2026-07-09', 'English', dummyImage('Red Ball', 'DB9A3C'), storyAudio('red-ball'), dummyImage('Red Ball Title', 'DB9A3C'), 'Beginner', '{}', '0', storyAudio('red-ball-title')],
      [2, 'Mango Day', 'Mira finds a ripe mango and shares it with her friend.', '2026-07-09', 'English', dummyImage('Mango Day', 'E05C8A'), storyAudio('mango-day'), dummyImage('Mango Day Title', 'E05C8A'), 'Beginner', '{}', '0', storyAudio('mango-day-title')],
      [3, 'The Blue Kite', 'A blue kite flies high above the park.', '2026-07-09', 'English', dummyImage('Blue Kite', '6E90E8'), storyAudio('blue-kite'), dummyImage('Blue Kite Title', '6E90E8'), 'Beginner', '{}', '1', storyAudio('blue-kite-title')],
      [4, 'The Little Bus', 'A little bus goes to school. It stops for friends and says beep beep.', '2026-07-09', 'English', dummyImage('Little Bus', '7A87B8'), storyAudio('little-bus'), dummyImage('Little Bus Title', '7A87B8'), 'Beginner', '{}', '0', storyAudio('little-bus-title')],
      [5, 'The Shape Garden', 'Mia finds a circle flower, a square stone, and a triangle kite in the garden.', '2026-07-09', 'English', dummyImage('Shape Garden', '6E90E8'), storyAudio('shape-garden'), dummyImage('Shape Garden Title', '6E90E8'), 'Beginner', '{}', '1', storyAudio('shape-garden-title')],
      [6, 'My Happy Hands', 'I clap my hands. I wave hello. I draw a star and smile.', '2026-07-09', 'English', dummyImage('Happy Hands', 'E879A7'), storyAudio('happy-hands'), dummyImage('Happy Hands Title', 'E879A7'), 'Beginner', '{}', '0', storyAudio('happy-hands-title')],
    ],
  );
};

const seedMultilingualTestData = async () => {
  await upsertRows(
    'site_language',
    ['id', 'lang1', 'lang2', 'lang3', 'lang4', 'language'],
    [
      [1, 'english', 'hindi', 'maithili', 'kannada', 'english'],
      [2, 'अंग्रेज़ी', 'हिन्दी', 'मैथिलि', 'कन्नड़', 'hindi'],
      [3, 'ಆಂಗ್ಲ', 'ಹಿಂದಿ', 'ಮೈಥಿಲಿ', 'ಕನ್ನಡ', 'kannada'],
      [4, 'अंग्रेज़ी', 'हिन्दी', 'मैथिलि', 'कन्नड़', 'maithili'],
    ],
  );

  await upsertRows(
    'categories',
    ['id', 'title', 'created', 'image', 'language'],
    [
      [101, 'पढ़ना सीखो', '2026-07-10', dummyImage('Hindi reading'), 'Hindi'],
      [102, 'जानवर', '2026-07-10', dummyImage('Hindi animals'), 'Hindi'],
      [103, 'ಓದಲು ಕಲಿಯಿರಿ', '2026-07-10', dummyImage('Kannada reading'), 'Kannada'],
      [104, 'ಪ್ರಾಣಿಗಳು', '2026-07-10', dummyImage('Kannada animals'), 'Kannada'],
      [105, 'पढ़ब सीखू', '2026-07-10', dummyImage('Maithili reading'), 'Maithili'],
      [106, 'जनावर', '2026-07-10', dummyImage('Maithili animals'), 'Maithili'],
    ],
  );

  await upsertRows(
    'subcategories',
    ['id', 'title', 'created', 'image', 'p_cat', 'language'],
    [
      [101, 'स्वर अक्षर', '2026-07-10', dummyImage('Hindi vowels'), 'पढ़ना सीखो', 'Hindi'],
      [102, 'पालतू जानवर', '2026-07-10', dummyImage('Hindi pet animals'), 'जानवर', 'Hindi'],
      [103, 'स्वादिष्ट फल', '2026-07-10', dummyImage('Hindi fruits'), 'पढ़ना सीखो', 'Hindi'],
      [104, 'ಸ್ವರಗಳು', '2026-07-10', dummyImage('Kannada vowels'), 'ಓದಲು ಕಲಿಯಿರಿ', 'Kannada'],
      [105, 'ಸಾಕು ಪ್ರಾಣಿಗಳು', '2026-07-10', dummyImage('Kannada pet animals'), 'ಪ್ರಾಣಿಗಳು', 'Kannada'],
      [106, 'ಹಣ್ಣುಗಳು', '2026-07-10', dummyImage('Kannada fruits'), 'ಓದಲು ಕಲಿಯಿರಿ', 'Kannada'],
      [107, 'स्वर आखर', '2026-07-10', dummyImage('Maithili vowels'), 'पढ़ब सीखू', 'Maithili'],
      [108, 'घरक जनावर', '2026-07-10', dummyImage('Maithili pet animals'), 'जनावर', 'Maithili'],
    ],
  );

  await upsertRows(
    'courses',
    ['id', 'title', 'created', 'image', 'language', 'show_plan'],
    [
      [101, 'स्वर अक्षर', '2026-07-10', dummyImage('Hindi alphabet course'), 'Hindi', '0'],
      [102, 'पालतू जानवर सीखें', '2026-07-10', dummyImage('Hindi pets course'), 'Hindi', '0'],
      [103, 'हिंदी फल', '2026-07-10', dummyImage('Hindi fruit course'), 'Hindi', '1'],
      [104, 'ಕನ್ನಡ ಅಕ್ಷರಗಳು', '2026-07-10', dummyImage('Kannada alphabet course'), 'Kannada', '0'],
      [105, 'ಸಾಕು ಪ್ರಾಣಿಗಳನ್ನು ಕಲಿಯಿರಿ', '2026-07-10', dummyImage('Kannada pets course'), 'Kannada', '0'],
      [106, 'ಕನ್ನಡ ಹಣ್ಣುಗಳು', '2026-07-10', dummyImage('Kannada fruit course'), 'Kannada', '1'],
      [107, 'स्वर आखर', '2026-07-10', dummyImage('Maithili alphabet course'), 'Maithili', '0'],
      [108, 'जनावर सीखू', '2026-07-10', dummyImage('Maithili pets course'), 'Maithili', '0'],
    ],
  );

  await upsertRows(
    'Content',
    [
      'id',
      'content',
      'created',
      'content_image',
      'content_audio',
      'word_audio',
      'course',
      'subcategory',
      'category',
      'language',
    ],
    [
      [101, 'बिल्ली', '2026-07-10', dummyImage('cat'), soundAudio('hindi-cat'), wordAudio('hindi-billi'), 'पालतू जानवर सीखें', 'पालतू जानवर', 'जानवर', 'Hindi'],
      [102, 'कुत्ता', '2026-07-10', dummyImage('dog'), soundAudio('hindi-dog'), wordAudio('hindi-kutta'), 'पालतू जानवर सीखें', 'पालतू जानवर', 'जानवर', 'Hindi'],
      [103, 'आम', '2026-07-10', dummyImage('mango'), soundAudio('hindi-mango'), wordAudio('hindi-aam'), 'हिंदी फल', 'स्वादिष्ट फल', 'पढ़ना सीखो', 'Hindi'],
      [104, 'सेब', '2026-07-10', dummyImage('apple'), soundAudio('hindi-apple'), wordAudio('hindi-seb'), 'हिंदी फल', 'स्वादिष्ट फल', 'पढ़ना सीखो', 'Hindi'],
      [105, 'ಬೆಕ್ಕು', '2026-07-10', dummyImage('cat'), soundAudio('kannada-cat'), wordAudio('kannada-bekku'), 'ಸಾಕು ಪ್ರಾಣಿಗಳನ್ನು ಕಲಿಯಿರಿ', 'ಸಾಕು ಪ್ರಾಣಿಗಳು', 'ಪ್ರಾಣಿಗಳು', 'Kannada'],
      [106, 'ನಾಯಿ', '2026-07-10', dummyImage('dog'), soundAudio('kannada-dog'), wordAudio('kannada-naayi'), 'ಸಾಕು ಪ್ರಾಣಿಗಳನ್ನು ಕಲಿಯಿರಿ', 'ಸಾಕು ಪ್ರಾಣಿಗಳು', 'ಪ್ರಾಣಿಗಳು', 'Kannada'],
      [107, 'ಮಾವು', '2026-07-10', dummyImage('mango'), soundAudio('kannada-mango'), wordAudio('kannada-maavu'), 'ಕನ್ನಡ ಹಣ್ಣುಗಳು', 'ಹಣ್ಣುಗಳು', 'ಓದಲು ಕಲಿಯಿರಿ', 'Kannada'],
      [108, 'ಸೇಬು', '2026-07-10', dummyImage('apple'), soundAudio('kannada-apple'), wordAudio('kannada-sebu'), 'ಕನ್ನಡ ಹಣ್ಣುಗಳು', 'ಹಣ್ಣುಗಳು', 'ಓದಲು ಕಲಿಯಿರಿ', 'Kannada'],
      [109, 'बिलाइ', '2026-07-10', dummyImage('cat'), soundAudio('maithili-cat'), wordAudio('maithili-bilai'), 'जनावर सीखू', 'घरक जनावर', 'जनावर', 'Maithili'],
      [110, 'कुकुर', '2026-07-10', dummyImage('dog'), soundAudio('maithili-dog'), wordAudio('maithili-kukur'), 'जनावर सीखू', 'घरक जनावर', 'जनावर', 'Maithili'],
      [111, 'आम', '2026-07-10', dummyImage('mango'), soundAudio('maithili-mango'), wordAudio('maithili-aam'), 'स्वर आखर', 'स्वर आखर', 'पढ़ब सीखू', 'Maithili'],
      [112, 'अनार', '2026-07-10', dummyImage('pomegranate'), soundAudio('maithili-pomegranate'), wordAudio('maithili-anar'), 'स्वर आखर', 'स्वर आखर', 'पढ़ब सीखू', 'Maithili'],
    ],
  );

  await upsertRows(
    'Alphabets',
    [
      'id',
      'letter',
      'ill_word',
      'ill_image',
      'letter_sound',
      'word_audio',
      'letter_type',
      'coursename',
      'subcategory',
      'category',
      'language',
      'title_image',
      'level',
      'created',
    ],
    [
      [101, 'अ', 'अनार', dummyImage('pomegranate'), letterAudio('hindi-a'), wordAudio('hindi-anar'), 'vowel', 'स्वर अक्षर', 'स्वर अक्षर', 'पढ़ना सीखो', 'Hindi', dummyImage('Hindi alphabet title'), 'Nursery', '2026-07-10'],
      [102, 'आ', 'आम', dummyImage('mango'), letterAudio('hindi-aa'), wordAudio('hindi-aam'), 'vowel', 'स्वर अक्षर', 'स्वर अक्षर', 'पढ़ना सीखो', 'Hindi', dummyImage('Hindi alphabet title'), 'Nursery', '2026-07-10'],
      [103, 'क', 'कमल', dummyImage('lotus'), letterAudio('hindi-ka'), wordAudio('hindi-kamal'), 'consonant', 'स्वर अक्षर', 'स्वर अक्षर', 'पढ़ना सीखो', 'Hindi', dummyImage('Hindi alphabet title'), 'LKG', '2026-07-10'],
      [104, 'ಅ', 'ಅಕ್ಕಿ', dummyImage('rice'), letterAudio('kannada-a'), wordAudio('kannada-akki'), 'vowel', 'ಕನ್ನಡ ಅಕ್ಷರಗಳು', 'ಸ್ವರಗಳು', 'ಓದಲು ಕಲಿಯಿರಿ', 'Kannada', dummyImage('Kannada alphabet title'), 'Nursery', '2026-07-10'],
      [105, 'ಆ', 'ಆನೆ', dummyImage('elephant'), letterAudio('kannada-aa'), wordAudio('kannada-aane'), 'vowel', 'ಕನ್ನಡ ಅಕ್ಷರಗಳು', 'ಸ್ವರಗಳು', 'ಓದಲು ಕಲಿಯಿರಿ', 'Kannada', dummyImage('Kannada alphabet title'), 'Nursery', '2026-07-10'],
      [106, 'ಕ', 'ಕಮಲ', dummyImage('lotus'), letterAudio('kannada-ka'), wordAudio('kannada-kamala'), 'consonant', 'ಕನ್ನಡ ಅಕ್ಷರಗಳು', 'ಸ್ವರಗಳು', 'ಓದಲು ಕಲಿಯಿರಿ', 'Kannada', dummyImage('Kannada alphabet title'), 'LKG', '2026-07-10'],
      [107, 'अ', 'अनार', dummyImage('pomegranate'), letterAudio('maithili-a'), wordAudio('maithili-anar'), 'vowel', 'स्वर आखर', 'स्वर आखर', 'पढ़ब सीखू', 'Maithili', dummyImage('Maithili alphabet title'), 'Nursery', '2026-07-10'],
      [108, 'आ', 'आम', dummyImage('mango'), letterAudio('maithili-aa'), wordAudio('maithili-aam'), 'vowel', 'स्वर आखर', 'स्वर आखर', 'पढ़ब सीखू', 'Maithili', dummyImage('Maithili alphabet title'), 'Nursery', '2026-07-10'],
    ],
  );

  await upsertRows(
    'quizz',
    [
      'id',
      'Question',
      'ca',
      'o1',
      'o2',
      'o3',
      'Instruction',
      'audio',
      'image',
      'RAFeed',
      'WAFeed',
      'difflvl',
      'topic',
      'QType',
      'created',
      'Language',
      'q_audio',
      'raf_audio',
      'waf_audio',
    ],
    [
      [101, 'कौन सा जानवर म्याऊं करता है?', 'बिल्ली', 'कुत्ता', 'आम', 'सेब', 'सही उत्तर चुनें', '', dummyImage('cat quiz'), 'बहुत अच्छा', 'फिर से कोशिश करें', 'easy', 'पालतू जानवर', 'mcq', '2026-07-10', 'Hindi', '', '', ''],
      [102, 'आम किस अक्षर से शुरू होता है?', 'आ', 'अ', 'क', 'म', 'सही अक्षर चुनें', '', dummyImage('mango quiz'), 'सही जवाब', 'दोबारा देखें', 'easy', 'स्वर अक्षर', 'mcq', '2026-07-10', 'Hindi', '', '', ''],
      [103, 'ಯಾವ ಪ್ರಾಣಿ ಮಿಯಾವು ಎನ್ನುತ್ತದೆ?', 'ಬೆಕ್ಕು', 'ನಾಯಿ', 'ಮಾವು', 'ಸೇಬು', 'ಸರಿಯಾದ ಉತ್ತರ ಆಯ್ಕೆಮಾಡಿ', '', dummyImage('cat quiz'), 'ಚೆನ್ನಾಗಿದೆ', 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ', 'easy', 'ಸಾಕು ಪ್ರಾಣಿಗಳು', 'mcq', '2026-07-10', 'Kannada', '', '', ''],
      [104, 'ಆನೆ ಯಾವ ಅಕ್ಷರದಿಂದ ಪ್ರಾರಂಭವಾಗುತ್ತದೆ?', 'ಆ', 'ಅ', 'ಕ', 'ಮ', 'ಸರಿಯಾದ ಅಕ್ಷರ ಆಯ್ಕೆಮಾಡಿ', '', dummyImage('elephant quiz'), 'ಸರಿಯಾಗಿದೆ', 'ಮತ್ತೊಮ್ಮೆ ನೋಡಿ', 'easy', 'ಸ್ವರಗಳು', 'mcq', '2026-07-10', 'Kannada', '', '', ''],
      [105, 'कोन जनावर म्याऊं करैत अछि?', 'बिलाइ', 'कुकुर', 'आम', 'अनार', 'सही उत्तर चुनू', '', dummyImage('cat quiz'), 'बहुत नीक', 'फेर कोशिश करू', 'easy', 'घरक जनावर', 'mcq', '2026-07-10', 'Maithili', '', '', ''],
      [106, 'आम कोन आखर सँ शुरू होइत अछि?', 'आ', 'अ', 'क', 'म', 'सही आखर चुनू', '', dummyImage('mango quiz'), 'सही जवाब', 'फेर देखू', 'easy', 'स्वर आखर', 'mcq', '2026-07-10', 'Maithili', '', '', ''],
    ],
  );

  await upsertRows(
    'phonics_category',
    ['id', 'title', 'image', 'created', 'language'],
    [
      [101, 'पाठ अभ्यास', dummyImage('Hindi phonics'), '2026-07-10', 'Hindi'],
      [102, 'ಉಚ್ಚಾರಣೆ ಅಭ್ಯಾಸ', dummyImage('Kannada phonics'), '2026-07-10', 'Kannada'],
      [103, 'उच्चारण अभ्यास', dummyImage('Maithili phonics'), '2026-07-10', 'Maithili'],
    ],
  );

  await upsertRows(
    'phonics_courses',
    ['id', 'title', 'image', 'created', 'language', 'subcategory'],
    [
      [101, 'अ ध्वनि', dummyImage('Hindi a sound'), '2026-07-10', 'Hindi', 'स्वर ध्वनि'],
      [102, 'क ध्वनि', dummyImage('Hindi ka sound'), '2026-07-10', 'Hindi', 'व्यंजन ध्वनि'],
      [103, 'ಅ ಧ್ವನಿ', dummyImage('Kannada a sound'), '2026-07-10', 'Kannada', 'ಸ್ವರ ಧ್ವನಿ'],
      [104, 'ಕ ಧ್ವನಿ', dummyImage('Kannada ka sound'), '2026-07-10', 'Kannada', 'ವ್ಯಂಜನ ಧ್ವನಿ'],
      [105, 'अ ध्वनि', dummyImage('Maithili a sound'), '2026-07-10', 'Maithili', 'स्वर ध्वनि'],
    ],
  );

  await upsertRows(
    'Phonics',
    [
      'id',
      'sentence',
      'word',
      'image',
      'sentence_sound',
      'word_audio',
      'coursename',
      'language',
      'category',
      'subcategory',
      'created',
      'title_image',
      'level',
    ],
    [
      [101, 'अ से अनार।', 'अनार', dummyImage('pomegranate'), sentenceAudio('hindi-a-anar'), wordAudio('hindi-anar'), 'अ ध्वनि', 'Hindi', 'पाठ अभ्यास', 'स्वर ध्वनि', '2026-07-10', dummyImage('Hindi a sound'), 'Nursery'],
      [102, 'क से कमल।', 'कमल', dummyImage('lotus'), sentenceAudio('hindi-ka-kamal'), wordAudio('hindi-kamal'), 'क ध्वनि', 'Hindi', 'पाठ अभ्यास', 'व्यंजन ध्वनि', '2026-07-10', dummyImage('Hindi ka sound'), 'LKG'],
      [103, 'ಅ ಅಕ್ಕಿ.', 'ಅಕ್ಕಿ', dummyImage('rice'), sentenceAudio('kannada-a-akki'), wordAudio('kannada-akki'), 'ಅ ಧ್ವನಿ', 'Kannada', 'ಉಚ್ಚಾರಣೆ ಅಭ್ಯಾಸ', 'ಸ್ವರ ಧ್ವನಿ', '2026-07-10', dummyImage('Kannada a sound'), 'Nursery'],
      [104, 'ಕ ಕಮಲ.', 'ಕಮಲ', dummyImage('lotus'), sentenceAudio('kannada-ka-kamala'), wordAudio('kannada-kamala'), 'ಕ ಧ್ವನಿ', 'Kannada', 'ಉಚ್ಚಾರಣೆ ಅಭ್ಯಾಸ', 'ವ್ಯಂಜನ ಧ್ವನಿ', '2026-07-10', dummyImage('Kannada ka sound'), 'LKG'],
      [105, 'अ सँ अनार।', 'अनार', dummyImage('pomegranate'), sentenceAudio('maithili-a-anar'), wordAudio('maithili-anar'), 'अ ध्वनि', 'Maithili', 'उच्चारण अभ्यास', 'स्वर ध्वनि', '2026-07-10', dummyImage('Maithili a sound'), 'Nursery'],
    ],
  );

  await upsertRows(
    'stories',
    [
      'id',
      'title',
      'text',
      'created',
      'language',
      'image',
      'audio',
      'title_image',
      'grade',
      'audio_text_map',
      'show_plan',
      'title_audio',
    ],
    [
      [101, 'छोटी रेल', 'छोटी रेल चली। बच्चे खुश हुए।', '2026-07-10', 'Hindi', dummyImage('toy train'), storyAudio('hindi-choti-rail'), dummyImage('toy train title'), 'Nursery', '{}', '0', storyAudio('hindi-choti-rail-title')],
      [102, 'आम का पेड़', 'पेड़ पर मीठे आम लगे। मीरा ने आम बाँटा।', '2026-07-10', 'Hindi', dummyImage('mango tree'), storyAudio('hindi-aam-ped'), dummyImage('mango tree title'), 'LKG', '{}', '1', storyAudio('hindi-aam-ped-title')],
      [103, 'ಚಿಕ್ಕ ರೈಲು', 'ಚಿಕ್ಕ ರೈಲು ಬಂತು. ಮಕ್ಕಳು ಕೈ ಬೀಸಿದರು.', '2026-07-10', 'Kannada', dummyImage('toy train'), storyAudio('kannada-chikka-railu'), dummyImage('toy train title'), 'Nursery', '{}', '0', storyAudio('kannada-chikka-railu-title')],
      [104, 'ಮಾವಿನ ಮರ', 'ಮರದಲ್ಲಿ ಸಿಹಿ ಮಾವು ಇತ್ತು. ಮೀನಾ ಹಣ್ಣು ಹಂಚಿದಳು.', '2026-07-10', 'Kannada', dummyImage('mango tree'), storyAudio('kannada-maavina-mara'), dummyImage('mango tree title'), 'LKG', '{}', '1', storyAudio('kannada-maavina-mara-title')],
      [105, 'छोट रेल', 'छोट रेल चलल। बच्चा सभ खुश भेल।', '2026-07-10', 'Maithili', dummyImage('toy train'), storyAudio('maithili-chhot-rail'), dummyImage('toy train title'), 'Nursery', '{}', '0', storyAudio('maithili-chhot-rail-title')],
    ],
  );
};

const initializeDatabase = async () => {
  const connection = await createBootstrapConnection();

  try {
    await connection.query(
      `CREATE DATABASE IF NOT EXISTS \`${databaseName}\`
       CHARACTER SET utf8mb4
       COLLATE utf8mb4_unicode_ci`,
    );
  } finally {
    await connection.end();
  }

  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      mobile_number VARCHAR(10) NOT NULL,
      full_name VARCHAR(120) NOT NULL,
      email VARCHAR(191) NULL,
      school VARCHAR(160) NULL,
      city VARCHAR(120) NULL,
      state VARCHAR(120) NULL,
      push_token TEXT NULL,
      mobile_verified_at DATETIME NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      UNIQUE KEY users_mobile_number_unique (mobile_number)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await ensureColumn('users', 'school', 'VARCHAR(160) NULL AFTER email');
  await ensureColumn('users', 'city', 'VARCHAR(120) NULL AFTER school');
  await ensureColumn('users', 'state', 'VARCHAR(120) NULL AFTER city');
  await ensureColumn(
    'users',
    'mobile_verified_at',
    'DATETIME NULL AFTER push_token',
  );

  await pool.query(`
    CREATE TABLE IF NOT EXISTS user_auth_identities (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      user_id BIGINT UNSIGNED NOT NULL,
      provider ENUM('google', 'apple') NOT NULL,
      provider_uid VARCHAR(191) NOT NULL,
      email VARCHAR(191) NULL,
      email_verified BOOLEAN NOT NULL DEFAULT FALSE,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      UNIQUE KEY user_auth_identities_provider_uid_unique (provider, provider_uid),
      KEY user_auth_identities_user_id_index (user_id),
      CONSTRAINT user_auth_identities_user_id_foreign
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS otp_verifications (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      user_id BIGINT UNSIGNED NOT NULL,
      otp VARCHAR(6) NOT NULL,
      expires_at DATETIME NOT NULL,
      is_verified BOOLEAN NOT NULL DEFAULT FALSE,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      KEY otp_verifications_user_id_index (user_id),
      KEY otp_verifications_lookup_index (user_id, otp, is_verified, created_at),
      CONSTRAINT otp_verifications_user_id_foreign
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await createLearningTables();
  await seedLearningData();
  await seedExpandedTestData();
  await seedMultilingualTestData();
  await seedAdminUser();
};

module.exports = initializeDatabase;
