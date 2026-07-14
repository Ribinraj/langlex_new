const paymentService = require('../../../application/payment/paymentService');

const getPlans = async (_req, res) => {
  const plans = await paymentService.listPlans();
  res.json({ plans });
};

const createOrder = async (req, res) => {
  const result = await paymentService.createOrder({
    userId: req.user.id,
    planId: req.body.plan_id,
  });
  res.status(201).json(result);
};

const verifyPayment = async (req, res) => {
  const result = await paymentService.verifyPayment({
    userId: req.user.id,
    orderId: req.body.order_id,
    mockStatus: req.body.mock_status,
  });
  res.json(result);
};

module.exports = {
  getPlans,
  createOrder,
  verifyPayment,
};
