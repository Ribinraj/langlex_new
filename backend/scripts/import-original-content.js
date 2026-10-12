const initializeDatabase = require('../src/infrastructure/database/initDatabase');
const { pool } = require('../src/infrastructure/database/db');
initializeDatabase()
  .catch((error) => { console.error('Content import failed:', error.message); process.exitCode = 1; })
  .finally(() => pool.end());
