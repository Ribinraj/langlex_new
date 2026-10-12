const { pool } = require('../database/db');

const publicColumns =
  'id, is_blocked, mobile_number, full_name, email, school, city, state, push_token, mobile_verified_at, created_at, updated_at';

const findByMobileNumber = async (mobileNumber) => {
  const [rows] = await pool.execute(
    `SELECT ${publicColumns} FROM users WHERE mobile_number = ? LIMIT 1`,
    [mobileNumber],
  );
  return rows[0] || null;
};

const findById = async (id) => {
  const [rows] = await pool.execute(
    `SELECT ${publicColumns} FROM users WHERE id = ? LIMIT 1`,
    [id],
  );
  return rows[0] || null;
};

const create = async ({
  mobile_number,
  full_name,
  email = null,
  school,
  city,
  state,
}) => {
  const [result] = await pool.execute(
    `INSERT INTO users (mobile_number, full_name, email, school, city, state)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [mobile_number, full_name, email || null, school, city, state],
  );

  return findById(result.insertId);
};

const markMobileVerified = async (id) => {
  await pool.execute(
    `UPDATE users
     SET mobile_verified_at = COALESCE(mobile_verified_at, CURRENT_TIMESTAMP),
         updated_at = CURRENT_TIMESTAMP
     WHERE id = ?`,
    [id],
  );
  return findById(id);
};

const updatePushToken = async (id, pushToken) => {
  await pool.execute(
    `UPDATE users
     SET push_token = ?, updated_at = CURRENT_TIMESTAMP
     WHERE id = ?`,
    [pushToken || null, id],
  );
  return findById(id);
};

const updateProfile = async (
  id,
  { full_name, email = null, school = null, city = null, state = null },
) => {
  await pool.execute(
    `UPDATE users
     SET full_name = ?,
         email = ?,
         school = ?,
         city = ?,
         state = ?,
         updated_at = CURRENT_TIMESTAMP
     WHERE id = ?`,
    [full_name, email || null, school || null, city || null, state || null, id],
  );

  return findById(id);
};

const clearPushToken = async (id) => {
  await pool.execute(
    `UPDATE users
     SET push_token = NULL, updated_at = CURRENT_TIMESTAMP
     WHERE id = ?`,
    [id],
  );
};

module.exports = {
  findByMobileNumber,
  findById,
  create,
  markMobileVerified,
  updatePushToken,
  updateProfile,
  clearPushToken,
};
