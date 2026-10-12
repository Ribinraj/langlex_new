const express = require('express');
const Joi = require('joi');

const userController = require('../controllers/userController');
const authenticate = require('../middleware/authMiddleware');
const validate = require('../middleware/validate');
const asyncHandler = require('../../../shared/utils/asyncHandler');

const router = express.Router();

const academicLevels = ['Playgroup', 'Nursery', 'LKG', 'UKG', 'Class 1', 'Class 2'];

const profileSchema = Joi.object({
  full_name: Joi.string().trim().min(2).max(120).required(),
  email: Joi.string().trim().email().allow('', null).optional(),
  school: Joi.string().trim().min(2).max(160).allow('', null).optional(),
  city: Joi.string().trim().min(2).max(120).allow('', null).optional(),
  state: Joi.string().trim().min(2).max(120).allow('', null).optional(),
});

const pushTokenSchema = Joi.object({
  push_token: Joi.string().trim().max(4096).allow('', null).required(),
});

const learningSetupSchema = Joi.object({
  child_name: Joi.string().trim().min(2).max(120).allow('', null).optional(),
  primary_language: Joi.string().trim().min(2).max(80).optional(),
  learning_language: Joi.string().trim().min(2).max(80).optional(),
  active_language: Joi.string().trim().min(2).max(80).optional(),
  selected_languages: Joi.array().items(Joi.string().trim().min(2).max(80)).length(3).unique().optional(),
  level: Joi.string().valid(...academicLevels).required(),
  interests: Joi.array().items(Joi.string().trim().min(1).max(120)).max(12).default([]),
  plan_id: Joi.number().integer().positive().allow(null).optional(),
});

const contentProgressQuerySchema = Joi.object({
  content_type: Joi.string().valid('course', 'quiz', 'phonics', 'story', 'alphabet').required(),
  content_key: Joi.string().trim().min(1).max(160).required(),
});

const contentProgressSchema = Joi.object({
  content_type: Joi.string().valid('course', 'quiz', 'phonics', 'story', 'alphabet').required(),
  content_key: Joi.string().trim().min(1).max(160).required(),
  status: Joi.string().valid('not_started', 'in_progress', 'completed').optional(),
  position: Joi.number().integer().min(0).default(0),
  total_items: Joi.number().integer().min(0).default(0),
  score: Joi.number().integer().min(0).default(0),
  metadata: Joi.object().unknown(true).optional(),
  event_id: Joi.string().pattern(/^[a-zA-Z0-9_-]{8,80}$/).optional(),
  session_id: Joi.string().max(80).optional(),
  next_session_id: Joi.string().pattern(/^[a-zA-Z0-9_-]{8,80}$/).optional(),
  answer: Joi.string().max(1000).allow('').optional(),
});

const contentProgressItemSchema = contentProgressSchema.keys({
  item_key: Joi.string().trim().min(1).max(180).required(),
  is_correct: Joi.boolean().allow(null).optional(),
});

router.get('/profile', authenticate, asyncHandler(userController.getProfile));
router.put(
  '/profile',
  authenticate,
  validate(profileSchema),
  asyncHandler(userController.updateProfile),
);
router.post(
  '/push-token',
  authenticate,
  validate(pushTokenSchema),
  asyncHandler(userController.updatePushToken),
);
router.get(
  '/learning-setup',
  authenticate,
  asyncHandler(userController.getLearningSetup),
);
router.put(
  '/learning-setup',
  authenticate,
  validate(learningSetupSchema),
  asyncHandler(userController.saveLearningSetup),
);
router.get('/learning-progress', authenticate, validate(Joi.object({ language: Joi.string().trim().max(80).optional() }), 'query'), asyncHandler(async (req, res) => {
  res.json({ progress: await require('../../../application/learning/contentProgressService').overview(req.user, req.query) });
}));

router.get(
  '/content-progress',
  authenticate,
  validate(contentProgressQuerySchema, 'query'),
  asyncHandler(userController.getContentProgress),
);
router.put(
  '/content-progress',
  authenticate,
  validate(contentProgressSchema),
  asyncHandler(userController.saveContentProgress),
);
router.post(
  '/content-progress/item',
  authenticate,
  validate(contentProgressItemSchema),
  asyncHandler(userController.recordContentProgressItem),
);
router.post(
  '/content-progress/restart',
  authenticate,
  validate(contentProgressSchema),
  asyncHandler(userController.restartContentProgress),
);

module.exports = router;
