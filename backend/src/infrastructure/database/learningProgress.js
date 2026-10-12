// Additive migration: keep earned work separate from replayable practice sessions.
module.exports = async function migrateLearningProgress(pool) {
  await pool.query(`CREATE TABLE IF NOT EXISTS user_learning_completions (
    user_id BIGINT UNSIGNED NOT NULL,
    content_type VARCHAR(40) NOT NULL,
    item_id BIGINT UNSIGNED NOT NULL,
    best_correct BOOLEAN NULL,
    first_completed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_practiced_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, content_type, item_id),
    CONSTRAINT learning_completions_user_fk FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`);
  await pool.query(`CREATE TABLE IF NOT EXISTS user_progress_events (
    user_id BIGINT UNSIGNED NOT NULL,
    event_id VARCHAR(80) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, event_id),
    CONSTRAINT progress_events_user_fk FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`);
  await pool.query(`CREATE TABLE IF NOT EXISTS learning_progress_migrations (
    version VARCHAR(80) NOT NULL PRIMARY KEY, applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
  ) ENGINE=InnoDB`);
  const connection = await pool.getConnection();
  try {
    const [[lock]] = await connection.query("SELECT GET_LOCK('langlex-progress-earned-v1', 30) AS acquired");
    if (Number(lock.acquired) !== 1) throw new Error('Could not acquire progress migration lock');
    const [done] = await connection.query("SELECT version FROM learning_progress_migrations WHERE version='earned-items-v1'");
    if (done.length) return;
    await connection.beginTransaction();
    // Only real item rows are evidence of progress. Never trust the old last-card status.
    for (const [type, prefix, table] of [['course', 'content-', 'Content'], ['quiz', 'quiz-', 'quizz'], ['phonics', 'phonics-', 'Phonics']]) {
      await connection.query(`INSERT IGNORE INTO user_learning_completions
        (user_id, content_type, item_id, best_correct, first_completed_at, last_practiced_at)
        SELECT p.user_id, ?, c.id, MAX(p.is_correct), MIN(p.created_at), MAX(p.updated_at)
        FROM user_content_progress_items p JOIN \`${table}\` c ON p.item_key=CONCAT(?, c.id)
        WHERE p.content_type=? GROUP BY p.user_id, c.id`, [type, prefix, type]);
    }
    // Finishing a legacy story meant reading its complete group of passages.
    await connection.query(`INSERT IGNORE INTO user_learning_completions
      (user_id, content_type, item_id, first_completed_at, last_practiced_at)
      SELECT p.user_id, 'story', s.id, COALESCE(p.completed_at,p.updated_at), p.updated_at
      FROM user_content_progress p JOIN stories first ON p.content_key=CONCAT('story-',first.id)
      JOIN stories s ON s.title=first.title AND s.language=first.language AND s.grade=first.grade
      WHERE p.content_type='story' AND p.status='completed'`);
    await connection.query("INSERT INTO learning_progress_migrations (version) VALUES ('earned-items-v1')");
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    await connection.query("SELECT RELEASE_LOCK('langlex-progress-earned-v1')");
    connection.release();
  }
};
