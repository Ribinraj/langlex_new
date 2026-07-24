const adminService = require('../../../application/admin/adminService');
const ApiError = require('../../../shared/errors/apiError');
const { verifyToken } = require('../../../shared/utils/jwt');

const authenticateAdmin = async (req, _res, next) => {
  try {
    const header = req.headers.authorization || '';
    const [scheme, token] = header.split(' ');

    if (scheme?.toLowerCase() !== 'bearer' || !token) {
      throw new ApiError('Admin authentication token is required', 401);
    }

    const payload = verifyToken(token);
    if (payload.type !== 'admin') {
      throw new ApiError('Admin privileges are required', 403);
    }

    req.admin = await adminService.getCurrentAdmin(payload.sub);
    return next();
  } catch (error) {
    if (error instanceof ApiError) return next(error);
    return next(new ApiError('Invalid or expired admin token', 401));
  }
};

module.exports = authenticateAdmin;
