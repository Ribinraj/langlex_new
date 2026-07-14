const cors = require('cors');
const express = require('express');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const rateLimit = require('express-rate-limit');

const env = require('./infrastructure/config/env');
const authRoutes = require('./interfaces/http/routes/authRoutes');
const learningRoutes = require('./interfaces/http/routes/learningRoutes');
const notificationRoutes = require('./interfaces/http/routes/notificationRoutes');
const paymentRoutes = require('./interfaces/http/routes/paymentRoutes');
const subscriptionRoutes = require('./interfaces/http/routes/subscriptionRoutes');
const userRoutes = require('./interfaces/http/routes/userRoutes');
const {
  errorHandler,
  notFound,
} = require('./interfaces/http/middleware/errorHandler');

const app = express();

app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors({ origin: env.corsOrigin === '*' ? true : env.corsOrigin }));
app.use(express.json({ limit: '1mb' }));
app.use(morgan(env.nodeEnv === 'production' ? 'combined' : 'dev'));
app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 200,
    standardHeaders: true,
    legacyHeaders: false,
  }),
);

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.use(
  '/media',
  express.static(path.join(__dirname, '..', 'public', 'media'), {
    immutable: env.nodeEnv === 'production',
    maxAge: env.nodeEnv === 'production' ? '30d' : 0,
  }),
);

app.use(`${env.apiPrefix}/auth`, authRoutes);
app.use(`${env.apiPrefix}/payments`, paymentRoutes);
app.use(`${env.apiPrefix}/subscriptions`, subscriptionRoutes);
app.use(`${env.apiPrefix}/notifications`, notificationRoutes);
app.use(`${env.apiPrefix}/user`, userRoutes);
app.use(env.apiPrefix, learningRoutes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
