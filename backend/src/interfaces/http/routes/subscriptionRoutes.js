const express = require('express');

const subscriptionController = require('../controllers/subscriptionController');
const authenticate = require('../middleware/authMiddleware');
const asyncHandler = require('../../../shared/utils/asyncHandler');

const router = express.Router();

router.get('/me', authenticate, asyncHandler(subscriptionController.getMySubscription));

module.exports = router;
