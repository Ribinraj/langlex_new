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
    if (language && /\p{L}/u.test(language)) languages.set(language.toLowerCase(), language);
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

const listPlans = async () => {
  const [rows] = await pool.execute(
    `SELECT id, name, type, amount, permission, plan_timeperiod
     FROM subsc_plans
     ORDER BY id`,
  );
  return rows;
};

module.exports = { listLanguages, listPlans };
