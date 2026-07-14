const env = require('../../../infrastructure/config/env');
const ApiError = require('../../../shared/errors/apiError');

const notFound = (req, _res, next) => {
  next(new ApiError(`Route not found: ${req.method} ${req.originalUrl}`, 404));
};

const errorHandler = (error, _req, res, _next) => {
  const statusCode = error.statusCode || 500;
  const response = {
    message: error.message || 'Internal server error',
  };

  if (error.details) response.details = error.details;
  if (env.nodeEnv !== 'production') response.stack = error.stack;

  res.status(statusCode).json(response);
};

module.exports = {
  notFound,
  errorHandler,
};
