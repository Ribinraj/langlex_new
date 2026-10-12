const ApiError = require('../../shared/errors/apiError');
module.exports = (user) => {
  if (user?.is_blocked) throw new ApiError('Your account has been blocked. Please contact support.', 403, { code: 'ACCOUNT_BLOCKED' });
};
