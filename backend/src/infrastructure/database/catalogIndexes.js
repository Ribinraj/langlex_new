const indexes = [
  ['Content', 'content_language_id', 'language, id'],
  ['Content', 'content_course_language_id', 'course, language, id'],
  ['Alphabets', 'alphabets_language_id', 'language, id'],
  ['quizz', 'quizz_language_id', 'Language, id'],
  ['Phonics', 'phonics_language_id', 'language, id'],
  ['stories', 'stories_language_id', 'language, id'],
  ['notifications', 'notifications_user_created_id', 'user_id, created_at, id'],
];
module.exports = async (pool) => {
  for (const [table, name, columns] of indexes) {
    const [found] = await pool.query('SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=? AND INDEX_NAME=? LIMIT 1', [table, name]);
    if (!found.length) await pool.query(`ALTER TABLE \`${table}\` ADD INDEX \`${name}\` (${columns})`);
  }
};
