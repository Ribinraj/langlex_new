const learningService = require('../../../application/learning/learningService');

const getLanguages = async (_req, res) => {
  const languages = await learningService.getLanguages();
  res.json({ languages });
};

const getCategories = async (_req, res) => {
  const categories = await learningService.getCategories();
  res.json({ categories });
};

const getSubcategories = async (req, res) => {
  const subcategories = await learningService.getSubcategories(req.query);
  res.json({ subcategories });
};

const getCourses = async (req, res) => {
  const courses = await learningService.getCourses(req.query);
  res.json({ courses });
};

const getContent = async (req, res) => {
  const content = await learningService.getContent(req.query);
  res.json({ content });
};

const getAlphabets = async (req, res) => {
  const alphabets = await learningService.getAlphabets(req.query);
  res.json({ alphabets });
};

const getQuizzes = async (req, res) => {
  const quizzes = await learningService.getQuizzes(req.query);
  res.json({ quizzes });
};

const getPhonics = async (req, res) => {
  const phonics = await learningService.getPhonics(req.query);
  res.json({ phonics });
};

const getStories = async (_req, res) => {
  const stories = await learningService.getStories();
  res.json({ stories });
};

const getPlans = async (_req, res) => {
  const plans = await learningService.getPlans();
  res.json({ plans });
};

module.exports = {
  getLanguages,
  getCategories,
  getSubcategories,
  getCourses,
  getContent,
  getAlphabets,
  getQuizzes,
  getPhonics,
  getStories,
  getPlans,
};
