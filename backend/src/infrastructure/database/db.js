const mysql = require('mysql2/promise');
const env = require('../config/env');

const createBootstrapConnection = () =>
  mysql.createConnection({
    host: env.db.host,
    port: env.db.port,
    user: env.db.user,
    password: env.db.password,
    multipleStatements: true,
  });

const pool = mysql.createPool(env.db);

module.exports = {
  pool,
  createBootstrapConnection,
};
