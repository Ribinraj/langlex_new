const crypto = require('crypto');
const { pool, withTransaction } = require('../../infrastructure/database/db');
const { buildExpiry } = require('../../shared/utils/subscriptionExpiry');

const learningRepository = require('../../infrastructure/repositories/learningRepository');
const paymentRepository = require('../../infrastructure/repositories/paymentRepository');
const ApiError = require('../../shared/errors/apiError');

const listPlans = () => learningRepository.listPlans();

const getActiveSubscription = async (userId) => {
  const subscription = await paymentRepository.findActiveSubscriptionByUserId(userId);
  return subscription || {
    status: 'free',
    plan_name: 'Free Trial',
    type: 'free',
    amount: '0',
    plan_timeperiod: 'limited',
  };
};

const createOrder = async ({ userId, planId }) => {
  const plan = await paymentRepository.findPlanById(planId);
  if (!plan) {
    throw new ApiError('Subscription plan not found', 404);
  }

  const providerOrderId = `dummy_order_${Date.now()}_${crypto
    .randomBytes(4)
    .toString('hex')}`;

  const order = await paymentRepository.createOrder({
    userId,
    plan,
    providerOrderId,
    metadata: {
      mode: 'dummy',
      provider: 'dummy',
      migration_note: 'Replace this with a real payment provider order id.',
    },
  });

  return {
    order,
    checkout: {
      provider: 'dummy',
      provider_order_id: providerOrderId,
      amount: plan.amount,
      currency: 'INR',
      plan_name: plan.name,
    },
  };
};

const verifyPayment = ({ userId, orderId, mockStatus = 'success' }) => withTransaction(async () => {
  await pool.execute('SELECT id FROM users WHERE id=? FOR UPDATE',[userId]);
  const order = await paymentRepository.findOrderById(orderId);
  if (!order || Number(order.user_id) !== Number(userId)) {
    throw new ApiError('Payment order not found', 404);
  }

  if (order.status === 'paid') {
    const subscription = await paymentRepository.findActiveSubscriptionByUserId(userId);
    return { order, subscription };
  }

  if (mockStatus !== 'success') {
    throw new ApiError('Dummy payment failed', 400);
  }

  const paidOrder = await paymentRepository.markOrderPaid({
    orderId,
    metadata: {
      mode: 'dummy',
      provider_payment_id: `dummy_payment_${Date.now()}`,
      verified_at: new Date().toISOString(),
    },
  });

  const plan = await paymentRepository.findPlanById(order.plan_id);
  const startedAt = new Date();
  const expiresAt = buildExpiry(startedAt, plan?.plan_timeperiod);

  const subscription = await paymentRepository.createSubscription({
    userId,
    planId: order.plan_id,
    paymentOrderId: paidOrder.id,
    startedAt,
    expiresAt,
  });

  return { order: paidOrder, subscription };
});

module.exports = {
  listPlans,
  getActiveSubscription,
  createOrder,
  verifyPayment,
};
