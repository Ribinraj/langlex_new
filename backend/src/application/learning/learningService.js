const learningRepository = require('../../infrastructure/repositories/learningRepository');
const { pool } = require('../../infrastructure/database/db');
const accessPolicy = require('./contentAccess');
const ApiError = require('../../shared/errors/apiError');
const { groupStoryPassages } = require('./catalogAdapter');
const catalogRepository = require('../../infrastructure/repositories/catalogRepository');
const { textFilter } = require('../../shared/utils/pagination');
module.exports = {
  getLanguages: () => learningRepository.listLanguages(),
  getPlans: () => learningRepository.listPlans(),
  getCategories: (query) => catalogRepository.list('categories', query),
  getSubcategories: (query) => catalogRepository.list('subcategories', query),
  getCourses: (query) => catalogRepository.courses(query),
  getContent: async (query, user) => {
    query = {
      ...query,
      course: textFilter(query.course, 'course'),
      language: textFilter(query.language, 'language'),
    };
    const access = await accessPolicy.accessFor(user);
    if (query.course) {
      const [courses] = await pool.query(
        'SELECT show_plan FROM courses WHERE title=?' +
          (query.language ? ' AND language=?' : ''),
        [query.course, ...(query.language ? [query.language] : [])],
      );
      for (const course of courses)
        accessPolicy.assertRead(course.show_plan, access);
    }
    return catalogRepository.list('content', query, access);
  },
  getAlphabets: (query) => catalogRepository.list('alphabets', query),
  getQuizzes: async (query, user) => {
    const access = await accessPolicy.accessFor(user);
    const topic = textFilter(query.topic, 'topic'),
      language = textFilter(query.language, 'language');
    if (topic && query.view !== 'sets') {
      const [settings] = await pool.query(
        'SELECT show_plan FROM quiz_topic_settings WHERE topic=?' +
          (language ? ' AND language=?' : ''),
        [topic, ...(language ? [language] : [])],
      );
      for (const setting of settings)
        accessPolicy.assertRead(setting.show_plan, access);
    }
    return catalogRepository.list('quizzes', query, access);
  },
  getPhonics: (query) => catalogRepository.list('phonics', query),
  getStories: async (query, user) => {
    const [result, access] = await Promise.all([
      catalogRepository.stories(query),
      accessPolicy.accessFor(user),
    ]);
    return {
      ...result,
      items: result.items.map((story) => ({
        ...story,
        reading_minutes: Math.max(
          1,
          Math.ceil(
            String(story.text || '')
              .trim()
              .split(/\s+/)
              .filter(Boolean).length / 80,
          ),
        ),
        ...(!accessPolicy.canRead(story.show_plan, access)
          ? {
              locked: true,
              text: '',
              audio: '',
              title_audio: '',
              audio_text_map: '',
              sections: [],
            }
          : { locked: false }),
      })),
    };
  },
  getStory: async (id, query, user) => {
    if (!/^\d+$/.test(String(id))) throw new ApiError('Story not found', 404);
    const [[anchor]] = await pool.query(
      'SELECT title,language,grade FROM stories WHERE id=?',
      [id],
    );
    if (!anchor || (query.language && query.language !== anchor.language))
      throw new ApiError('Story not found in this language', 404);
    const eligible =
      require('../../infrastructure/repositories/curriculumRepository').filter(
        'stories',
        'stories',
        textFilter(query.level, 'level'),
      );
    const [rows] = await pool.query(
      `SELECT * FROM stories WHERE title=? AND language=? AND grade=? AND ${eligible.sql} ORDER BY id`,
      [anchor.title, anchor.language, anchor.grade, ...eligible.params],
    );
    if (!rows.length)
      throw new ApiError('This story is not available for your standard.', 404);
    const story = groupStoryPassages(rows)[0];
    const [[fullAccess]] = await pool.query(
      "SELECT CASE WHEN SUM(LOWER(TRIM(show_plan)) IN ('premium','paid','1'))>0 THEN 'Premium' WHEN SUM(LOWER(TRIM(show_plan))='login')>0 THEN 'Login' ELSE 'Free' END AS show_plan FROM stories WHERE title=? AND language=? AND grade=?",
      [anchor.title, anchor.language, anchor.grade],
    );
    story.show_plan = fullAccess.show_plan;
    accessPolicy.assertRead(
      story.show_plan,
      await accessPolicy.accessFor(user),
    );
    return {
      ...story,
      id: Number(id),
      ...(query.level ? { grade: query.level } : {}),
      locked: false,
    };
  },
};
