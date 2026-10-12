const { test } = require('node:test');
const assert = require('node:assert/strict');
const retirePreferences = require('../src/infrastructure/database/retireLearningPreferences');

const mock = (file, exports) => {
  const id = require.resolve(file);
  require.cache[id] = { id, filename: id, loaded: true, exports };
};
let saved;
const statements = [];
const connection = {
  beginTransaction: async () => {},
  commit: async () => {},
  rollback: async () => {},
  release: () => {},
  execute: async (sql, values) => {
    statements.push({ sql, values });
    if (sql.includes('INSERT INTO user_learning_setups')) {
      assert.doesNotMatch(sql, /age_group|daily_goal_minutes/);
      assert.equal(values.length, 8);
      const keys = ['user_id', 'child_name', 'primary_language', 'learning_language', 'level', 'interests', 'selected_languages', 'plan_id'];
      saved = Object.fromEntries(keys.map((key, index) => [key, values[index]]));
      return [{}];
    }
    if (sql.includes('FROM user_learning_setups')) {
      assert.doesNotMatch(sql, /age_group|daily_goal_minutes/);
      return [saved ? [saved] : []];
    }
    if (sql.includes('FROM users') && sql.includes('WHERE id = ?')) {
      return [[{ id: 1, full_name: 'Alex' }]];
    }
    return [[]];
  },
};
mock('../src/infrastructure/database/db', { pool: { ...connection, getConnection: async () => connection } });
mock('../src/infrastructure/repositories/learningRepository', {
  listLanguages: async () => ['English', 'Hindi', 'Kannada'],
  listPlans: async () => [],
});
mock('../src/application/user/userService', {});
mock('../src/application/learning/contentProgressService', {});
mock('../src/interfaces/http/middleware/authMiddleware', (req, _res, next) => {
  req.user = { id: 1, full_name: 'Alex' };
  next();
});
const express = require('express');
const routes = require('../src/interfaces/http/routes/userRoutes');
const adminRepository = require('../src/infrastructure/repositories/adminRepository');

test('setup saves without retired preferences and ignores them from old clients', async (t) => {
  const app = express();
  app.use(express.json());
  app.use('/user', routes);
  app.use((error, _req, res, _next) => res.status(error.statusCode || 500).json({ message: error.message }));
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}/user`;
  const payload = {
    child_name: 'Alex', active_language: 'Hindi',
    selected_languages: ['English', 'Hindi', 'Kannada'], level: 'Nursery',
  };
  for (const body of [payload, { ...payload, age_group: '3-4 years', daily_goal_minutes: 30 }]) {
    const response = await fetch(`${base}/learning-setup`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
    });
    assert.equal(response.status, 200);
    const { learning_setup: setup } = await response.json();
    assert.equal(setup.child_name, 'Alex');
    assert.equal(setup.level, 'Nursery');
    assert.equal(setup.learning_language, 'Hindi');
    assert.deepEqual(setup.selected_languages, payload.selected_languages);
    assert.equal('age_group' in setup, false);
    assert.equal('daily_goal_minutes' in setup, false);
  }
  assert.equal(statements.filter(({ sql }) => sql.includes('INSERT INTO user_learning_setups')).length, 2);
  assert.equal((await fetch(`${base}/daily-goal`)).status, 404);
  assert.equal((await fetch(`${base}/daily-goal/progress`, { method: 'POST' })).status, 404);
});

test('legacy migration preserves values and permits omitted preferences; reruns skip DDL', async () => {
  let columns = [
    { COLUMN_NAME: 'age_group', IS_NULLABLE: 'NO', COLUMN_DEFAULT: null },
    { COLUMN_NAME: 'daily_goal_minutes', IS_NULLABLE: 'NO', COLUMN_DEFAULT: '15' },
  ];
  const queries = [];
  const updates = [];
  const pool = {
    execute: async (sql, params) => {
      if (sql.includes('INFORMATION_SCHEMA')) return [columns];
      updates.push({ sql, params });
      return [{}];
    },
    query: async (sql) => queries.push(sql),
  };
  await retirePreferences(pool, 'test');
  assert.equal(queries.length, 2);
  for (const sql of queries) {
    assert.match(sql, /NULL DEFAULT NULL/);
    assert.doesNotMatch(sql, /DROP|DELETE/);
  }
  assert.match(updates[0].sql, /WHERE type = 'setup' AND title = \? AND body = \?/);
  columns = columns.map((column) => ({ ...column, IS_NULLABLE: 'YES', COLUMN_DEFAULT: null }));
  await retirePreferences(pool, 'test');
  assert.equal(queries.length, 2);
  columns = [];
  await retirePreferences(pool, 'test');
  assert.equal(queries.length, 2);
});

test('admin overview and user details work without the retired daily events table', async () => {
  const start = statements.length;
  const overview = await adminRepository.getOverview();
  const detail = await adminRepository.getUserDetail(1);
  assert.equal('activity_trend' in overview, false);
  assert.equal('daily_events' in detail, false);
  assert.ok(Array.isArray(detail.progress));
  for (const { sql } of statements.slice(start)) {
    assert.doesNotMatch(sql, /user_daily_learning_events|age_group|daily_goal_minutes/);
  }
});
