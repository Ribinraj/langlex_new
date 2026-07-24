const express = require('express');
const Joi = require('joi');

const adminController = require('../controllers/adminController');
const authenticateAdmin = require('../middleware/adminAuthMiddleware');
const validate = require('../middleware/validate');
const asyncHandler = require('../../../shared/utils/asyncHandler');

const router = express.Router();

const loginSchema = Joi.object({
  email: Joi.string().trim().email({ tlds: { allow: false } }).required(),
  password: Joi.string().min(8).max(160).required(),
});

const pagingSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(10),
  search: Joi.string().trim().allow('', null).default(''),
  language: Joi.string().trim().allow('', null).optional(),
  status: Joi.string().trim().allow('', null).optional(),
});

const userUpdateSchema = Joi.object({
  full_name: Joi.string().trim().min(2).max(120).required(),
  email: Joi.string().trim().email().allow('', null).optional(),
  school: Joi.string().trim().max(160).allow('', null).optional(),
  city: Joi.string().trim().max(120).allow('', null).optional(),
  state: Joi.string().trim().max(120).allow('', null).optional(),
});

const notificationSchema = Joi.object({
  userId: Joi.number().integer().positive().allow(null).optional(),
  broadcast: Joi.boolean().default(false),
  title: Joi.string().trim().min(2).max(160).required(),
  body: Joi.string().trim().min(2).max(500).required(),
  type: Joi.string().trim().min(2).max(60).default('info'),
  data: Joi.object().unknown(true).default({}),
});

const resourceSchema = Joi.object().unknown(true);

router.post(
  '/auth/login',
  validate(loginSchema),
  asyncHandler(adminController.login),
);

router.use(authenticateAdmin);

router.get('/auth/me', asyncHandler(adminController.me));
router.get('/overview', asyncHandler(adminController.overview));
router.get('/users', validate(pagingSchema, 'query'), asyncHandler(adminController.listUsers));
router.get('/users/:id', asyncHandler(adminController.getUser));
router.put('/users/:id', validate(userUpdateSchema), asyncHandler(adminController.updateUser));
router.delete('/users/:id', asyncHandler(adminController.deleteUser));
router.get(
  '/payments',
  validate(pagingSchema, 'query'),
  asyncHandler(adminController.listPayments),
);
router.get(
  '/subscriptions',
  validate(pagingSchema, 'query'),
  asyncHandler(adminController.listSubscriptions),
);
router.get(
  '/notifications',
  validate(pagingSchema, 'query'),
  asyncHandler(adminController.listNotifications),
);
router.post(
  '/notifications',
  validate(notificationSchema),
  asyncHandler(adminController.createNotification),
);
router.get('/resources/schema', asyncHandler(adminController.resourceSchema));
router.get(
  '/resources/:resource',
  validate(pagingSchema, 'query'),
  asyncHandler(adminController.listResource),
);
router.get('/resources/:resource/:id', asyncHandler(adminController.getResource));
router.post(
  '/resources/:resource',
  validate(resourceSchema),
  asyncHandler(adminController.createResource),
);
router.put(
  '/resources/:resource/:id',
  validate(resourceSchema),
  asyncHandler(adminController.updateResource),
);
router.delete('/resources/:resource/:id', asyncHandler(adminController.deleteResource));

module.exports = router;
