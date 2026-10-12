const userRepository = require('../../../infrastructure/repositories/userRepository');
const ApiError = require('../../../shared/errors/apiError');
const { verifyToken } = require('../../../shared/utils/jwt');

const authenticate = async (req, _res, next) => {
  try {
    const header = req.headers.authorization || '';
    const [scheme, token] = header.split(' ');

    if (scheme?.toLowerCase() !== 'bearer' || !token) {
      throw new ApiError('Authentication token is required', 401);
    }

    const payload = verifyToken(token);
    if (payload.type === 'admin') throw new ApiError('A learner session is required',403);
    const user = await userRepository.findById(payload.sub);

    if (!user) {
      throw new ApiError('Invalid authentication token', 401);
    }

    require('../../../application/auth/accountAccess')(user);
    req.user = user;
    return next();
  } catch (error) {
    if (error instanceof ApiError) return next(error);
    return next(new ApiError('Invalid or expired authentication token', 401));
  }
};

module.exports = authenticate;
