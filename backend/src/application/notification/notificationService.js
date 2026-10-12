const notificationRepository = require('../../infrastructure/repositories/notificationRepository');
const fcmService = require('../../infrastructure/firebase/fcmService');
const { withTransaction } = require('../../infrastructure/database/db');
const audit = require('../admin/auditService');
const ApiError = require('../../shared/errors/apiError');

const defaultNotifications = [
  {
    title: 'Welcome to LangLex Kids',
    body: 'Your learning home is ready. Pick a lesson and start with a quick word card.',
    type: 'welcome',
    data: { action: 'open_learn' },
  },
  {
    title: 'Set up your learning',
    body: 'Choose your language and student level to personalize learning.',
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

const listNotifications = async ({ userId, page = 1, limit = 20 }) => {
  await ensureDefaultNotifications(userId);
  const notifications = await notificationRepository.listForUser({
    userId,
    page, limit,
  });
  const unreadCount = await notificationRepository.unreadCount(userId);
  const total = await notificationRepository.countForUser(userId);
  const { pagination } = require('../../shared/utils/pagination').pageResult(notifications, total, { page, limit });
  return { notifications, unread_count: unreadCount, pagination };
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

const sendAdminNotification = async ({
  admin,
  broadcast = false,
  userId,
  title,
  body,
  type = 'info',
  data = {},
}) => {
  if (!broadcast && (!Number.isInteger(Number(userId)) || Number(userId) <= 0)) {
    throw new ApiError('A valid user ID is required for a targeted notification', 422);
  }
  const targets = await notificationRepository.listTargets({
    userId: broadcast ? undefined : userId,
  });

  if (!broadcast && targets.length === 0) {
    throw new ApiError('User not found', 404);
  }

  const createdNotifications = await withTransaction(async () => {
    const created = [];
    for (const target of targets) {
      created.push(await notificationRepository.create({userId: target.id, title, body, type, data}));
    }
    if (admin) await audit.record(admin, {action:'send', entity:'notifications', id: broadcast ? null : userId,
      after: {title, body, type, data, broadcast, recipients:targets.map(target=>target.id), sent:created.length}});
    return created;
  });

  const push = await fcmService.sendToTokens({
    tokens: targets.map((target) => target.push_token),
    title,
    body,
    data: {
      ...data,
      action: data.action || 'open_notifications',
      type,
    },
  });

  for (const invalidToken of push.invalidTokens) {
    await notificationRepository.clearPushToken(invalidToken);
  }

  return {
    sent: createdNotifications.length,
    notification: broadcast ? undefined : createdNotifications[0],
    push,
  };
};

module.exports = {
  listNotifications,
  getUnreadCount,
  markRead,
  markAllRead,
  sendAdminNotification,
};
