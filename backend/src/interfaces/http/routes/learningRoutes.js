const express = require('express');

const learningController = require('../controllers/learningController');
const asyncHandler = require('../../../shared/utils/asyncHandler');

const router = express.Router();

router.get('/languages', asyncHandler(learningController.getLanguages));
router.get('/categories', asyncHandler(learningController.getCategories));
router.get('/subcategories', asyncHandler(learningController.getSubcategories));
router.get('/courses', asyncHandler(learningController.getCourses));
router.get('/content', asyncHandler(learningController.getContent));
router.get('/alphabets', asyncHandler(learningController.getAlphabets));
router.get('/quizzes', asyncHandler(learningController.getQuizzes));
router.get('/phonics', asyncHandler(learningController.getPhonics));
router.get('/stories', asyncHandler(learningController.getStories));
router.get('/plans', asyncHandler(learningController.getPlans));

module.exports = router;
