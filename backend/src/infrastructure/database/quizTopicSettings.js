// Access is owned by a topic, never copied onto individual questions.
module.exports = async (pool) => {
  await pool.query(`CREATE TABLE IF NOT EXISTS quiz_topic_settings (
    language VARCHAR(100) NOT NULL,
    topic VARCHAR(255) NOT NULL,
    show_plan ENUM('Free','Premium') NOT NULL DEFAULT 'Free',
    PRIMARY KEY (language,topic)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`);
  await pool.query("INSERT IGNORE INTO quiz_topic_settings(language,topic,show_plan) SELECT DISTINCT Language,topic,'Free' FROM quizz");
};
