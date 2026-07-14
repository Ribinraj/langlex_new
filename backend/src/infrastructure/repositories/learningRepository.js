const { pool } = require('../database/db');
const env = require('../config/env');

const columnCache = new Map();

const hasColumn = async (tableName, columnName) => {
  const key = `${tableName}.${columnName}`;
  if (columnCache.has(key)) return columnCache.get(key);

  const [rows] = await pool.execute(
    `SELECT COLUMN_NAME
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?
     LIMIT 1`,
    [env.db.database, tableName, columnName],
  );
  const exists = rows.length > 0;
  columnCache.set(key, exists);
  return exists;
};

const listCategories = async () => {
  const [rows] = await pool.execute(
    `SELECT id, title, created, image, language
     FROM categories
     ORDER BY id`,
  );
  return rows;
};

const toDisplayLanguage = (value) => {
  const text = String(value || '').trim();
  if (!text) return '';

  const canonical = {
    english: 'English',
    hindi: 'Hindi',
    kannada: 'Kannada',
    maithili: 'Maithili',
  };

  return canonical[text.toLowerCase()] || text;
};

const listLanguages = async () => {
  const languages = new Map();

  const addLanguage = (value) => {
    const language = toDisplayLanguage(value);
    if (language) languages.set(language.toLowerCase(), language);
  };

  if (await hasColumn('site_language', 'language')) {
    const [rows] = await pool.execute(
      `SELECT language
       FROM site_language
       ORDER BY id`,
    );
    rows.forEach((row) => addLanguage(row.language));
  }

  const tableQueries = [
    ['categories', 'language'],
    ['courses', 'language'],
    ['Content', 'language'],
    ['Alphabets', 'language'],
    ['quizz', 'Language'],
    ['Phonics', 'language'],
    ['stories', 'language'],
  ];

  for (const [table, column] of tableQueries) {
    if (!(await hasColumn(table, column))) continue;
    const [rows] = await pool.execute(
      `SELECT DISTINCT \`${column}\` AS language
       FROM \`${table}\`
       WHERE \`${column}\` <> ''
       ORDER BY \`${column}\``,
    );
    rows.forEach((row) => addLanguage(row.language));
  }

  return [...languages.values()];
};

const listSubcategories = async ({ category } = {}) => {
  const params = [];
  let query = `SELECT id, title, created, image, p_cat, language FROM subcategories`;

  if (category) {
    query += ' WHERE p_cat = ?';
    params.push(category);
  }

  query += ' ORDER BY id';
  const [rows] = await pool.execute(query, params);
  return rows;
};

const listCourses = async ({ language } = {}) => {
  const params = [];
  const levelSelect = (await hasColumn('courses', 'level'))
    ? 'level'
    : "'' AS level";
  let query = `SELECT id, title, created, image, language, show_plan, ${levelSelect} FROM courses`;

  if (language) {
    query += ' WHERE language = ?';
    params.push(language);
  }

  query += ' ORDER BY id';
  const [rows] = await pool.execute(query, params);
  return rows;
};

const listContent = async ({ course, category, subcategory } = {}) => {
  const where = [];
  const params = [];
  const levelSelect = (await hasColumn('Content', 'level'))
    ? 'level'
    : "'' AS level";

  if (course) {
    where.push('course = ?');
    params.push(course);
  }
  if (category) {
    where.push('category = ?');
    params.push(category);
  }
  if (subcategory) {
    where.push('subcategory = ?');
    params.push(subcategory);
  }

  const [rows] = await pool.execute(
    `SELECT id, content, created, content_image, content_audio, word_audio,
            course, subcategory, category, language, ${levelSelect}
     FROM Content
     ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
     ORDER BY id`,
    params,
  );
  return rows;
};

const listAlphabets = async ({ level } = {}) => {
  const params = [];
  let query = `
    SELECT id, letter, ill_word, ill_image, letter_sound, word_audio,
           letter_type, coursename, subcategory, category, language,
           title_image, level, created
    FROM Alphabets
  `;

  if (level) {
    query += ' WHERE level = ?';
    params.push(level);
  }

  query += ' ORDER BY id';
  const [rows] = await pool.execute(query, params);
  return rows;
};

const listQuizzes = async ({ topic } = {}) => {
  const params = [];
  let query = `
    SELECT id, Question, ca, o1, o2, o3, Instruction, audio, image,
           RAFeed, WAFeed, difflvl, topic, QType, created, Language,
           q_audio, raf_audio, waf_audio
    FROM quizz
  `;

  if (topic) {
    query += ' WHERE topic = ?';
    params.push(topic);
  }

  query += ' ORDER BY id';
  const [rows] = await pool.execute(query, params);
  return rows;
};

const listStories = async () => {
  const [rows] = await pool.execute(
    `SELECT id, title, text, created, language, image, audio, title_image,
            grade, audio_text_map, show_plan, title_audio
     FROM stories
     ORDER BY id`,
  );
  return rows;
};

const listPhonics = async ({ course, category, subcategory } = {}) => {
  const where = [];
  const params = [];

  if (course) {
    where.push('coursename = ?');
    params.push(course);
  }
  if (category) {
    where.push('category = ?');
    params.push(category);
  }
  if (subcategory) {
    where.push('subcategory = ?');
    params.push(subcategory);
  }

  const [rows] = await pool.execute(
    `SELECT id, sentence, word, image, sentence_sound, word_audio,
            coursename, language, category, subcategory, created, title_image, level
     FROM Phonics
     ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
     ORDER BY id`,
    params,
  );
  return rows;
};

const listPlans = async () => {
  const [rows] = await pool.execute(
    `SELECT id, name, type, amount, permission, plan_timeperiod
     FROM subsc_plans
     ORDER BY id`,
  );
  return rows;
};

module.exports = {
  listLanguages,
  listCategories,
  listSubcategories,
  listCourses,
  listContent,
  listAlphabets,
  listQuizzes,
  listPhonics,
  listStories,
  listPlans,
};
