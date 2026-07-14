const userService = require('../../../application/user/userService');
const contentProgressService = require('../../../application/learning/contentProgressService');
const dailyGoalService = require('../../../application/learning/dailyGoalService');
const learningSetupService = require('../../../application/learning/learningSetupService');

const getProfile = async (req, res) => {
  const user = await userService.getProfile(req.user);
  res.json({ user });
};

const updateProfile = async (req, res) => {
  const user = await userService.updateProfile(req.user, req.body);
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

const getDailyGoal = async (req, res) => {
  const dailyGoal = await dailyGoalService.getDailyGoal(
    req.user,
    req.query.date,
  );
  res.json({ daily_goal: dailyGoal });
};

const recordDailyProgress = async (req, res) => {
  const dailyGoal = await dailyGoalService.recordDailyProgress(req.user, req.body);
  res.json({ daily_goal: dailyGoal });
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
  getLearningSetup,
  saveLearningSetup,
  getDailyGoal,
  recordDailyProgress,
  getContentProgress,
  saveContentProgress,
  recordContentProgressItem,
  restartContentProgress,
};
