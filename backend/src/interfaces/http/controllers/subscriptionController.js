const paymentService = require('../../../application/payment/paymentService');

const getMySubscription = async (req, res) => {
  const subscription = await paymentService.getActiveSubscription(req.user.id);
  res.json({ subscription });
};

module.exports = {
  getMySubscription,
};
