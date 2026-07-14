const { pool } = require('../database/db');

const countByType = async ({ userId, activityDate }) => {
  const [rows] = await pool.execute(
    `SELECT activity_type, COUNT(*) AS total, COALESCE(SUM(estimated_minutes), 0) AS minutes
     FROM user_daily_learning_events
     WHERE user_id = ? AND activity_date = ?
     GROUP BY activity_type`,
    [userId, activityDate],
  );

  return rows;
};

const recordEvent = async ({
  userId,
  activityDate,
  activityType,
  activityKey,
  estimatedMinutes,
}) => {
  await pool.execute(
    `INSERT IGNORE INTO user_daily_learning_events (
       user_id, activity_date, activity_type, activity_key, estimated_minutes
     )
     VALUES (?, ?, ?, ?, ?)`,
    [userId, activityDate, activityType, activityKey, estimatedMinutes],
  );
};

module.exports = {
  countByType,
  recordEvent,
};
