const adminService = require('../../../application/admin/adminService');
const adminRepository = require('../../../infrastructure/repositories/adminRepository');
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
  const result = await adminRepository.updateUser(req.params.id, req.body);
  if (!result) throw new ApiError('User not found', 404);
  res.json(result);
};

const deleteUser = async (req, res) => {
  const deleted = await adminRepository.deleteUser(req.params.id);
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
  const result = req.body.broadcast
    ? await adminRepository.broadcastNotification(req.body)
    : await adminRepository.createNotification(req.body);
  res.status(201).json(result);
};

const resourceSchema = async (_req, res) => {
  res.json({ resources: adminRepository.getResourceSchema() });
};

const listResource = async (req, res) => {
  const result = await adminRepository.listResource(req.params.resource, req.query);
  res.json(result);
};

const getResource = async (req, res) => {
  const result = await adminRepository.getResource(req.params.resource, req.params.id);
  if (!result) throw new ApiError('Resource not found', 404);
  res.json({ item: result });
};

const createResource = async (req, res) => {
  const item = await adminRepository.createResource(req.params.resource, req.body);
  res.status(201).json({ item });
};

const updateResource = async (req, res) => {
  const item = await adminRepository.updateResource(
    req.params.resource,
    req.params.id,
    req.body,
  );
  if (!item) throw new ApiError('Resource not found', 404);
  res.json({ item });
};

const deleteResource = async (req, res) => {
  const deleted = await adminRepository.deleteResource(
    req.params.resource,
    req.params.id,
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
