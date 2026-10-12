const authenticate = require('./authMiddleware');
const setups = require('../../../application/learning/learningSetupService');
const ApiError = require('../../../shared/errors/apiError');
module.exports = (req, res, next) => {
  if (!req.headers.authorization) return next();
  authenticate(req, res, async (error) => {
    if (error) return next(error);
    try {
      const setup = await setups.getLearningSetup(req.user);
      if (setup.selected_languages?.length !== 3) {
        throw new ApiError('Select your three languages before learning.', 409);
      }
      if (req.query.language && req.query.language !== setup.active_language) {
        throw new ApiError('Switch to this language from Home first.', 403);
      }
      req.query.language = setup.active_language;
      req.query.level = setup.level;
      next();
    } catch (failure) { next(failure); }
  });
};
