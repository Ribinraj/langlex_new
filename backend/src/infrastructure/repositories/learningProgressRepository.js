const { pool } = require('../database/db');
async function completions(userId, executor = pool) {
  return (await executor.execute('SELECT content_type,item_id,best_correct,last_practiced_at FROM user_learning_completions WHERE user_id=?', [userId]))[0];
}
async function session(userId, type, key, executor = pool) {
  const [rows] = await executor.execute('SELECT * FROM user_content_progress WHERE user_id=? AND content_type=? AND content_key=?', [userId, type, key]);
  const [items] = await executor.execute('SELECT item_key,position,is_correct FROM user_content_progress_items WHERE user_id=? AND content_type=? AND content_key=?', [userId, type, key]);
  const row = rows[0];
  let metadata = {};
  try { metadata = typeof row?.metadata === 'string' ? JSON.parse(row.metadata) : row?.metadata || {}; } catch (_) { /* legacy JSON */ }
  return { ...row, metadata, items };
}
async function transaction(userId, work) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    await connection.execute('SELECT id FROM users WHERE id=? FOR UPDATE', [userId]);
    const result = await work(connection);
    await connection.commit();
    return result;
  } catch (error) { await connection.rollback(); throw error; }
  finally { connection.release(); }
}
async function claimEvent(userId, eventId, connection) {
  if (!eventId) return true; // compatibility with the installed client
  const [result] = await connection.execute('INSERT IGNORE INTO user_progress_events (user_id,event_id) VALUES (?,?)', [userId, eventId]);
  return result.affectedRows > 0;
}
async function earn(userId, type, id, correct, connection) {
  await connection.execute(`INSERT INTO user_learning_completions (user_id,content_type,item_id,best_correct)
    VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE
    best_correct=IF(VALUES(best_correct) IS NULL,best_correct,GREATEST(COALESCE(best_correct,0),VALUES(best_correct))),
    last_practiced_at=NOW()`, [userId, type, id, correct]);
}
async function record(userId, type, key, itemKey, position, correct, connection) {
  await connection.execute(`INSERT INTO user_content_progress_items (user_id,content_type,content_key,item_key,position,is_correct)
    VALUES (?,?,?,?,?,?) ON DUPLICATE KEY UPDATE position=VALUES(position),is_correct=COALESCE(VALUES(is_correct),is_correct),updated_at=CURRENT_TIMESTAMP`,
  [userId,type,key,itemKey,position,correct]);
}
async function save(userId, topic, position, status, score, metadata, connection) {
  await connection.execute(`INSERT INTO user_content_progress (user_id,content_type,content_key,position,total_items,status,score,metadata,last_practiced_at,completed_at)
    VALUES (?,?,?,?,?,?,?,?,NOW(),?) ON DUPLICATE KEY UPDATE position=VALUES(position),total_items=VALUES(total_items),status=VALUES(status),score=VALUES(score),metadata=VALUES(metadata),last_practiced_at=NOW(),completed_at=VALUES(completed_at),updated_at=CURRENT_TIMESTAMP`,
  [userId,topic.content_type,topic.content_key,position,topic.items.length,status,score,JSON.stringify(metadata),status === 'completed' ? new Date() : null]);
}
module.exports = { completions, session, transaction, claimEvent, earn, record, save };
