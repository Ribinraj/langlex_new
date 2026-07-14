const express = require('express');

const notificationController = require('../controllers/notificationController');
const authenticate = require('../middleware/authMiddleware');
const asyncHandler = require('../../../shared/utils/asyncHandler');

const router = express.Router();

router.use(authenticate);

router.get('/', asyncHandler(notificationController.listNotifications));
router.get('/unread-count', asyncHandler(notificationController.getUnreadCount));
router.patch('/read-all', asyncHandler(notificationController.markAllRead));
router.patch('/:id/read', asyncHandler(notificationController.markRead));

module.exports = router;
