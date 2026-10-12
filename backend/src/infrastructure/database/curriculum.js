// Additive metadata only: original SQL tables and item IDs remain intact.
module.exports = async (pool) => {
  await pool.query(`CREATE TABLE IF NOT EXISTS learning_topics (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    resource VARCHAR(20) NOT NULL,
    source_key CHAR(64) NOT NULL UNIQUE,
    legacy_id BIGINT UNSIGNED NULL,
    title VARCHAR(255) NOT NULL,
    language VARCHAR(255) NOT NULL,
    group_name VARCHAR(255) NOT NULL DEFAULT '',
    legacy_grade VARCHAR(255) NOT NULL DEFAULT '',
    standards JSON NOT NULL,
    image TEXT NOT NULL,
    audio TEXT NOT NULL,
    access VARCHAR(20) NOT NULL DEFAULT 'Free',
    revision INT UNSIGNED NOT NULL DEFAULT 1,
    KEY topic_resource(resource)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`);
  await pool.query(`CREATE TABLE IF NOT EXISTS learning_topic_items (
    resource VARCHAR(20) NOT NULL,
    item_id BIGINT UNSIGNED NOT NULL,
    topic_id BIGINT UNSIGNED NOT NULL,
    standards JSON NULL,
    PRIMARY KEY(resource,item_id),
    KEY topic_items(topic_id),
    FOREIGN KEY(topic_id) REFERENCES learning_topics(id) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`);
  await require('../repositories/curriculumRepository').backfill();
};
