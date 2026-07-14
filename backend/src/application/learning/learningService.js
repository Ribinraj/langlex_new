const learningRepository = require('../../infrastructure/repositories/learningRepository');

const getLanguages = () => learningRepository.listLanguages();

const getCategories = () => learningRepository.listCategories();

const getSubcategories = (filters) => learningRepository.listSubcategories(filters);

const getCourses = (filters) => learningRepository.listCourses(filters);

const getContent = (filters) => learningRepository.listContent(filters);

const getAlphabets = (filters) => learningRepository.listAlphabets(filters);

const getQuizzes = (filters) => learningRepository.listQuizzes(filters);

const getPhonics = (filters) => learningRepository.listPhonics(filters);

const getStories = () => learningRepository.listStories();

const getPlans = () => learningRepository.listPlans();

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
