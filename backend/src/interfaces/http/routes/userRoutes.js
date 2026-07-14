const express = require('express');
const Joi = require('joi');

const userController = require('../controllers/userController');
const authenticate = require('../middleware/authMiddleware');
const validate = require('../middleware/validate');
const asyncHandler = require('../../../shared/utils/asyncHandler');

const router = express.Router();

const ageGroups = ['2-3 years', '3-4 years', '4-5 years', '5-6 years', '6+ years'];
const academicLevels = ['Playgroup', 'Nursery', 'LKG', 'UKG', 'Class 1', 'Class 2'];

const profileSchema = Joi.object({
  full_name: Joi.string().trim().min(2).max(120).required(),
  email: Joi.string().trim().email().allow('', null).optional(),
  school: Joi.string().trim().min(2).max(160).allow('', null).optional(),
  city: Joi.string().trim().min(2).max(120).allow('', null).optional(),
  state: Joi.string().trim().min(2).max(120).allow('', null).optional(),
});

const learningSetupSchema = Joi.object({
  child_name: Joi.string().trim().min(2).max(120).allow('', null).optional(),
  age_group: Joi.string().valid(...ageGroups).required(),
  primary_language: Joi.string().trim().min(2).max(80).required(),
  learning_language: Joi.string().trim().min(2).max(80).required(),
  level: Joi.string().valid(...academicLevels).required(),
  interests: Joi.array().items(Joi.string().trim().min(1).max(120)).max(12).default([]),
  daily_goal_minutes: Joi.number().integer().min(5).max(180).default(15),
  plan_id: Joi.number().integer().positive().allow(null).optional(),
});

const dailyGoalProgressSchema = Joi.object({
  activity_date: Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).optional(),
  activity_type: Joi.string().valid('word', 'quiz').required(),
  activity_key: Joi.string().trim().min(1).max(160).required(),
  estimated_minutes: Joi.number().integer().min(1).max(15).optional(),
});

const contentProgressQuerySchema = Joi.object({
  content_type: Joi.string().valid('course', 'quiz', 'phonics', 'story').required(),
  content_key: Joi.string().trim().min(1).max(160).required(),
});

const contentProgressSchema = Joi.object({
  content_type: Joi.string().valid('course', 'quiz', 'phonics', 'story').required(),
  content_key: Joi.string().trim().min(1).max(160).required(),
  status: Joi.string().valid('not_started', 'in_progress', 'completed').optional(),
  position: Joi.number().integer().min(0).default(0),
  total_items: Joi.number().integer().min(0).default(0),
  score: Joi.number().integer().min(0).default(0),
  metadata: Joi.object().unknown(true).optional(),
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
router.get(
  '/daily-goal',
  authenticate,
  asyncHandler(userController.getDailyGoal),
);
router.post(
  '/daily-goal/progress',
  authenticate,
  validate(dailyGoalProgressSchema),
  asyncHandler(userController.recordDailyProgress),
);
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
