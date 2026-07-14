const { pool } = require('../database/db');

const findProgress = async ({ userId, contentType, contentKey }) => {
  const [rows] = await pool.execute(
    `SELECT *
     FROM user_content_progress
     WHERE user_id = ? AND content_type = ? AND content_key = ?
     LIMIT 1`,
    [userId, contentType, contentKey],
  );

  return normalizeProgress(rows[0]);
};

const listItems = async ({ userId, contentType, contentKey }) => {
  const [rows] = await pool.execute(
    `SELECT item_key, position, is_correct, created_at, updated_at
     FROM user_content_progress_items
     WHERE user_id = ? AND content_type = ? AND content_key = ?
     ORDER BY position ASC, id ASC`,
    [userId, contentType, contentKey],
  );

  return rows.map((row) => ({
    item_key: row.item_key,
    position: Number(row.position || 0),
    is_correct: row.is_correct == null ? null : Boolean(row.is_correct),
    created_at: row.created_at,
    updated_at: row.updated_at,
  }));
};

const upsertProgress = async ({
  userId,
  contentType,
  contentKey,
  status = 'in_progress',
  position = 0,
  totalItems = 0,
  score = 0,
  metadata = null,
}) => {
  const completedAt = status === 'completed' ? new Date() : null;

  await pool.execute(
    `INSERT INTO user_content_progress (
       user_id, content_type, content_key, status, position, total_items,
       score, metadata, last_practiced_at, completed_at
     )
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?)
     ON DUPLICATE KEY UPDATE
       status = VALUES(status),
       position = VALUES(position),
       total_items = VALUES(total_items),
       score = VALUES(score),
       metadata = VALUES(metadata),
       last_practiced_at = NOW(),
       completed_at = VALUES(completed_at),
       updated_at = CURRENT_TIMESTAMP`,
    [
      userId,
      contentType,
      contentKey,
      status,
      position,
      totalItems,
      score,
      metadata == null ? null : JSON.stringify(metadata),
      completedAt,
    ],
  );
};

const recordItem = async ({
  userId,
  contentType,
  contentKey,
  itemKey,
  position,
  isCorrect = null,
}) => {
  await pool.execute(
    `INSERT INTO user_content_progress_items (
       user_id, content_type, content_key, item_key, position, is_correct
     )
     VALUES (?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       position = VALUES(position),
       is_correct = COALESCE(VALUES(is_correct), is_correct),
       updated_at = CURRENT_TIMESTAMP`,
    [userId, contentType, contentKey, itemKey, position, isCorrect],
  );
};

const restartSession = async ({ userId, contentType, contentKey }) => {
  await pool.execute(
    `INSERT INTO user_content_progress (
       user_id, content_type, content_key, status, position, total_items,
       score, metadata, last_practiced_at
     )
     VALUES (?, ?, ?, 'in_progress', 0, 0, 0, ?, NOW())
     ON DUPLICATE KEY UPDATE
       status = 'in_progress',
       position = 0,
       score = 0,
       metadata = VALUES(metadata),
       last_practiced_at = NOW(),
       completed_at = NULL,
       updated_at = CURRENT_TIMESTAMP`,
    [userId, contentType, contentKey, JSON.stringify({ restart_session: true })],
  );
};

const normalizeProgress = (row) => {
  if (!row) return null;

  let metadata = {};
  try {
    metadata = row.metadata ? JSON.parse(row.metadata) : {};
  } catch (_) {
    metadata = {};
  }

  return {
    content_type: row.content_type,
    content_key: row.content_key,
    status: row.status,
    position: Number(row.position || 0),
    total_items: Number(row.total_items || 0),
    score: Number(row.score || 0),
    metadata,
    last_practiced_at: row.last_practiced_at,
    completed_at: row.completed_at,
  };
};

module.exports = {
  findProgress,
  listItems,
  upsertProgress,
  recordItem,
  restartSession,
};
