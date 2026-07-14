const { pool } = require('../database/db');

const columns = `
  user_id, child_name, age_group, primary_language, learning_language,
  level, interests, daily_goal_minutes, plan_id, created_at, updated_at
`;

const normalize = (row) => {
  if (!row) return null;

  let interests = [];
  try {
    const parsed = JSON.parse(row.interests || '[]');
    interests = Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    interests = [];
  }

  return {
    ...row,
    interests,
    daily_goal_minutes: Number(row.daily_goal_minutes || 15),
    plan_id: row.plan_id == null ? null : Number(row.plan_id),
  };
};

const findByUserId = async (userId) => {
  const [rows] = await pool.execute(
    `SELECT ${columns}
     FROM user_learning_setups
     WHERE user_id = ?
     LIMIT 1`,
    [userId],
  );

  return normalize(rows[0]);
};

const upsert = async (userId, setup) => {
  const interests = JSON.stringify(setup.interests || []);

  await pool.execute(
    `INSERT INTO user_learning_setups (
       user_id, child_name, age_group, primary_language, learning_language,
       level, interests, daily_goal_minutes, plan_id
     )
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       child_name = VALUES(child_name),
       age_group = VALUES(age_group),
       primary_language = VALUES(primary_language),
       learning_language = VALUES(learning_language),
       level = VALUES(level),
       interests = VALUES(interests),
       daily_goal_minutes = VALUES(daily_goal_minutes),
       plan_id = VALUES(plan_id),
       updated_at = CURRENT_TIMESTAMP`,
    [
      userId,
      setup.child_name || null,
      setup.age_group,
      setup.primary_language,
      setup.learning_language,
      setup.level,
      interests,
      setup.daily_goal_minutes,
      setup.plan_id || null,
    ],
  );

  return findByUserId(userId);
};

module.exports = {
  findByUserId,
  upsert,
};
