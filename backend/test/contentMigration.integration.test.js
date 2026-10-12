const test = require('node:test');
const assert = require('node:assert/strict');

test('MySQL content migration is atomic, preserves accounts, and does not overwrite later edits',
  { skip: process.env.RUN_DB_TESTS !== '1' }, async () => {
    // Always use a new isolated database, never the configured application database.
    process.env.DB_NAME = `langlex_import_test_${process.pid}_${Date.now()}`;
    const initializeDatabase = require('../src/infrastructure/database/initDatabase');
    const { pool, createBootstrapConnection } = require('../src/infrastructure/database/db');
    const { importOriginalContent } = require('../src/infrastructure/database/originalContent');
    const database = process.env.DB_NAME;
    try {
      await initializeDatabase();
      await pool.query("INSERT INTO users (mobile_number, full_name) VALUES ('1000000000', 'Migration test')");
      await pool.query("UPDATE courses SET title = 'Admin edited title' WHERE id = 308");
      assert.equal(await importOriginalContent(pool), false);
      const [[course]] = await pool.query('SELECT title FROM courses WHERE id = 308');
      assert.equal(course.title, 'Admin edited title');
      await pool.query('DELETE FROM content_migrations');
      await pool.query('DELETE FROM content_migration_backups');
      const failingPool = {
        query: (...args) => pool.query(...args),
        getConnection: async () => {
          const connection = await pool.getConnection();
          return new Proxy(connection, { get(target, property) {
            if (property === 'query') return (sql, ...args) => {
              if (sql.startsWith('INSERT INTO `Content`')) throw new Error('Injected insert failure');
              return target.query(sql, ...args);
            };
            return typeof target[property] === 'function' ? target[property].bind(target) : target[property];
          } });
        },
      };
      await assert.rejects(importOriginalContent(failingPool), /Injected insert failure/);
      const [[unchanged]] = await pool.query('SELECT title FROM courses WHERE id = 308');
      assert.equal(unchanged.title, 'Admin edited title');
      const [[count]] = await pool.query('SELECT COUNT(*) AS n FROM Content');
      assert.equal(count.n, 8371);
      const [[backup]] = await pool.query('SELECT COUNT(*) AS n FROM content_migration_backups');
      assert.equal(backup.n, 0);
      const [[users]] = await pool.query('SELECT COUNT(*) AS n FROM users');
      assert.equal(users.n, 1);
      assert.equal(await importOriginalContent(pool), true);
      const [[preserved]] = await pool.query('SELECT COUNT(*) AS n FROM users');
      assert.equal(preserved.n, 1);
    } finally {
      await pool.end();
      const connection = await createBootstrapConnection();
      await connection.query(`DROP DATABASE IF EXISTS \`${database}\``);
      await connection.end();
    }
  });
