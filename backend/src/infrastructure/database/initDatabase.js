const env = require('../config/env');
const { createBootstrapConnection, pool } = require('./db');
const { hashPassword } = require('../../shared/utils/password');
const { importOriginalContent } = require('./originalContent');

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
      primary_language VARCHAR(80) NOT NULL,
      learning_language VARCHAR(80) NOT NULL,
      level VARCHAR(80) NOT NULL,
      interests JSON NULL,
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
  await require('./retireLearningPreferences')(pool, env.db.database);
  await ensureColumn('user_learning_setups', 'selected_languages', 'JSON NULL');
  await importOriginalContent(pool);
  await require('./catalogIndexes')(pool);
  await require('./quizTopicSettings')(pool);
  await require('./learningProgress')(pool);
  await require('./adminOperations')(pool, ensureColumn);
  await require('./curriculum')(pool);
  await seedAdminUser();
};

module.exports = initializeDatabase;
