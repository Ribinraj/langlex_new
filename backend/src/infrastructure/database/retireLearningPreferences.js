// Preserve historical values but let existing databases accept setup writes
// that no longer supply these retired preferences. Fresh installs omit them.
module.exports = async (pool, database) => {
  const [columns] = await pool.execute(
    `SELECT COLUMN_NAME, IS_NULLABLE, COLUMN_DEFAULT
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'user_learning_setups'
       AND COLUMN_NAME IN ('age_group', 'daily_goal_minutes')`,
    [database],
  );
  const definitions = {
    age_group: 'VARCHAR(80) NULL DEFAULT NULL',
    daily_goal_minutes: 'INT UNSIGNED NULL DEFAULT NULL',
  };
  for (const column of columns) {
    const definition = definitions[column.COLUMN_NAME];
    if (definition && (column.IS_NULLABLE !== 'YES' || column.COLUMN_DEFAULT != null)) {
      await pool.query(
        `ALTER TABLE user_learning_setups MODIFY COLUMN \`${column.COLUMN_NAME}\` ${definition}`,
      );
    }
  }

  // Update only the old built-in reminder, including reminders already saved.
  await pool.execute(
    `UPDATE notifications SET title = ?, body = ?
     WHERE type = 'setup' AND title = ? AND body = ?`,
    [
      'Set up your learning',
      'Choose your language and student level to personalize learning.',
      'Set your daily goal',
      'A short daily goal helps children build a steady learning habit.',
    ],
  );
};
