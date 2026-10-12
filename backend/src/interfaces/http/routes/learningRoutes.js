const express = require('express');

const learningController = require('../controllers/learningController');
const asyncHandler = require('../../../shared/utils/asyncHandler');

const router = express.Router();
const catalogLanguage = require('../middleware/catalogLanguage');

router.get('/languages', asyncHandler(learningController.getLanguages));
router.get('/categories', catalogLanguage, asyncHandler(learningController.getCategories));
router.get('/subcategories', catalogLanguage, asyncHandler(learningController.getSubcategories));
router.get('/courses', catalogLanguage, asyncHandler(learningController.getCourses));
router.get('/content', catalogLanguage, asyncHandler(learningController.getContent));
router.get('/alphabets', catalogLanguage, asyncHandler(learningController.getAlphabets));
router.get('/quizzes', catalogLanguage, asyncHandler(learningController.getQuizzes));
router.get('/phonics', catalogLanguage, asyncHandler(learningController.getPhonics));
router.get('/stories/:id', catalogLanguage, asyncHandler(learningController.getStory));
router.get('/stories', catalogLanguage, asyncHandler(learningController.getStories));
router.get('/plans', asyncHandler(learningController.getPlans));

module.exports = router;
