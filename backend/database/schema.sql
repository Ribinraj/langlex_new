CREATE DATABASE IF NOT EXISTS langlex_auth
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE langlex_auth;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  mobile_number VARCHAR(10) NOT NULL,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(191) NULL,
  school VARCHAR(160) NULL,
  city VARCHAR(120) NULL,
  state VARCHAR(120) NULL,
  push_token TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY users_mobile_number_unique (mobile_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS categories (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  created VARCHAR(255) NOT NULL,
  image VARCHAR(255) NOT NULL,
  language VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS subcategories (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  created VARCHAR(255) NOT NULL,
  image VARCHAR(255) NOT NULL,
  p_cat VARCHAR(255) NOT NULL,
  language VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS courses (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  created VARCHAR(255) NOT NULL,
  image VARCHAR(255) NOT NULL,
  language VARCHAR(255) NOT NULL,
  show_plan VARCHAR(255) NOT NULL DEFAULT '0',
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS phonics_category (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  image VARCHAR(255) NOT NULL,
  created VARCHAR(255) NOT NULL,
  language VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS phonics_courses (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  image VARCHAR(255) NOT NULL,
  created VARCHAR(255) NOT NULL,
  language VARCHAR(255) NOT NULL,
  subcategory VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS subsc_plans (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(255) NOT NULL,
  amount VARCHAR(255) NOT NULL,
  permission LONGTEXT NOT NULL,
  plan_timeperiod VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
