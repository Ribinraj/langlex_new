const mysql = require('mysql2/promise');
const { AsyncLocalStorage } = require('node:async_hooks');
const env = require('../config/env');
const transactions = new AsyncLocalStorage();
const rawPool = mysql.createPool(env.db);
const createBootstrapConnection = () =>
  mysql.createConnection({
    host: env.db.host,
    port: env.db.port,
    user: env.db.user,
    password: env.db.password,
    multipleStatements: true,
  });
// Repository transactions join the enclosing admin operation. Only the owner commits.
const pool = new Proxy(rawPool, {
  get(target, key) {
    const connection = transactions.getStore();
    if (connection && (key === 'query' || key === 'execute'))
      return connection[key].bind(connection);
    if (connection && key === 'getConnection')
      return async () =>
        new Proxy(connection, {
          get(conn, method) {
            if (
              ['beginTransaction', 'commit', 'rollback', 'release'].includes(
                method,
              )
            )
              return async () => {};
            const value = conn[method];
            return typeof value === 'function' ? value.bind(conn) : value;
          },
        });
    const value = target[key];
    return typeof value === 'function' ? value.bind(target) : value;
  },
});
const withTransaction = async (work, { rollback = false } = {}) => {
  if (transactions.getStore()) {
    if (rollback) throw new Error('A preview must own its transaction');
    return work();
  }
  const connection = await rawPool.getConnection();
  try {
    await connection.query('SET TRANSACTION ISOLATION LEVEL READ COMMITTED');
    await connection.beginTransaction();
    const result = await transactions.run(connection, work);
    if (rollback) await connection.rollback();
    else await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};
module.exports = { pool, createBootstrapConnection, withTransaction };
