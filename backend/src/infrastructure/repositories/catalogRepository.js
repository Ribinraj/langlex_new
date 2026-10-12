const { pool } = require('../database/db');
const {
  pagination,
  pageResult,
  textFilter,
} = require('../../shared/utils/pagination');
const { listLetters } = require('./alphabetCatalog');
const {
  groupStoryPassages,
} = require('../../application/learning/catalogAdapter');
const validContent =
  "TRIM(content) <> '' AND LOWER(TRIM(content)) <> 'skip' AND LOWER(TRIM(course)) <> 'skip'";
const levels = require('../../application/learning/standards').aliases;
const curriculum = require('./curriculumRepository');
const definitions = {
  categories: {
    table: 'categories',
    search: ['title'],
    filters: { language: 'language' },
  },
  subcategories: {
    table: 'subcategories',
    search: ['title'],
    filters: { language: 'language', category: 'p_cat' },
  },
  content: {
    table: 'Content',
    search: ['content', 'course'],
    filters: {
      language: 'language',
      course: 'course',
      category: 'category',
      subcategory: 'subcategory',
      level: 'category',
    },
    where: validContent,
  },
  alphabets: {
    table: 'Alphabets',
    search: ['letter', 'ill_word', 'coursename'],
    filters: { language: 'language', level: 'level', course: 'coursename' },
  },
  quizzes: {
    table: 'quizz',
    search: ['Question', 'topic'],
    filters: { language: 'Language', topic: 'topic', level: 'difflvl' },
  },
  phonics: {
    table: 'Phonics',
    search: ['word', 'sentence', 'coursename'],
    filters: {
      language: 'language',
      course: 'coursename',
      category: 'category',
      subcategory: 'subcategory',
      level: 'level',
    },
  },
};
function whereFor(query, definition) {
  const where = definition.where ? [definition.where] : [];
  const params = [];
  for (const [name, column] of Object.entries(definition.filters)) {
    const value = textFilter(query[name], name);
    if (!value) continue;
    const aliases = name === 'level' ? levels[value] || [value] : [value];
    where.push(`\`${column}\` IN (${aliases.map(() => '?').join(',')})`);
    params.push(...aliases);
  }
  const search = textFilter(query.search, 'search');
  if (search) {
    where.push(
      `(${definition.search.map((c) => `LOCATE(?, \`${c}\`) > 0`).join(' OR ')})`,
    );
    params.push(...definition.search.map(() => search));
  }
  return { sql: where.length ? `WHERE ${where.join(' AND ')}` : '', params };
}
async function list(resource, query = {}, access = null) {
  const definition = definitions[resource];
  const paging = pagination(query);
  let { sql, params } = whereFor({ ...query, level: undefined }, definition);
  const standard =
    query.level && !['categories', 'subcategories'].includes(resource)
      ? curriculum.filter(
          resource === 'content' ? 'courses' : resource,
          `\`${definition.table}\``,
          textFilter(query.level, 'level'),
        )
      : { sql: '1=1', params: [] };
  if (query.level) {
    sql += `${sql ? ' AND ' : 'WHERE '}${standard.sql}`;
    params.push(...standard.params);
  }
  if (resource === 'content' && access) {
    const blocked = [
      ...(!access.premium ? ['premium', 'paid', '1'] : []),
      ...(!access.signedIn ? ['login'] : []),
    ];
    if (blocked.length) {
      const rule = `NOT EXISTS (SELECT 1 FROM courses gated WHERE gated.title=Content.course AND gated.language=Content.language AND LOWER(TRIM(gated.show_plan)) IN (${blocked.map(() => '?').join(',')}))`;
      sql += `${sql ? ' AND ' : 'WHERE '}${rule}`;
      params.push(...blocked);
    }
  }
  if (
    resource === 'quizzes' &&
    access &&
    !access.premium &&
    query.view !== 'sets'
  ) {
    sql += `${sql ? ' AND ' : 'WHERE '}NOT EXISTS (SELECT 1 FROM quiz_topic_settings gated WHERE gated.language=quizz.Language AND gated.topic=quizz.topic AND gated.show_plan='Premium')`;
  }
  if (resource === 'alphabets' && query.view === 'letters') {
    const result = await listLetters(query, { sql, params });
    if (query.level)
      result.items = result.items.map((row) => ({
        ...row,
        level: query.level,
      }));
    return result;
  }
  if (resource === 'quizzes' && query.view === 'sets') {
    // Search finds matching topics; opening one always practices the complete
    // topic, retaining every database row even when question content repeats.
    const all = whereFor(
      { ...query, search: undefined, level: undefined },
      definition,
    );
    if (query.level) {
      all.sql += `${all.sql ? ' AND ' : 'WHERE '}${standard.sql}`;
      all.params.push(...standard.params);
    }
    const topics = `SELECT (SELECT MIN(anchor.id) FROM quizz anchor WHERE anchor.Language=q.Language AND anchor.topic=q.topic) AS id, q.Language AS language,
        q.topic, COUNT(*) AS question_count, COALESCE(MAX(settings.show_plan),'Free') AS show_plan
      FROM (SELECT * FROM quizz ${all.sql}) q
      JOIN (SELECT DISTINCT Language, topic FROM quizz ${sql}) matched
        ON matched.Language = q.Language AND matched.topic = q.topic
      LEFT JOIN quiz_topic_settings settings ON settings.language=q.Language AND settings.topic=q.topic
      GROUP BY q.Language, q.topic`;
    const values = [...all.params, ...params];
    const [[count]] = await pool.query(
      `SELECT COUNT(*) AS total FROM (${topics}) quiz_sets`,
      values,
    );
    const [rows] = await pool.query(`${topics} ORDER BY id LIMIT ? OFFSET ?`, [
      ...values,
      paging.limit,
      paging.offset,
    ]);
    return pageResult(
      rows.map((row) => ({
        ...row,
        question_count: Number(row.question_count),
        locked: row.show_plan === 'Premium' && !access?.premium,
      })),
      count.total,
      paging,
    );
  }
  if (resource === 'phonics' && query.view === 'courses') {
    // Page categories, not individual words, so a category appears only once.
    const grouped = `SELECT (SELECT MIN(anchor.id) FROM Phonics anchor WHERE anchor.coursename=Phonics.coursename AND anchor.language=Phonics.language) AS id, coursename AS title, language,
      COUNT(*) AS sound_count FROM Phonics ${sql} GROUP BY coursename, language`;
    const [[count]] = await pool.query(
      `SELECT COUNT(*) AS total FROM (${grouped}) sound_courses`,
      params,
    );
    const [rows] = await pool.query(`${grouped} ORDER BY id LIMIT ? OFFSET ?`, [
      ...params,
      paging.limit,
      paging.offset,
    ]);
    return pageResult(rows, count.total, paging);
  }
  const [[count]] = await pool.query(
    `SELECT COUNT(*) AS total FROM \`${definition.table}\` ${sql}`,
    params,
  );
  const [rows] = await pool.query(
    `SELECT * FROM \`${definition.table}\` ${sql} ORDER BY id LIMIT ? OFFSET ?`,
    [...params, paging.limit, paging.offset],
  );
  return pageResult(
    query.level
      ? rows.map((row) => ({
          ...row,
          ...(resource === 'quizzes'
            ? { difflvl: query.level }
            : ['alphabets', 'phonics'].includes(resource)
              ? { level: query.level }
              : {}),
        }))
      : rows,
    count.total,
    paging,
  );
}
const courseCte = `WITH stats AS (
  SELECT course, language, MIN(id) AS first_id, COUNT(*) AS word_count,
    MIN(category) AS category, GROUP_CONCAT(DISTINCT category ORDER BY category SEPARATOR '|') AS levels,
    MIN(content_image) AS image, MIN(created) AS created
  FROM Content WHERE ${validContent} GROUP BY course, language
), catalog AS (
  SELECT c.id, c.title, c.created, c.image, c.language, c.show_plan,
    COALESCE(s.word_count, 0) AS word_count, COALESCE(s.category, '') AS category, COALESCE(s.levels, '') AS levels
  FROM courses c LEFT JOIN stats s ON s.course = c.title AND s.language = c.language
  UNION ALL
  SELECT 1000000 + s.first_id, s.course, s.created, s.image, s.language, '', s.word_count, s.category, s.levels
  FROM stats s WHERE NOT EXISTS (SELECT 1 FROM courses c WHERE c.title = s.course AND c.language = s.language)
)`;
async function courses(query = {}) {
  const paging = pagination(query);
  const { sql, params } = whereFor(query, {
    filters: { language: 'language', category: 'category' },
    search: ['title', 'category', 'language'],
  });
  const level = textFilter(query.level, 'level');
  const eligible = curriculum.filter('courses', 'cw', level);
  const membership = `SELECT COUNT(*) FROM Content cw WHERE cw.course=catalog.title AND cw.language=catalog.language AND TRIM(cw.content)<>'' AND LOWER(TRIM(cw.content))<>'skip' AND ${eligible.sql}`;
  const scope = level ? `${sql ? ' AND ' : 'WHERE '}(${membership})>0` : '';
  const args = [...params, ...(level ? eligible.params : [])];
  const [[count]] = await pool.query(
    `${courseCte} SELECT COUNT(*) AS total FROM catalog ${sql}${scope}`,
    args,
  );
  const [rows] = await pool.query(
    `${courseCte} SELECT * FROM catalog ${sql}${scope} ORDER BY id LIMIT ? OFFSET ?`,
    [...args, paging.limit, paging.offset],
  );
  for (const row of rows) {
    if (level) {
      const [[total]] = await pool.query(
        `SELECT COUNT(*) AS total FROM Content cw WHERE cw.course=? AND cw.language=? AND TRIM(cw.content)<>'' AND LOWER(TRIM(cw.content))<>'skip' AND ${eligible.sql}`,
        [row.title, row.language, ...eligible.params],
      );
      row.word_count = Number(total.total);
      row.levels = [level];
    } else row.levels = row.levels ? row.levels.split('|') : [];
  }
  return pageResult(rows, count.total, paging);
}
async function stories(query = {}) {
  const paging = pagination(query);
  let { sql, params } = whereFor(query, {
    filters: { language: 'language' },
    search: ['title', 'text'],
  });
  const eligible = curriculum.filter(
    'stories',
    'stories',
    textFilter(query.level, 'level'),
  );
  if (query.level) {
    sql += `${sql ? ' AND ' : 'WHERE '}${eligible.sql}`;
    params.push(...eligible.params);
  }
  const grouped = `SELECT MIN(id) AS id, title, language, grade FROM stories ${sql} GROUP BY title, language, grade`;
  const [[count]] = await pool.query(
    `SELECT COUNT(*) AS total FROM (${grouped}) grouped`,
    params,
  );
  // Page complete story groups first, then retrieve all passages of only those stories.
  const [rows] = await pool.query(
    `SELECT s.* FROM stories s JOIN (${grouped} ORDER BY id LIMIT ? OFFSET ?) selected
    ON s.title = selected.title AND s.language = selected.language AND s.grade = selected.grade ORDER BY selected.id, s.id`,
    [...params, paging.limit, paging.offset],
  );
  const allowed = query.level
    ? new Set(
        (
          await pool.query(
            `SELECT id FROM stories WHERE ${eligible.sql}`,
            eligible.params,
          )
        )[0].map((r) => Number(r.id)),
      )
    : null;
  const groupedStories = groupStoryPassages(
    allowed ? rows.filter((r) => allowed.has(Number(r.id))) : rows,
  );
  for (const story of groupedStories) {
    const [[anchor]] = await pool.query(
      `SELECT MIN(id) AS id, CASE WHEN SUM(LOWER(TRIM(show_plan)) IN ('premium','paid','1'))>0 THEN 'Premium' WHEN SUM(LOWER(TRIM(show_plan))='login')>0 THEN 'Login' ELSE 'Free' END AS show_plan FROM stories WHERE title=? AND language=? AND grade=?`,
      [story.title, story.language, story.grade],
    );
    story.id = anchor.id;
    story.show_plan = anchor.show_plan;
    if (query.level) story.grade = query.level;
  }
  return pageResult(groupedStories, count.total, paging);
}
module.exports = { list, courses, stories };

