const jwt = require('jsonwebtoken');
const env = require('../../infrastructure/config/env');

const signToken = (user) =>
  jwt.sign(
    {
      sub: String(user.id),
      mobile_number: user.mobile_number,
    },
    env.jwt.secret,
    { expiresIn: env.jwt.expiresIn },
  );

const verifyToken = (token) => jwt.verify(token, env.jwt.secret);

module.exports = {
  signToken,
  verifyToken,
};
