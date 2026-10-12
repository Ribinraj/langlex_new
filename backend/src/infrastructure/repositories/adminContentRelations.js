const { pool } = require('../database/db');
const ApiError = require('../../shared/errors/apiError');
const relations = {
  courses: [['Content','course']],
  categories: [['subcategories','p_cat'],['Content','category'],['Alphabets','category'],['Phonics','category']],
  subcategories: [['Content','subcategory'],['Alphabets','subcategory'],['Phonics','subcategory']],
};
async function transaction(work) {
  const conn = await pool.getConnection();
  try { await conn.beginTransaction(); const value = await work(conn); await conn.commit(); return value; }
  catch (error) { await conn.rollback(); throw error; } finally { conn.release(); }
}
async function update(definition, resource, id, payload, valueForColumn) {
  return transaction(async conn => {
    const [[old]] = await conn.query(`SELECT * FROM \`${definition.table}\` WHERE id=? FOR UPDATE`, [id]);
    if (!old) return false;
    const next = { ...old, ...payload };
    const refs = relations[resource] || [];
    if (refs.length && (next.title !== old.title || next.language !== old.language)) {
      // A shared name cannot safely identify which dependent rows should move.
      const [conflicts] = await conn.query(`SELECT id FROM \`${definition.table}\` WHERE id<>? AND ((title=? AND language=?) OR (title=? AND language=?)) LIMIT 1 FOR UPDATE`, [id,old.title,old.language,next.title,next.language]);
      if (conflicts.length) throw new ApiError('This name is already shared by another record. Resolve the duplicate before renaming or moving it.',409);
      if (resource === 'courses') {
        const [words] = await conn.query('SELECT id FROM Content WHERE course=? AND language=? AND NOT (course=? AND language=?) LIMIT 1 FOR UPDATE',[next.title,next.language,old.title,old.language]);
        if (words.length) throw new ApiError('The destination already contains a learning activity. Choose a different course name.',409);
      }
      for (const [table, field] of refs) {
        await conn.query(`UPDATE \`${table}\` SET \`${field}\`=?, language=? WHERE \`${field}\`=? AND language=?`,[next.title,next.language,old.title,old.language]);
      }
    }
    const columns = definition.columns.filter(column => Object.hasOwn(payload,column));
    if (columns.length) await conn.query(`UPDATE \`${definition.table}\` SET ${columns.map(column=>`\`${column}\`=?`).join(',')} WHERE id=?`,[...columns.map(column=>valueForColumn(definition,column,payload[column])),id]);
    return true;
  });
}
async function remove(definition, resource, id) {
  return transaction(async conn => {
    const [[old]] = await conn.query(`SELECT * FROM \`${definition.table}\` WHERE id=? FOR UPDATE`, [id]);
    if (!old) return false;
    for (const [table, field] of relations[resource] || []) {
      const [[row]] = await conn.query(`SELECT COUNT(*) AS total FROM \`${table}\` WHERE \`${field}\`=? AND language=?`,[old.title,old.language]);
      if (row.total) throw new ApiError('This record still has linked learning content. Move or remove that content before deleting it.',409);
    }
    if (resource === 'plans') {
      const [[row]] = await conn.query('SELECT (SELECT COUNT(*) FROM user_subscriptions WHERE plan_id=?) + (SELECT COUNT(*) FROM payment_orders WHERE plan_id=?) AS total',[id,id]);
      if (row.total) throw new ApiError('This plan has payment or subscription history and cannot be deleted.',409);
    }
    const [result] = await conn.query(`DELETE FROM \`${definition.table}\` WHERE id=?`,[id]);
    return result.affectedRows > 0;
  });
}
module.exports = { update, remove };
