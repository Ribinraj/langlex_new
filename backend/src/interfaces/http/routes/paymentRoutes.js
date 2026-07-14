const express = require('express');
const Joi = require('joi');

const paymentController = require('../controllers/paymentController');
const authenticate = require('../middleware/authMiddleware');
const validate = require('../middleware/validate');
const asyncHandler = require('../../../shared/utils/asyncHandler');

const router = express.Router();

const createOrderSchema = Joi.object({
  plan_id: Joi.number().integer().positive().required(),
});

const verifyPaymentSchema = Joi.object({
  order_id: Joi.number().integer().positive().required(),
  mock_status: Joi.string().valid('success', 'failed').default('success'),
});

router.get('/plans', asyncHandler(paymentController.getPlans));
router.post(
  '/create-order',
  authenticate,
  validate(createOrderSchema),
  asyncHandler(paymentController.createOrder),
);
router.post(
  '/verify',
  authenticate,
  validate(verifyPaymentSchema),
  asyncHandler(paymentController.verifyPayment),
);

module.exports = router;
