const { pool, withTransaction } = require('../../infrastructure/database/db');
const audit = require('./auditService');
const ApiError = require('../../shared/errors/apiError');
const user = async (id) => {
  const [[row]] = await pool.execute(
    'SELECT id,full_name,is_blocked,block_reason,blocked_at FROM users WHERE id=? FOR UPDATE',
    [id],
  );
  if (!row) throw new ApiError('User not found', 404);
  return row;
};
const subscription = async (id) => {
  const [[row]] = await pool.execute(
    'SELECT * FROM user_subscriptions WHERE id=? FOR UPDATE',
    [id],
  );
  if (!row) throw new ApiError('Subscription not found', 404);
  return row;
};
const setBlocked = (admin, id, { blocked, reason }) =>
  audit.mutate(
    admin,
    { action: blocked ? 'block' : 'unblock', entity: 'users', id, reason },
    () => user(id),
    async () => {
      await pool.execute(
        'UPDATE users SET is_blocked=?,block_reason=?,blocked_at=?,push_token=IF(?,NULL,push_token) WHERE id=?',
        [
          blocked,
          blocked ? reason : null,
          blocked ? new Date() : null,
          blocked,
          id,
        ],
      );
      return { user: await user(id) };
    },
  );
const grant = (admin, id, { plan_id, expires_at, reason }) =>
  withTransaction(async () => {
    await user(id); // Serializes changes to this learner's entitlements.
    const [[plan]] = await pool.execute(
      'SELECT * FROM subsc_plans WHERE id=? FOR UPDATE',
      [plan_id],
    );
    if (!plan || plan.type.toLowerCase() !== 'premium')
      throw new ApiError('Choose a Premium plan', 422);
    const expiry = new Date(expires_at);
    if (!Number.isFinite(expiry.getTime()) || expiry <= new Date())
      throw new ApiError('Expiry must be in the future', 422);
    const [before] = await pool.execute(
      "SELECT * FROM user_subscriptions WHERE user_id=? AND status='active' FOR UPDATE",
      [id],
    );
    await pool.execute(
      "UPDATE user_subscriptions SET status='cancelled' WHERE user_id=? AND status='active'",
      [id],
    );
    const [created] = await pool.execute(
      `INSERT INTO user_subscriptions
    (user_id,plan_id,status,started_at,expires_at,source,admin_note) VALUES (?,?,'active',NOW(),?,'manual',?)`,
      [id, plan_id, expiry, reason],
    );
    const after = await subscription(created.insertId);
    await audit.record(admin, {
      action: 'grant',
      entity: 'subscriptions',
      id: created.insertId,
      reason,
      before,
      after,
    });
    return { subscription: after };
  });
const manage = (admin, id, { action, expires_at, reason }) =>
  withTransaction(async () => {
    const [[owner]] = await pool.execute(
      'SELECT user_id FROM user_subscriptions WHERE id=?',
      [id],
    );
    if (!owner) throw new ApiError('Subscription not found', 404);
    await user(owner.user_id);
    return audit.mutate(
      admin,
      { action, entity: 'subscriptions', id, reason },
      () => subscription(id),
      async () => {
        const current = await subscription(id);
        if (current.status !== 'active')
          throw new ApiError(
            'This subscription is no longer active. Grant a new subscription instead.',
            409,
          );
        if (action === 'cancel') {
          await pool.execute(
            "UPDATE user_subscriptions SET status='cancelled',admin_note=? WHERE id=?",
            [reason, id],
          );
        } else {
          const expiry = new Date(expires_at);
          if (
            !Number.isFinite(expiry.getTime()) ||
            expiry <= new Date() ||
            expiry <= new Date(current.started_at)
          )
            throw new ApiError(
              'Choose an expiry after now and the start date',
              422,
            );
          // Expired rows can only be replaced by a new grant; never reactivate old payments.
          if (current.expires_at && new Date(current.expires_at) <= new Date())
            throw new ApiError(
              'This subscription has expired. Grant a new subscription instead.',
              409,
            );
          await pool.execute(
            'UPDATE user_subscriptions SET expires_at=?,admin_note=? WHERE id=?',
            [expiry, reason, id],
          );
        }
        return { subscription: await subscription(id) };
      },
    );
  });
module.exports = { setBlocked, grant, manage };
