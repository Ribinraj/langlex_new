const app = require('./app');
const env = require('./infrastructure/config/env');
const { pool } = require('./infrastructure/database/db');
const initializeDatabase = require('./infrastructure/database/initDatabase');

const start = async () => {
  await initializeDatabase();
  await pool.query('SELECT 1');
  app.listen(env.port, () => {
    console.log(`LangLex API running on http://localhost:${env.port}`);
  });
};

start().catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});
