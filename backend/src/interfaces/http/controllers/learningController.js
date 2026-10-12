const service = require('../../../application/learning/learningService');
const paged = (name, key) => async (req, res) => {
  const { items, pagination } = await service[name](req.query,req.user);
  res.json({ [key]: items, pagination });
};
module.exports = {
  getStory: async (req,res) => res.json({story:await service.getStory(req.params.id,req.query,req.user)}),
  getLanguages: async (_req, res) => res.json({ languages: await service.getLanguages() }),
  getPlans: async (_req, res) => res.json({ plans: await service.getPlans() }),
  getCategories: paged('getCategories', 'categories'),
  getSubcategories: paged('getSubcategories', 'subcategories'),
  getCourses: paged('getCourses', 'courses'),
  getContent: paged('getContent', 'content'),
  getAlphabets: paged('getAlphabets', 'alphabets'),
  getQuizzes: paged('getQuizzes', 'quizzes'),
  getPhonics: paged('getPhonics', 'phonics'),
  getStories: paged('getStories', 'stories'),
};
