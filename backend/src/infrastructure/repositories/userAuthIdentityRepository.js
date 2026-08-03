const { pool } = require('../database/db');

const findByProviderUid = async ({ provider, providerUid }) => {
  const [rows] = await pool.execute(
    `SELECT id, user_id, provider, provider_uid, email, email_verified, created_at, updated_at
     FROM user_auth_identities
     WHERE provider = ? AND provider_uid = ?
     LIMIT 1`,
    [provider, providerUid],
  );
  return rows[0] || null;
};

const create = async ({
  userId,
  provider,
  providerUid,
  email = null,
  emailVerified = false,
}) => {
  const [result] = await pool.execute(
    `INSERT INTO user_auth_identities
       (user_id, provider, provider_uid, email, email_verified)
     VALUES (?, ?, ?, ?, ?)`,
    [userId, provider, providerUid, email || null, Boolean(emailVerified)],
  );

  const [rows] = await pool.execute(
    `SELECT id, user_id, provider, provider_uid, email, email_verified, created_at, updated_at
     FROM user_auth_identities
     WHERE id = ?
     LIMIT 1`,
    [result.insertId],
  );

  return rows[0] || null;
};

module.exports = {
  findByProviderUid,
  create,
};
