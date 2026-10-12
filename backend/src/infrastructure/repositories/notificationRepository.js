const { pool } = require('../database/db');

const notificationColumns = `
  id, user_id, title, body, type, data, is_read, created_at, read_at
`;

const create = async ({
  userId,
  title,
  body,
  type = 'info',
  data = {},
}) => {
  const [result] = await pool.execute(
    `INSERT INTO notifications (user_id, title, body, type, data)
     VALUES (?, ?, ?, ?, ?)`,
    [userId, title, body, type, JSON.stringify(data)],
  );

  return findById({ userId, notificationId: result.insertId });
};

const countForUser = async (userId) => {
  const [rows] = await pool.execute(
    `SELECT COUNT(*) AS count
     FROM notifications
     WHERE user_id = ?`,
    [userId],
  );
  return Number(rows[0]?.count || 0);
};

const unreadCount = async (userId) => {
  const [rows] = await pool.execute(
    `SELECT COUNT(*) AS count
     FROM notifications
     WHERE user_id = ? AND is_read = FALSE`,
    [userId],
  );
  return Number(rows[0]?.count || 0);
};

const listForUser = async ({ userId, page = 1, limit = 20 }) => {
  const paging = require('../../shared/utils/pagination').pagination({ page, limit });
  const [rows] = await pool.query(
    `SELECT ${notificationColumns}
     FROM notifications
     WHERE user_id = ?
     ORDER BY created_at DESC, id DESC
     LIMIT ? OFFSET ?`,
    [userId, paging.limit, paging.offset],
  );
  return rows;
};

const findById = async ({ userId, notificationId }) => {
  const [rows] = await pool.execute(
    `SELECT ${notificationColumns}
     FROM notifications
     WHERE id = ? AND user_id = ?
     LIMIT 1`,
    [notificationId, userId],
  );
  return rows[0] || null;
};

const markRead = async ({ userId, notificationId }) => {
  await pool.execute(
    `UPDATE notifications
     SET is_read = TRUE, read_at = COALESCE(read_at, NOW())
     WHERE id = ? AND user_id = ?`,
    [notificationId, userId],
  );
  return findById({ userId, notificationId });
};

const markAllRead = async (userId) => {
  const [result] = await pool.execute(
    `UPDATE notifications
     SET is_read = TRUE, read_at = COALESCE(read_at, NOW())
     WHERE user_id = ? AND is_read = FALSE`,
    [userId],
  );
  return result.affectedRows;
};

const listTargets = async ({ userId } = {}) => {
  const params = [];
  let whereSql = '';

  if (userId) {
    whereSql = 'WHERE id = ?';
    params.push(userId);
  }

  const [rows] = await pool.execute(
    `SELECT id, push_token
     FROM users
     ${whereSql}
     ORDER BY id`,
    params,
  );
  return rows;
};

const clearPushToken = async (pushToken) => {
  const [result] = await pool.execute(
    `UPDATE users
     SET push_token = NULL, updated_at = CURRENT_TIMESTAMP
     WHERE push_token = ?`,
    [pushToken],
  );
  return result.affectedRows;
};

module.exports = {
  create,
  countForUser,
  unreadCount,
  listForUser,
  findById,
  markRead,
  markAllRead,
  listTargets,
  clearPushToken,
};