async function options(resource, query = {}) {
  const sources = {
    categories: 'SELECT title, language FROM categories',
    subcategories: 'SELECT title, language FROM subcategories',
    courses: `SELECT title, language FROM courses UNION SELECT course AS title, language FROM Content WHERE ${validContent} UNION SELECT coursename AS title, language FROM Alphabets UNION SELECT coursename AS title, language FROM Phonics`,
    topics: 'SELECT topic AS title, Language AS language FROM quizz',
  };
  if (!sources[resource])
    throw new (require('../../shared/errors/apiError'))(
      'Unknown option resource',
      404,
    );
  const paging = pagination(query);
  const { sql, params } = whereFor(query, {
    where: "TRIM(title) <> ''",
    filters: { language: 'language' },
    search: ['title'],
  });
  const grouped = `SELECT DISTINCT title FROM (${sources[resource]}) options ${sql}`;
  const [[count]] = await pool.query(
    `SELECT COUNT(*) AS total FROM (${grouped}) matched`,
    params,
  );
  const [rows] = await pool.query(
    `${grouped} ORDER BY title LIMIT ? OFFSET ?`,
    [...params, paging.limit, paging.offset],
  );
  return pageResult(
    rows.map((row) => row.title),
    count.total,
    paging,
  );
}
module.exports.options = options;
module.exports.courseCte = courseCte;
module.exports.levels = levels;
