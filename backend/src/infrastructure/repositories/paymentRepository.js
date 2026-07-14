const { pool } = require('../database/db');

const findPlanById = async (planId) => {
  const [rows] = await pool.execute(
    `SELECT id, name, type, amount, permission, plan_timeperiod
     FROM subsc_plans
     WHERE id = ?
     LIMIT 1`,
    [planId],
  );
  return rows[0] || null;
};

const createOrder = async ({ userId, plan, providerOrderId, metadata = {} }) => {
  const [result] = await pool.execute(
    `INSERT INTO payment_orders
      (user_id, plan_id, provider, provider_order_id, amount, currency, status, metadata)
     VALUES (?, ?, 'dummy', ?, ?, 'INR', 'created', ?)`,
    [userId, plan.id, providerOrderId, plan.amount, JSON.stringify(metadata)],
  );

  return findOrderById(result.insertId);
};

const findOrderById = async (orderId) => {
  const [rows] = await pool.execute(
    `SELECT id, user_id, plan_id, provider, provider_order_id, amount, currency,
            status, metadata, created_at, updated_at
     FROM payment_orders
     WHERE id = ?
     LIMIT 1`,
    [orderId],
  );
  return rows[0] || null;
};

const markOrderPaid = async ({ orderId, metadata = {} }) => {
  await pool.execute(
    `UPDATE payment_orders
     SET status = 'paid', metadata = ?, updated_at = CURRENT_TIMESTAMP
     WHERE id = ?`,
    [JSON.stringify(metadata), orderId],
  );
  return findOrderById(orderId);
};

const createSubscription = async ({
  userId,
  planId,
  paymentOrderId,
  startedAt,
  expiresAt,
}) => {
  await pool.execute(
    `UPDATE user_subscriptions
     SET status = 'expired', updated_at = CURRENT_TIMESTAMP
     WHERE user_id = ? AND status = 'active'`,
    [userId],
  );

  const [result] = await pool.execute(
    `INSERT INTO user_subscriptions
      (user_id, plan_id, payment_order_id, status, started_at, expires_at)
     VALUES (?, ?, ?, 'active', ?, ?)`,
    [userId, planId, paymentOrderId, startedAt, expiresAt],
  );

  return findSubscriptionById(result.insertId);
};

const findSubscriptionById = async (subscriptionId) => {
  const [rows] = await pool.execute(
    `SELECT us.id, us.user_id, us.plan_id, us.payment_order_id, us.status,
            us.started_at, us.expires_at, sp.name AS plan_name, sp.type,
            sp.amount, sp.permission, sp.plan_timeperiod
     FROM user_subscriptions us
     JOIN subsc_plans sp ON sp.id = us.plan_id
     WHERE us.id = ?
     LIMIT 1`,
    [subscriptionId],
  );
  return rows[0] || null;
};

const findActiveSubscriptionByUserId = async (userId) => {
  const [rows] = await pool.execute(
    `SELECT us.id, us.user_id, us.plan_id, us.payment_order_id, us.status,
            us.started_at, us.expires_at, sp.name AS plan_name, sp.type,
            sp.amount, sp.permission, sp.plan_timeperiod
     FROM user_subscriptions us
     JOIN subsc_plans sp ON sp.id = us.plan_id
     WHERE us.user_id = ?
       AND us.status = 'active'
       AND (us.expires_at IS NULL OR us.expires_at > NOW())
     ORDER BY us.created_at DESC
     LIMIT 1`,
    [userId],
  );
  return rows[0] || null;
};

module.exports = {
  findPlanById,
  createOrder,
  findOrderById,
  markOrderPaid,
  createSubscription,
  findActiveSubscriptionByUserId,
};
