const { pool, withTransaction } = require('../../infrastructure/database/db');
const clean = (value) => {
  if (value instanceof Date) return value.toISOString();
  if (Array.isArray(value)) return value.map(clean);
  if (value && typeof value === 'object')
    return Object.fromEntries(
      Object.entries(value)
        .filter(([key]) => !/password|token|otp|stack/i.test(key))
        .map(([key, val]) => [key, clean(val)]),
    );
  return value;
};
const record = async (
  admin,
  { action, entity, id, before = null, after = null, reason = null },
) => {
  await pool.execute(
    `INSERT INTO admin_audit_log
    (admin_id,admin_name,admin_email,action,entity,entity_id,reason,before_data,after_data)
    VALUES (?,?,?,?,?,?,?,?,?)`,
    [
      admin.id,
      admin.full_name,
      admin.email,
      action,
      entity,
      id == null ? null : String(id),
      reason,
      JSON.stringify(clean(before)),
      JSON.stringify(clean(after)),
    ],
  );
};
const mutate = (admin, info, read, work) =>
  withTransaction(async () => {
    const tables = {
      users: 'users',
      learning_topics: 'learning_topics',
      subscriptions: 'user_subscriptions',
      ...Object.fromEntries(
        Object.entries(
          require('../../infrastructure/repositories/adminCatalogRepository')
            .resources,
        ).map(([key, value]) => [key, value.table]),
      ),
    };
    if (info.id && Object.hasOwn(tables, info.entity))
      await pool.query(
        `SELECT id FROM \`${tables[info.entity]}\` WHERE id=? FOR UPDATE`,
        [info.id],
      );
    const before = read ? await read() : null;
    const result = await work();
    const after =
      info.action === 'delete' ? null : read ? await read() : result;
    await record(admin, {
      ...info,
      id: info.id ?? result?.id ?? result?.item?.id,
      before,
      after: info.action === 'delete' ? null : (after ?? result),
    });
    return result;
  });
const list = async ({ page = 1, limit = 25, search = '' }) => {
  const where = search
    ? 'WHERE CONCAT_WS(" ",admin_name,admin_email,action,entity,entity_id,reason) LIKE ?'
    : '';
  const params = search ? [`%${search}%`] : [];
  const [[{ total }]] = await pool.execute(
    `SELECT COUNT(*) total FROM admin_audit_log ${where}`,
    params,
  );
  const [items] = await pool.execute(
    `SELECT * FROM admin_audit_log ${where} ORDER BY id DESC LIMIT ${Number(limit)} OFFSET ${(page - 1) * limit}`,
    params,
  );
  return { items, total, page, limit };
};
module.exports = { record, mutate, list, clean };
