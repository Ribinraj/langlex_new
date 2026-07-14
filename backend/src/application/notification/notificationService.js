const notificationRepository = require('../../infrastructure/repositories/notificationRepository');
const ApiError = require('../../shared/errors/apiError');

const defaultNotifications = [
  {
    title: 'Welcome to LangLex Kids',
    body: 'Your learning home is ready. Pick a lesson and start with a quick word card.',
    type: 'welcome',
    data: { action: 'open_learn' },
  },
  {
    title: 'Set your daily goal',
    body: 'A short daily goal helps children build a steady learning habit.',
    type: 'setup',
    data: { action: 'open_learning_setup' },
  },
  {
    title: 'Try a quiz today',
    body: 'Practice questions are ready for the selected learning language.',
    type: 'practice',
    data: { action: 'open_quiz' },
  },
];

const ensureDefaultNotifications = async (userId) => {
  const count = await notificationRepository.countForUser(userId);
  if (count > 0) return;

  for (const notification of defaultNotifications) {
    await notificationRepository.create({ userId, ...notification });
  }
};

const listNotifications = async ({ userId, limit }) => {
  await ensureDefaultNotifications(userId);
  const notifications = await notificationRepository.listForUser({
    userId,
    limit,
  });
  const unreadCount = await notificationRepository.unreadCount(userId);
  return { notifications, unread_count: unreadCount };
};

const getUnreadCount = async (userId) => {
  await ensureDefaultNotifications(userId);
  return notificationRepository.unreadCount(userId);
};

const markRead = async ({ userId, notificationId }) => {
  const id = Number(notificationId);
  if (!Number.isInteger(id) || id <= 0) {
    throw new ApiError('Notification not found', 404);
  }

  const notification = await notificationRepository.markRead({
    userId,
    notificationId: id,
  });

  if (!notification) {
    throw new ApiError('Notification not found', 404);
  }

  const unreadCount = await notificationRepository.unreadCount(userId);
  return { notification, unread_count: unreadCount };
};

const markAllRead = async (userId) => {
  await notificationRepository.markAllRead(userId);
  const notifications = await notificationRepository.listForUser({ userId });
  return { notifications, unread_count: 0 };
};

module.exports = {
  listNotifications,
  getUnreadCount,
  markRead,
  markAllRead,
};
