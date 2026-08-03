const express = require('express');
const Joi = require('joi');

const authController = require('../controllers/authController');
const authenticate = require('../middleware/authMiddleware');
const validate = require('../middleware/validate');
const asyncHandler = require('../../../shared/utils/asyncHandler');

const router = express.Router();

const mobileSchema = Joi.object({
  mobile_number: Joi.string().pattern(/^[0-9]{10}$/).required().messages({
    'string.pattern.base': 'Mobile number must be 10 digits',
  }),
});

const registerSchema = mobileSchema.keys({
  full_name: Joi.string().trim().min(2).max(120).required(),
  email: Joi.string().trim().email().allow('', null).optional(),
  school: Joi.string().trim().min(2).max(160).required(),
  city: Joi.string().trim().min(2).max(120).required(),
  state: Joi.string().trim().min(2).max(120).required(),
});

const verifyOtpSchema = mobileSchema.keys({
  otp: Joi.string().pattern(/^[0-9]{6}$/).required().messages({
    'string.pattern.base': 'OTP must be 6 digits',
  }),
  push_token: Joi.string().trim().allow('', null).optional(),
});

const socialLoginSchema = Joi.object({
  id_token: Joi.string().trim().required(),
  push_token: Joi.string().trim().allow('', null).optional(),
});

const socialRegisterSchema = registerSchema.keys({
  id_token: Joi.string().trim().required(),
});

router.post(
  '/check-user',
  validate(mobileSchema),
  asyncHandler(authController.checkUser),
);
router.post(
  '/register',
  validate(registerSchema),
  asyncHandler(authController.register),
);
router.post(
  '/send-otp',
  validate(mobileSchema),
  asyncHandler(authController.sendOtp),
);
router.post(
  '/resend-otp',
  validate(mobileSchema),
  asyncHandler(authController.resendOtp),
);
router.post(
  '/verify-otp',
  validate(verifyOtpSchema),
  asyncHandler(authController.verifyOtp),
);
router.post(
  '/social-login',
  validate(socialLoginSchema),
  asyncHandler(authController.socialLogin),
);
router.post(
  '/social-register',
  validate(socialRegisterSchema),
  asyncHandler(authController.socialRegister),
);
router.post('/logout', authenticate, asyncHandler(authController.logout));

module.exports = router;
