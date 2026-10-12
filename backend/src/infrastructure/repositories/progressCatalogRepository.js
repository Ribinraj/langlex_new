const { pool } = require('../database/db');
const { courseCte } = require('./catalogRepository');
const premium = (value) =>
  ['1', 'premium', 'paid'].includes(
    String(value || '')
      .trim()
      .toLowerCase(),
  );
const group = (rows, key) => {
  const result = new Map();
  for (const row of rows) {
    const k = key(row);
    if (!result.has(k)) result.set(k, []);
    result.get(k).push(row);
  }
  return [...result.values()];
};

// Read only membership/labels; no media or question payloads are sent to the dashboard.
async function topics(language, level, executor = pool) {
  const queries = [
    [
      `${courseCte} SELECT * FROM catalog WHERE language=? ORDER BY id`,
      [language],
    ],
    [
      "SELECT id,course,category FROM Content WHERE language=? AND TRIM(content)<>'' AND LOWER(TRIM(content))<>'skip' AND LOWER(TRIM(course))<>'skip' ORDER BY id",
      [language],
    ],
    [
      "SELECT q.id,q.topic,q.ca,COALESCE(s.show_plan,'Free') AS show_plan FROM quizz q LEFT JOIN quiz_topic_settings s ON s.language=q.Language AND s.topic=q.topic WHERE q.Language=? ORDER BY q.id",
      [language],
    ],
    [
      'SELECT id,coursename FROM Phonics WHERE language=? ORDER BY id',
      [language],
    ],
    [
      'SELECT id,coursename,letter FROM Alphabets WHERE language=? ORDER BY id',
      [language],
    ],
    [
      'SELECT id,title,grade,show_plan FROM stories WHERE language=? ORDER BY id',
      [language],
    ],
  ];
  const [courses, words, quizzes, sounds, letters, stories] = await Promise.all(
    queries.map(async ([sql, args]) => (await executor.query(sql, args))[0]),
  );
  const wordGroups = new Map(
    group(words, (r) => r.course).map((rows) => [rows[0].course, rows]),
  );
  const make = (type, key, title, rows, locked = false) => ({
    content_type: type,
    content_key: key,
    title,
    language,
    premium: locked,
    items: rows.map((r) => ({ id: Number(r.id), answer: r.ca })),
  });
  const all = [
    ...courses.map((c) =>
      make(
        'course',
        `course-${c.id}`,
        c.title,
        wordGroups.get(c.title) || [],
        premium(c.show_plan),
      ),
    ),
    ...group(quizzes, (r) => r.topic).map((rows) =>
      make(
        'quiz',
        `quiz-topic-${rows[0].id}`,
        rows[0].topic,
        rows,
        rows.some((row) => premium(row.show_plan)),
      ),
    ),
    ...group(sounds, (r) => r.coursename).map((rows) =>
      make(
        'phonics',
        `phonics-course-${rows[0].id}-${language}`,
        rows[0].coursename,
        rows,
      ),
    ),
    ...group(letters, (r) =>
      JSON.stringify([r.coursename, r.letter.trim()]),
    ).map((rows) =>
      make(
        'alphabet',
        `alphabet-${rows[0].id}`,
        `${rows[0].letter.trim()} · ${rows[0].coursename}`,
        rows,
      ),
    ),
    ...group(stories, (r) => JSON.stringify([r.title, r.grade])).map((rows) =>
      make(
        'story',
        `story-${rows[0].id}`,
        rows[0].title,
        rows,
        rows.some((r) => premium(r.show_plan)),
      ),
    ),
  ];
  if (!level) return all;
  const curriculum = require('./curriculumRepository');
  const mapping = {
    course: 'courses',
    quiz: 'quizzes',
    phonics: 'phonics',
    alphabet: 'alphabets',
    story: 'stories',
  };
  const allowed = {};
  for (const [type, resource] of Object.entries(mapping)) {
    const d = curriculum.definition(resource),
      rule = curriculum.filter(resource, 'r', level);
    const [rows] = await executor.query(
      `SELECT r.id FROM \`${d.table}\` r WHERE r.\`${d.language}\`=? AND ${rule.sql}`,
      [language, ...rule.params],
    );
    allowed[type] = new Set(rows.map((r) => Number(r.id)));
  }
  return all
    .map((t) => ({
      ...t,
      items: t.items.filter((i) => allowed[t.content_type].has(i.id)),
    }))
    .filter((t) => t.items.length);
}

// Resolve legacy session keys as well as canonical topic keys, including older
// sessions that grouped all sounds/quizzes in a language or opened one letter.
async function resolve(
  type,
  key,
  languages,
  executor = pool,
  hasPremium = false,
  level = null,
) {
  for (const language of languages) {
    const all = await topics(language, level, executor);
    const exact = all.find(
      (t) => t.content_type === type && t.content_key === key,
    );
    if (exact) return exact;
    if (type === 'alphabet' && /^alphabet-\d+$/.test(key)) {
      const match = all.find(
        (t) =>
          t.content_type === type &&
          t.items.some((i) => i.id === Number(key.slice(9))),
      );
      if (match) return match;
    }
    if (
      (type === 'phonics' && key === `phonics-${language}`) ||
      (type === 'quiz' &&
        key.toLowerCase() === `quiz-${language}`.toLowerCase())
    ) {
      const matches = all.filter(
        (t) => t.content_type === type && (!t.premium || hasPremium),
      );
      return {
        content_type: type,
        content_key: key,
        title: language,
        language,
        premium: false,
        items: matches.flatMap((t) => t.items),
      };
    }
    if (type === 'phonics' && key.startsWith('alphabet-')) {
      const letter = all.find(
        (t) => t.content_type === 'alphabet' && t.content_key === key,
      );
      if (letter) return { ...letter, content_type: 'alphabet' };
    }
  }
  return null;
}
module.exports = { topics, resolve, premium };
