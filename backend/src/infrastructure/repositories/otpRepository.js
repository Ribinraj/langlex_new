const { pool } = require('../database/db');

const create = async ({ userId, otp, expiresAt }) => {
  await pool.execute(
    `UPDATE otp_verifications
     SET is_verified = TRUE
     WHERE user_id = ? AND is_verified = FALSE`,
    [userId],
  );

  const [result] = await pool.execute(
    `INSERT INTO otp_verifications (user_id, otp, expires_at)
     VALUES (?, ?, ?)`,
    [userId, otp, expiresAt],
  );

  return result.insertId;
};

const findLatestActive = async (userId, otp) => {
  const [rows] = await pool.execute(
    `SELECT id, user_id, otp, expires_at, is_verified, created_at
     FROM otp_verifications
     WHERE user_id = ? AND otp = ? AND is_verified = FALSE
     ORDER BY created_at DESC
     LIMIT 1`,
    [userId, otp],
  );

  return rows[0] || null;
};

const markVerified = async (id) => {
  await pool.execute(
    `UPDATE otp_verifications
     SET is_verified = TRUE
     WHERE id = ?`,
    [id],
  );
};

module.exports = {
  create,
  findLatestActive,
  markVerified,
};
