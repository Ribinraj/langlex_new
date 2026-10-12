const test = require('node:test');
const assert = require('node:assert/strict');

test('catalog pagination covers every record, filters before paging, and keeps stories whole', { skip: process.env.RUN_DB_TESTS !== '1' }, async () => {
  process.env.DB_NAME = `langlex_paging_test_${process.pid}_${Date.now()}`;
  const database = process.env.DB_NAME;
  const initialize = require('../src/infrastructure/database/initDatabase');
  const { pool, createBootstrapConnection } = require('../src/infrastructure/database/db');
  const repository = require('../src/infrastructure/repositories/catalogRepository');
  let server;
  try {
    await initialize();
    for (const [resource, expected] of [['content', 7538], ['alphabets', 2371], ['quizzes', 3771], ['phonics', 1226]]) {
      const ids = [];
      for (let page = 1; ; page++) {
        const result = await repository.list(resource, { page, limit: 100 });
        assert.equal(result.pagination.total, expected);
        assert.ok(result.items.length <= 100);
        ids.push(...result.items.map((row) => row.id));
        if (!result.pagination.has_more) break;
      }
      assert.equal(ids.length, expected);
      assert.equal(new Set(ids).size, expected);
      assert.deepEqual(ids, [...ids].sort((a, b) => a - b));
    }
    const courseIds = [];
    for (let page = 1; page <= 14; page++) {
      const result = await repository.courses({ page, limit: 17 });
      assert.equal(result.pagination.total, 238);
      courseIds.push(...result.items.map((row) => row.id));
    }
    assert.equal(new Set(courseIds).size, 238);
    const hindi = await repository.list('quizzes', { language: 'Hindi', page: 2, limit: 9 });
    assert.equal(hindi.pagination.total, 692);
    assert.ok(hindi.items.every((row) => row.Language === 'Hindi'));
    const english = await repository.list('quizzes', { language: 'English', limit: 4 });
    assert.equal(english.pagination.total, 1251);
    assert.deepEqual(english.items.map((row) => row.ca), ['A', 'A', 'A', 'A']);
    assert.equal(new Set(english.items.map((row) => row.audio)).size, 1);
    const nextEnglish = await repository.list('quizzes', { language: 'English', page: 2, limit: 4 });
    assert.ok(nextEnglish.items.every((row) => !english.items.some((previous) => previous.id === row.id)));
    const filteredQuizzes = await repository.list('quizzes', { language: 'English', topic: english.items[0].topic, search: 'select the correct letter', limit: 100 });
    assert.ok(filteredQuizzes.items.length > 0);
    assert.ok(filteredQuizzes.items.every((row) => row.Language === 'English' && row.topic === english.items[0].topic));
    const quizSets = await repository.list('quizzes', { language: 'English', view: 'sets', limit: 100 });
    assert.equal(quizSets.pagination.total, 35);
    assert.equal(new Set(quizSets.items.map((row) => row.topic)).size, 35);
    assert.equal(quizSets.items[0].topic, 'Alphabet Letter Recognition');
    assert.equal(quizSets.items[0].question_count, 308);
    assert.equal(quizSets.items.reduce((sum, row) => sum + row.question_count, 0), 1251);
    const selectedTopic = await repository.list('quizzes', { language: 'English', topic: quizSets.items[0].topic, limit: 100 });
    assert.equal(selectedTopic.pagination.total, 308);
    const topicRows = [...selectedTopic.items];
    for (let page = 2; page <= selectedTopic.pagination.total_pages; page++) {
      const next = await repository.list('quizzes', { language: 'English', topic: quizSets.items[0].topic, page, limit: 100 });
      topicRows.push(...next.items);
    }
    const [databaseRows] = await pool.query('SELECT * FROM quizz WHERE Language = ? AND topic = ? ORDER BY id', ['English', quizSets.items[0].topic]);
    assert.deepEqual(topicRows, databaseRows, 'Every stored row, including repeated exercises, must be returned unchanged');
    const searchSets = await repository.list('quizzes', { language: 'English', view: 'sets', search: 'Tap to listen to it', limit: 100 });
    assert.equal(searchSets.items[0].id, quizSets.items[0].id);
    assert.equal(searchSets.items[0].question_count, 308);
    const secondSet = await repository.list('quizzes', { language: 'English', view: 'sets', page: 2, limit: 1 });
    assert.equal(secondSet.items[0].topic, 'Pet Animals');
    const assamese = await repository.courses({ language: 'Assamese', limit: 100 });
    assert.equal(assamese.pagination.total, 46);
    const search = await repository.courses({ language: 'English', search: 'Pet Animals', limit: 1 });
    assert.equal(search.pagination.total, 1);
    assert.equal(search.items[0].word_count, 25);
    const words = await repository.list('content', { course: 'Pet Animals', language: 'English', page: 2 });
    assert.equal(words.pagination.total, 25);
    assert.equal(words.items.length, 5);
    const nursery = await repository.list('alphabets', { language: 'Hindi', level: 'Nursery' });
    assert.equal(nursery.pagination.total, 739);
    const soundCategories = [];
    for (let page = 1; page <= 4; page++) {
      const result = await repository.list('phonics', { language: 'Hindi', view: 'courses', page });
      assert.equal(result.pagination.total, 65);
      soundCategories.push(...result.items);
    }
    assert.equal(new Set(soundCategories.map((row) => row.title)).size, 65);
    assert.equal(soundCategories.reduce((total, row) => total + Number(row.sound_count), 0), 613);
    assert.ok(soundCategories.every((row) => row.language === 'Hindi' && !('word' in row) && !('sentence' in row)));
    const selectedSounds = await repository.list('phonics', { language: 'Hindi', course: soundCategories[0].title, limit: 100 });
    assert.equal(selectedSounds.items.length, Number(soundCategories[0].sound_count));
    assert.ok(selectedSounds.items.every((row) => row.coursename === soundCategories[0].title));
    const storyIds = [];
    let passages = 0;
    for (let page = 1; page <= 11; page++) {
      const result = await repository.stories({ page, limit: 1 });
      assert.equal(result.pagination.total, 11);
      assert.equal(result.items.length, 1);
      const story = result.items[0];
      storyIds.push(story.id); passages += story.sections.length;
      const [[expected]] = await pool.query('SELECT COUNT(*) AS n FROM stories WHERE title=? AND language=? AND grade=?', [story.title, story.language, story.grade]);
      assert.equal(story.sections.length, expected.n);
    }
    assert.equal(new Set(storyIds).size, 11);
    assert.equal(passages, 108);
    const options = await repository.options('courses', { language: 'Hindi', page: 6, limit: 20 });
    assert.ok(options.items.length > 0);
    assert.ok(options.pagination.total > 100);
    assert.equal((await repository.list('content', { page: 99999 })).items.length, 0);
    await pool.query("INSERT INTO users (mobile_number, full_name) VALUES ('1000000001', 'Paging test')");
    const [[user]] = await pool.query("SELECT id FROM users WHERE mobile_number='1000000001'");
    for (let i = 0; i < 45; i++) await pool.execute('INSERT INTO notifications (user_id, title, body) VALUES (?, ?, ?)', [user.id, `Notification ${i}`, 'test']);
    const notifications = require('../src/application/notification/notificationService');
    const firstInbox = await notifications.listNotifications({ userId: user.id, page: 1, limit: 20 });
    const lastInbox = await notifications.listNotifications({ userId: user.id, page: 3, limit: 20 });
    assert.equal(firstInbox.notifications.length, 20);
    assert.equal(lastInbox.notifications.length, 5);
    assert.equal(lastInbox.pagination.total, 45);
    assert.equal(lastInbox.unread_count, 45);
    assert.ok(!firstInbox.notifications.some((n) => lastInbox.notifications.some((other) => n.id === other.id)));
    const app = require('../src/app');
    server = app.listen(0, '127.0.0.1');
    await new Promise((resolve) => server.once('listening', resolve));
    const base = `http://127.0.0.1:${server.address().port}/api/`;
    const response = await fetch(base + 'content');
    const body = await response.json();
    assert.equal(body.content.length, 20);
    assert.equal(body.pagination.total, 5272, 'anonymous pagination excludes Login and Premium lessons');
    for (const suffix of ['?limit=100000', '?page=0', '?language[]=Hindi']) {
      assert.equal((await fetch(base + 'content' + suffix)).status, 400);
    }
    console.log('Default content response bytes:', JSON.stringify(body).length);
  } finally {
    if (server) await new Promise((resolve) => server.close(resolve));
    await pool.end();
    const connection = await createBootstrapConnection();
    await connection.query(`DROP DATABASE IF EXISTS \`${database}\``);
    await connection.end();
  }
});
