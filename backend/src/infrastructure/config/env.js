const dotenv = require('dotenv');

dotenv.config();

const required = ['DB_HOST', 'DB_USER', 'DB_NAME', 'JWT_SECRET'];

for (const key of required) {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
}

module.exports = {
  nodeEnv: process.env.NODE_ENV || 'development',
  host: process.env.HOST || undefined,
  port: Number(process.env.PORT || 5050),
  apiPrefix: process.env.API_PREFIX || '/api',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  db: {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: Number(process.env.DB_CONNECTION_LIMIT || 10),
    queueLimit: 0,
  },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  },
  otp: {
    exposeCode: process.env.OTP_EXPOSE_CODE === 'true',
    expiryMinutes: Number(process.env.OTP_EXPIRY_MINUTES || 5),
    resendCooldownSeconds: Number(process.env.OTP_RESEND_COOLDOWN_SECONDS || 30),
    fixedMobileNumber: process.env.OTP_FIXED_MOBILE_NUMBER || '9946802969',
    fixedCode: process.env.OTP_FIXED_CODE || '123456',
  },
  admin: {
    email: process.env.ADMIN_EMAIL || 'crisanttechnologies@gmail.com',
    password: process.env.ADMIN_PASSWORD || 'M@njula1105',
    name: process.env.ADMIN_NAME || 'Crisant Technologies',
  },
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || '',
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL || '',
    privateKey: process.env.FIREBASE_PRIVATE_KEY || '',
  },
};
