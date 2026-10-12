const test = require('node:test');
const assert = require('node:assert/strict');
const { loadCatalog, normalizeValue, TABLES } = require('../src/infrastructure/database/originalContent');
const { groupStoryPassages, addMissingCourses } = require('../src/application/learning/catalogAdapter');
const { buildExpiry } = require('../src/shared/utils/subscriptionExpiry');
const catalog = loadCatalog();
const rows = (name) => catalog.tables[name].rows.map((row) => Object.fromEntries(catalog.tables[name].columns.map((column, i) => [column, row[i]])));

test('the shipped catalog contains all original learning rows and no legacy accounts', () => {
  assert.deepEqual(Object.keys(catalog.tables), TABLES);
  assert.equal(rows('Content').length, 8371);
  assert.equal(rows('Alphabets').length, 2371);
  assert.equal(rows('quizz').length, 3771);
  assert.equal(rows('Phonics').length, 1226);
  assert.equal(rows('Content')[1].content, 'बिल्ली');
  for (const table of TABLES) assert.equal(new Set(rows(table).map((row) => row.id)).size, rows(table).length);
});

test('legacy media resolves to the original HTTPS host and missing audio stays empty', () => {
  assert.equal(normalizeValue('Content', 'word_audio', '/media/audio/cat.mp3\r'), 'https://kids.langlex.com/media/audio/cat.mp3');
  assert.equal(normalizeValue('Content', 'content_audio', 'NULL'), '');
  assert.equal(normalizeValue('quizz', 'o1', 'ಕೋಆಲಾ '), 'ಕೋಆಲಾ ');
  assert.equal(normalizeValue('quizz', 'ca', '/media/audio/a.mp3'), 'https://kids.langlex.com/media/audio/a.mp3');
  assert.equal(normalizeValue('Alphabets', 'ill_image', '/media/images/content_image/hindi-alphabet/oum.png'), 'https://kids.langlex.com/media/images/content_image/hindi-alphabet/oum.PNG');
  assert.equal(normalizeValue('stories', 'audio_text_map', '/media/story.txt'), 'https://kids.langlex.com/media/story.txt');
  assert.equal(normalizeValue('courses', 'language', 'english'), 'English');
  assert.equal(normalizeValue('subsc_plans', 'permission', 'Lorem ipsum'), '[]');
});

test('108 original passages become 11 complete stories without crossing languages', () => {
  const grouped = groupStoryPassages(rows('stories'));
  assert.equal(grouped.length, 11);
  assert.equal(grouped.reduce((sum, story) => sum + story.sections.length, 0), 108);
  for (const story of grouped) {
    assert.ok(story.text.includes(story.sections.at(-1).text));
    assert.ok(story.sections.every((section, i, all) => !i || section.id > all[i - 1].id));
  }
});

test('Assamese vocabulary gains courses without inventing lesson text or exposing Skip records', () => {
  const content = rows('Content').filter((row) => row.content && row.content.toLowerCase() !== 'skip');
  const courses = addMissingCourses(rows('courses'), content);
  assert.equal(courses.filter((course) => course.language === 'Assamese').length, 46);
  assert.equal(courses.filter((course) => course.title.toLowerCase() === 'skip').length, 0);
  assert.equal(new Set(courses.map((course) => course.id)).size, courses.length);
});

test('original Monthly plans expire after a calendar month, including month-end', () => {
  assert.equal(buildExpiry(new Date('2026-01-31T10:00:00Z'), 'Monthly').toISOString(), '2026-02-28T10:00:00.000Z');
  assert.equal(buildExpiry(new Date('2026-09-17T10:00:00Z'), '30 days').toISOString(), '2026-10-17T10:00:00.000Z');
  assert.equal(buildExpiry(new Date(), 'lifetime'), null);
});
