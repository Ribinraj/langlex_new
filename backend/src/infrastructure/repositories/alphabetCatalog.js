const { pool } = require('../database/db');
const { pagination, pageResult } = require('../../shared/utils/pagination');

// Explicit teaching order, independent of insertion order and database collation.
const sequences = {
  hindi: 'अ आ इ ई उ ऊ ऋ ए ऐ ओ औ ऑ अं अः क ख ग घ ङ च छ ज झ ञ ट ठ ड ड़ ढ ढ़ ण त थ द ध न प फ ब भ म य र ल व श ष स ह क्ष त्र ज्ञ',
  maithili: 'अ आ इ ई उ ऊ ऋ ए ऐ ओ औ ऑ अं अः क ख ग घ ङ च छ ज झ ञ ट ठ ड ड़ ढ ढ़ ण त थ द ध न प फ ब भ म य र ल व श ष स ह क्ष त्र ज्ञ',
  kannada: 'ಅ ಆ ಇ ಈ ಉ ಊ ಋ ಎ ಏ ಐ ಒ ಓ ಔ ಅಂ ಅಃ ಕ ಖ ಗ ಘ ಙ ಚ ಛ ಜ ಝ ಞ ಟ ಠ ಡ ಡ಼ ಢ ಢ಼ ಣ ತ ಥ ದ ಧ ನ ಪ ಫ ಬ ಭ ಮ ಯ ರ ಲ ವ ಶ ಷ ಸ ಹ ಕ್ಷ ತ್ರ ಜ್ಞ',
  english: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').join(' '),
};
const orderSql = `CASE LOWER(language) ${Object.entries(sequences).map(([language, sequence]) => {
  const values = sequence.split(' ').map((letter) => `'${letter}'`).join(',');
  return `WHEN '${language}' THEN COALESCE(NULLIF(FIELD(BINARY TRIM(letter),${values}),0),1000)`;
}).join(' ')} ELSE 1000 END`;

function groupLetters(rows) {
  const groups = new Map();
  for (const row of rows) {
    const { group_id, example_count, ...example } = row;
    if (!groups.has(group_id)) groups.set(group_id, { ...example, example_count: Number(example_count), examples: [] });
    groups.get(group_id).examples.push(example);
  }
  return [...groups.values()];
}

async function listLetters(query, where) {
  const paging = pagination(query);
  const cte = `WITH ranked AS (
    SELECT *, ${orderSql} AS letter_order,
      CASE WHEN LOWER(letter_type) IN ('barahkhari','gunitakshara') THEN 1 WHEN LOWER(letter_type) = 'special' THEN 2 ELSE 0 END AS stage
    FROM Alphabets ${where.sql}
  ), lessons AS (
    SELECT language, coursename, MIN(stage) AS stage, MIN(letter_order) AS lesson_order FROM ranked GROUP BY language, coursename
  ), letters AS (
    SELECT MIN(id) AS group_id, language, coursename, BINARY TRIM(letter) AS letter_key,
      MIN(letter_order) AS letter_order, MIN(stage) AS stage, COUNT(*) AS example_count
    FROM ranked GROUP BY language, coursename, BINARY TRIM(letter)
  )`;
  const [[count]] = await pool.query(`${cte} SELECT COUNT(*) AS total FROM letters`, where.params);
  const [rows] = await pool.query(`${cte}
    SELECT r.*, selected.group_id, selected.example_count,
      CONCAT('alphabet-', (SELECT MIN(a.id) FROM Alphabets a WHERE a.language=r.language AND a.coursename=r.coursename AND BINARY TRIM(a.letter)=BINARY TRIM(r.letter))) AS progress_key
      FROM ranked r JOIN (
      SELECT g.*, l.stage AS lesson_stage, l.lesson_order FROM letters g
      JOIN lessons l ON l.language = g.language AND l.coursename = g.coursename
      ORDER BY g.language, l.stage, l.lesson_order, g.coursename, g.stage, g.letter_order, g.group_id LIMIT ? OFFSET ?
    ) selected ON r.language = selected.language AND r.coursename = selected.coursename AND BINARY TRIM(r.letter) = selected.letter_key
    ORDER BY selected.language, selected.lesson_stage, selected.lesson_order, selected.coursename, selected.stage, selected.letter_order, selected.group_id, r.id`, [...where.params, paging.limit, paging.offset]);
  return pageResult(groupLetters(rows.map(({ letter_order, stage, ...row }) => row)), count.total, paging);
}
module.exports = { listLetters, groupLetters, sequences };
