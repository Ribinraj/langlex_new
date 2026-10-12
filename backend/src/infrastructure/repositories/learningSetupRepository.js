const { pool } = require('../database/db');

const columns = `
  user_id, child_name, primary_language, learning_language,
  level, interests, selected_languages, plan_id, created_at, updated_at
`;

const normalize = (row) => {
  if (!row) return null;

  let interests = [];
  try {
    const parsed = Array.isArray(row.interests) ? row.interests : JSON.parse(row.interests || '[]');
    interests = Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    interests = [];
  }

  return {
    ...row,
    interests,
    selected_languages: Array.isArray(row.selected_languages) ? row.selected_languages : JSON.parse(row.selected_languages || '[]'),
    active_language: row.learning_language,
    plan_id: row.plan_id == null ? null : Number(row.plan_id),
  };
};

const findByUserId = async (userId, executor = pool) => {
  const [rows] = await executor.execute(
    `SELECT ${columns}
     FROM user_learning_setups
     WHERE user_id = ?
     LIMIT 1`,
    [userId],
  );

  return normalize(rows[0]);
};

const upsert = async (userId, setup, executor = pool) => {
  const interests = JSON.stringify(setup.interests || []);

  await executor.execute(
    `INSERT INTO user_learning_setups (
       user_id, child_name, primary_language, learning_language,
       level, interests, selected_languages, plan_id
     )
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       child_name = VALUES(child_name),
       primary_language = VALUES(primary_language),
       learning_language = VALUES(learning_language),
       level = VALUES(level),
       interests = VALUES(interests),
       selected_languages = VALUES(selected_languages),
       plan_id = VALUES(plan_id),
       updated_at = CURRENT_TIMESTAMP`,
    [
      userId,
      setup.child_name || null,
      setup.primary_language,
      setup.learning_language,
      setup.level,
      interests,
      JSON.stringify(setup.selected_languages),
      setup.plan_id || null,
    ],
  );

  return findByUserId(userId, executor);
};

// Lock the account even when its setup row does not exist yet.
const saveLocked = async (userId, buildSetup) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    await connection.execute('SELECT id FROM users WHERE id = ? FOR UPDATE', [userId]);
    const existing = await findByUserId(userId, connection);
    const result = await upsert(userId, await buildSetup(existing), connection);
    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

module.exports = {
  saveLocked,
  findByUserId,
  upsert,
};
