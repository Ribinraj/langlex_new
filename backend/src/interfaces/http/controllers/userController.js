const userService = require('../../../application/user/userService');
const contentProgressService = require('../../../application/learning/contentProgressService');
const learningSetupService = require('../../../application/learning/learningSetupService');

const getProfile = async (req, res) => {
  const user = await userService.getProfile(req.user);
  res.json({ user });
};

const updateProfile = async (req, res) => {
  const user = await userService.updateProfile(req.user, req.body);
  res.json({ user });
};

const updatePushToken = async (req, res) => {
  const user = await userService.updatePushToken(req.user, req.body.push_token);
  res.json({ user });
};

const getLearningSetup = async (req, res) => {
  const learningSetup = await learningSetupService.getLearningSetup(req.user);
  res.json({ learning_setup: learningSetup });
};

const saveLearningSetup = async (req, res) => {
  const learningSetup = await learningSetupService.saveLearningSetup(
    req.user,
    req.body,
  );
  res.json({ learning_setup: learningSetup });
};

const getContentProgress = async (req, res) => {
  const progress = await contentProgressService.getProgress(req.user, req.query);
  res.json({ progress });
};

const saveContentProgress = async (req, res) => {
  const progress = await contentProgressService.saveProgress(req.user, req.body);
  res.json({ progress });
};

const recordContentProgressItem = async (req, res) => {
  const progress = await contentProgressService.recordItemProgress(
    req.user,
    req.body,
  );
  res.json({ progress });
};

const restartContentProgress = async (req, res) => {
  const progress = await contentProgressService.restartSession(req.user, req.body);
  res.json({ progress });
};

module.exports = {
  getProfile,
  updateProfile,
  updatePushToken,
  getLearningSetup,
  saveLearningSetup,
  getContentProgress,
  saveContentProgress,
  recordContentProgressItem,
  restartContentProgress,
};
