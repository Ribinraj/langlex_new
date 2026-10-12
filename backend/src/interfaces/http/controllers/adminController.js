const adminService = require('../../../application/admin/adminService');
const notificationService = require('../../../application/notification/notificationService');
const adminRepository = require('../../../infrastructure/repositories/adminRepository');
const audit = require('../../../application/admin/auditService');
const ApiError = require('../../../shared/errors/apiError');

const login = async (req, res) => {
  const result = await adminService.login(req.body);
  res.json(result);
};

const me = async (req, res) => {
  res.json({ admin: req.admin });
};

const overview = async (_req, res) => {
  const result = await adminRepository.getOverview();
  res.json(result);
};

const listUsers = async (req, res) => {
  const result = await adminRepository.listUsers(req.query);
  res.json(result);
};

const getUser = async (req, res) => {
  const result = await adminRepository.getUserDetail(req.params.id);
  if (!result) throw new ApiError('User not found', 404);
  res.json(result);
};

const updateUser = async (req, res) => {
  const result = await audit.mutate(
    req.admin,
    { action: 'update', entity: 'users', id: req.params.id },
    async () => (await adminRepository.getUserDetail(req.params.id))?.user,
    async () => {
      const result = await adminRepository.updateUser(req.params.id, req.body);
      if (!result) throw new ApiError('User not found', 404);
      return result;
    },
  );
  if (!result) throw new ApiError('User not found', 404);
  res.json(result);
};

const deleteUser = async (req, res) => {
  const deleted = await audit.mutate(
    req.admin,
    { action: 'delete', entity: 'users', id: req.params.id },
    async () => (await adminRepository.getUserDetail(req.params.id))?.user,
    async () => {
      const deleted = await adminRepository.deleteUser(req.params.id);
      if (!deleted) throw new ApiError('User not found', 404);
      return deleted;
    },
  );
  if (!deleted) throw new ApiError('User not found', 404);
  res.json({ deleted: true });
};

const listPayments = async (req, res) => {
  const result = await adminRepository.listPaymentOrders(req.query);
  res.json(result);
};

const listSubscriptions = async (req, res) => {
  const result = await adminRepository.listSubscriptions(req.query);
  res.json(result);
};

const listNotifications = async (req, res) => {
  const result = await adminRepository.listNotifications(req.query);
  res.json(result);
};

const createNotification = async (req, res) => {
  const result = await notificationService.sendAdminNotification({
    ...req.body,
    admin: req.admin,
  });
  res.status(201).json(result);
};

const resourceSchema = async (_req, res) => {
  res.json({ resources: adminRepository.getResourceSchema() });
};

const listResource = async (req, res) => {
  const result = await adminRepository.listResource(
    req.params.resource,
    req.query,
  );
  res.json(result);
};

const getResource = async (req, res) => {
  const result = await adminRepository.getResource(
    req.params.resource,
    req.params.id,
  );
  if (!result) throw new ApiError('Resource not found', 404);
  res.json({ item: result });
};

const createResource = async (req, res) => {
  const item = await audit.mutate(
    req.admin,
    { action: 'create', entity: req.params.resource },
    null,
    () => adminRepository.createResource(req.params.resource, req.body),
  );
  res.status(201).json({ item });
};

const updateResource = async (req, res) => {
  const item = await audit.mutate(
    req.admin,
    { action: 'update', entity: req.params.resource, id: req.params.id },
    () => adminRepository.getResource(req.params.resource, req.params.id),
    async () => {
      const item = await adminRepository.updateResource(
        req.params.resource,
        req.params.id,
        req.body,
      );
      if (!item) throw new ApiError('Resource not found', 404);
      return item;
    },
  );
  if (!item) throw new ApiError('Resource not found', 404);
  res.json({ item });
};

const deleteResource = async (req, res) => {
  const deleted = await audit.mutate(
    req.admin,
    { action: 'delete', entity: req.params.resource, id: req.params.id },
    () => adminRepository.getResource(req.params.resource, req.params.id),
    async () => {
      const deleted = await adminRepository.deleteResource(
        req.params.resource,
        req.params.id,
      );
      if (!deleted) throw new ApiError('Resource not found', 404);
      return deleted;
    },
  );
  if (!deleted) throw new ApiError('Resource not found', 404);
  res.json({ deleted: true });
};

module.exports = {
  login,
  me,
  overview,
  listUsers,
  getUser,
  updateUser,
  deleteUser,
  listPayments,
  listSubscriptions,
  listNotifications,
  createNotification,
  resourceSchema,
  listResource,
  getResource,
  createResource,
  updateResource,
  deleteResource,
};
