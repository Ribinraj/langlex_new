const notificationService = require('../../../application/notification/notificationService');

const listNotifications = async (req, res) => {
  const paging = require('../../../shared/utils/pagination').pagination(req.query);
  const result = await notificationService.listNotifications({
    userId: req.user.id,
    ...paging,
  });
  res.json(result);
};

const getUnreadCount = async (req, res) => {
  const unreadCount = await notificationService.getUnreadCount(req.user.id);
  res.json({ unread_count: unreadCount });
};

const markRead = async (req, res) => {
  const result = await notificationService.markRead({
    userId: req.user.id,
    notificationId: req.params.id,
  });
  res.json(result);
};

const markAllRead = async (req, res) => {
  const result = await notificationService.markAllRead(req.user.id);
  res.json(result);
};

module.exports = {
  listNotifications,
  getUnreadCount,
  markRead,
  markAllRead,
};
