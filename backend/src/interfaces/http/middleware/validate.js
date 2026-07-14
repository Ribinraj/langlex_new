const ApiError = require('../../../shared/errors/apiError');

const validate = (schema, source = 'body') => (req, _res, next) => {
  const { error, value } = schema.validate(req[source], {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    const details = error.details.map((item) => item.message);
    return next(new ApiError('Validation failed', 422, details));
  }

  req[source] = value;
  return next();
};

module.exports = validate;
