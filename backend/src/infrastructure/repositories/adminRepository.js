const { pool } = require('../database/db');
const ApiError = require('../../shared/errors/apiError');
const subscriptionStatusSql = "CASE WHEN us.status = 'active' AND us.expires_at IS NOT NULL AND us.expires_at <= NOW() THEN 'expired' WHEN us.status = 'active' AND us.started_at > NOW() THEN 'scheduled' ELSE us.status END";

const adminPublicColumns =
  'id, full_name, email, role, is_active, last_login_at, created_at, updated_at';

const learningResources = {
  categories: {
    table: 'categories',
    columns: ['title', 'created', 'image', 'language'],
    search: ['title', 'language'],
  },
  subcategories: {
    table: 'subcategories',
    columns: ['title', 'created', 'image', 'p_cat', 'language'],
    search: ['title', 'p_cat', 'language'],
  },
  courses: {
    table: 'courses',
    columns: ['title', 'created', 'image', 'language', 'show_plan'],
    search: ['title', 'language', 'show_plan'],
  },
  content: {
    table: 'Content',
    columns: [
      'content',
      'created',
      'content_image',
      'content_audio',
      'word_audio',
      'course',
      'subcategory',
      'category',
      'language',
    ],
    search: ['content', 'course', 'subcategory', 'category', 'language'],
  },
  alphabets: {
    table: 'Alphabets',
    columns: [
      'letter',
      'ill_word',
      'ill_image',
      'letter_sound',
      'word_audio',
      'letter_type',
      'coursename',
      'subcategory',
      'category',
      'language',
      'title_image',
      'level',
      'created',
    ],
    search: ['letter', 'ill_word', 'coursename', 'category', 'language', 'level'],
  },
  quizzes: {
    table: 'quizz',
    columns: [
      'Question',
      'ca',
      'o1',
      'o2',
      'o3',
      'Instruction',
      'audio',
      'image',
      'RAFeed',
      'WAFeed',
      'difflvl',
      'topic',
      'QType',
      'created',
      'Language',
      'q_audio',
      'raf_audio',
      'waf_audio',
    ],
    search: ['Question', 'ca', 'topic', 'difflvl', 'Language'],
  },
  phonics: {
    table: 'Phonics',
    columns: [
      'sentence',
      'word',
      'image',
      'sentence_sound',
      'word_audio',
      'coursename',
      'language',
      'category',
      'subcategory',
      'created',
      'title_image',
      'level',
    ],
    search: ['sentence', 'word', 'coursename', 'category', 'language', 'level'],
  },
  stories: {
    table: 'stories',
    columns: [
      'title',
      'text',
      'created',
      'language',
      'image',
      'audio',
      'title_image',
      'grade',
      'audio_text_map',
      'show_plan',
      'title_audio',
    ],
    search: ['title', 'text', 'language', 'grade'],
  },
  plans: {
    table: 'subsc_plans',
    columns: ['name', 'type', 'amount', 'permission', 'plan_timeperiod'],
    search: ['name', 'type', 'amount', 'plan_timeperiod'],
    jsonColumns: ['permission'],
  },
};

const clampLimit = (limit) => Math.min(Math.max(Number(limit) || 10, 1), 100);

const offsetFor = (page, limit) => (Math.max(Number(page) || 1, 1) - 1) * limit;

const like = (value) => `%${String(value || '').trim()}%`;

const dateOnly = (date) => new Date(date).toISOString().slice(0, 10);

const findAdminByEmail = async (email) => {
  const [rows] = await pool.execute(
    `SELECT id, full_name, email, password_hash, role, is_active, last_login_at,
            created_at, updated_at
     FROM admin_users
     WHERE email = ?
     LIMIT 1`,
    [email.trim().toLowerCase()],
  );
  return rows[0] || null;
};

const findAdminById = async (id) => {
  const [rows] = await pool.execute(
    `SELECT ${adminPublicColumns}
     FROM admin_users
     WHERE id = ?
     LIMIT 1`,
    [id],
  );
  return rows[0] || null;
};

const updateAdminLogin = async (id) => {
  await pool.execute('UPDATE admin_users SET last_login_at = NOW() WHERE id = ?', [
    id,
  ]);
  return findAdminById(id);
};

const getOverview = async () => {
  const [
    [users],
    [courses],
    [content],
    [quizzes],
    [activeSubscriptions],
    [orders],
    [revenue],
    [completed],
    [notifications],
  ] = await Promise.all([
    pool.execute('SELECT COUNT(*) AS total FROM users'),
    pool.execute("SELECT COUNT(*) AS total FROM learning_topics WHERE resource='courses'"),
    pool.execute('SELECT COUNT(*) AS total FROM Content'),
    pool.execute('SELECT COUNT(*) AS total FROM quizz'),
    pool.execute(
      `SELECT COUNT(*) AS total
       FROM user_subscriptions
       WHERE status = 'active' AND started_at <= NOW() AND (expires_at IS NULL OR expires_at > NOW())`,
    ),
    pool.execute('SELECT COUNT(*) AS total FROM payment_orders'),
    pool.execute(
      `SELECT COALESCE(SUM(CAST(amount AS DECIMAL(12,2))), 0) AS total
       FROM payment_orders
       WHERE status = 'paid'`,
    ),
    pool.execute(
      `SELECT COUNT(*) AS total
       FROM user_content_progress
       WHERE status = 'completed'`,
    ),
    pool.execute(
      `SELECT COUNT(*) AS total
       FROM notifications
       WHERE is_read = FALSE`,
    ),
  ]);

  const [recentUsers] = await pool.execute(
    `SELECT id, full_name, mobile_number, email, school, city, state, created_at
     FROM users
     ORDER BY created_at DESC
     LIMIT 6`,
  );
  const [revenueTrend] = await pool.execute(
    `SELECT DATE(updated_at) AS date, COALESCE(SUM(CAST(amount AS DECIMAL(12,2))), 0) AS revenue
     FROM payment_orders
     WHERE status = 'paid' AND updated_at >= DATE_SUB(CURDATE(), INTERVAL 13 DAY)
     GROUP BY DATE(updated_at)
     ORDER BY DATE(updated_at)`,
  );
  const [contentMix] = await pool.execute(
    `SELECT content_type, COUNT(*) AS total
     FROM user_content_progress
     GROUP BY content_type
     ORDER BY total DESC`,
  );

  return {
    stats: {
      users: Number(users[0]?.total || 0),
      courses: Number(courses[0]?.total || 0),
      content: Number(content[0]?.total || 0),
      quizzes: Number(quizzes[0]?.total || 0),
      active_subscriptions: Number(activeSubscriptions[0]?.total || 0),
      payment_orders: Number(orders[0]?.total || 0),
      revenue: Number(revenue[0]?.total || 0),
      completed_sessions: Number(completed[0]?.total || 0),
      unread_notifications: Number(notifications[0]?.total || 0),
    },
    recent_users: recentUsers,
    revenue_trend: normalizeTrend(revenueTrend, 'revenue'),
    content_mix: contentMix.map((row) => ({
      name: row.content_type,
      value: Number(row.total || 0),
    })),
  };
};

const normalizeTrend = (rows, metric) =>
  rows.map((row) => ({
    date: dateOnly(row.date),
    [metric]: Number(row[metric] || 0),
  }));

const listUsers = async ({ page = 1, limit = 10, search = '', status = '', account = '' }) => {
  const safeLimit = clampLimit(limit);
  const offset = offsetFor(page, safeLimit);
  const where = [];
  const params = [];

  if (search) {
    where.push(
      `(u.full_name LIKE ? OR u.mobile_number LIKE ? OR u.email LIKE ? OR u.school LIKE ? OR u.city LIKE ?)`,
    );
    params.push(like(search), like(search), like(search), like(search), like(search));
  }

  if (account) {where.push('u.is_blocked = ?');params.push(account === 'blocked' ? 1 : 0);}
  if (status === 'active') {
    where.push('us.id IS NOT NULL');
  } else if (status === 'inactive') {
    where.push('us.id IS NULL');
  }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const activeSubscriptionJoin = `LEFT JOIN user_subscriptions us
       ON us.user_id = u.id
      AND us.status = 'active'
      AND us.started_at <= NOW()
      AND (us.expires_at IS NULL OR us.expires_at > NOW())
      AND us.id = (SELECT MAX(current_sub.id) FROM user_subscriptions current_sub
        WHERE current_sub.user_id = u.id AND current_sub.status = 'active' AND current_sub.started_at <= NOW()
        AND (current_sub.expires_at IS NULL OR current_sub.expires_at > NOW()))`;
  const [[countRow]] = await pool.execute(
    `SELECT COUNT(*) AS total
     FROM users u
     ${activeSubscriptionJoin}
     ${whereSql}`,
    params,
  );
  const [items] = await pool.execute(
    `SELECT u.id, u.mobile_number, u.full_name, u.email, u.school, u.city, u.state,
            u.is_blocked, u.block_reason, u.blocked_at, u.created_at, u.updated_at,
            uls.child_name, uls.learning_language, uls.level,
            sp.name AS plan_name,
            us.status AS subscription_status,
            us.expires_at AS subscription_expires_at,
            COALESCE(progress.completed_count, 0) AS completed_count,
            COALESCE(payments.total_spent, 0) AS total_spent
     FROM users u
     LEFT JOIN user_learning_setups uls ON uls.user_id = u.id
     ${activeSubscriptionJoin}
     LEFT JOIN subsc_plans sp ON sp.id = us.plan_id
     LEFT JOIN (
       SELECT user_id, COUNT(*) AS completed_count
       FROM user_content_progress
       WHERE status = 'completed'
       GROUP BY user_id
     ) progress ON progress.user_id = u.id
     LEFT JOIN (
       SELECT user_id, COALESCE(SUM(CAST(amount AS DECIMAL(12,2))), 0) AS total_spent
       FROM payment_orders
       WHERE status = 'paid'
       GROUP BY user_id
     ) payments ON payments.user_id = u.id
     ${whereSql}
     ORDER BY u.created_at DESC, u.id DESC
     LIMIT ${safeLimit} OFFSET ${offset}`,
    params,
  );

  return paged(items, countRow, page, safeLimit);
};

const getUserDetail = async (userId) => {
  const [[user]] = await pool.execute(
    `SELECT id, mobile_number, full_name, email, school, city, state,
            is_blocked, block_reason, blocked_at, created_at, updated_at
     FROM users
     WHERE id = ?
     LIMIT 1`,
    [userId],
  );

  if (!user) return null;

  const [[learningSetup]] = await pool.execute(
    `SELECT user_id, child_name, primary_language, learning_language,
            level, interests, selected_languages, plan_id, created_at, updated_at
     FROM user_learning_setups
     WHERE user_id = ?
     LIMIT 1`,
    [userId],
  );
  const [progress] = await pool.execute(
    `SELECT *
     FROM user_content_progress
     WHERE user_id = ?
     ORDER BY updated_at DESC
     LIMIT 50`,
    [userId],
  );
  const [subscriptions] = await pool.execute(
    `SELECT us.*, ${subscriptionStatusSql} AS status, sp.name AS plan_name, sp.type, sp.amount, sp.plan_timeperiod
     FROM user_subscriptions us
     JOIN subsc_plans sp ON sp.id = us.plan_id
     WHERE us.user_id = ?
     ORDER BY us.created_at DESC`,
    [userId],
  );
  const [payments] = await pool.execute(
    `SELECT po.*, sp.name AS plan_name
     FROM payment_orders po
     LEFT JOIN subsc_plans sp ON sp.id = po.plan_id
     WHERE po.user_id = ?
     ORDER BY po.created_at DESC`,
    [userId],
  );
  const [notifications] = await pool.execute(
    `SELECT id, title, body, type, is_read, created_at, read_at
     FROM notifications
     WHERE user_id = ?
     ORDER BY created_at DESC
     LIMIT 30`,
    [userId],
  );

  return {
    user,
    learning_setup: normalizeJsonRow(learningSetup, ['interests','selected_languages']),
    progress: progress.map((row) => normalizeJsonRow(row, ['metadata'])),
    subscriptions,
    payments: payments.map((row) => normalizeJsonRow(row, ['metadata'])),
    notifications,
  };
};

const updateUser = async (userId, payload) => {
  await pool.execute(
    `UPDATE users
     SET full_name = ?, email = ?, school = ?, city = ?, state = ?,
         updated_at = CURRENT_TIMESTAMP
     WHERE id = ?`,
    [
      payload.full_name,
      nullable(payload.email),
      nullable(payload.school),
      nullable(payload.city),
      nullable(payload.state),
      userId,
    ],
  );
  return getUserDetail(userId);
};

const deleteUser = async (userId) => {
  const [result] = await pool.execute('DELETE FROM users WHERE id = ?', [userId]);
  return result.affectedRows > 0;
};

const listPaymentOrders = async ({ page = 1, limit = 10, search = '', status }) => {
  const safeLimit = clampLimit(limit);
  const offset = offsetFor(page, safeLimit);
  const params = [];
  const where = [];

  if (search) {
    where.push(
      `(u.full_name LIKE ? OR u.mobile_number LIKE ? OR po.provider_order_id LIKE ? OR sp.name LIKE ?)`,
    );
    params.push(like(search), like(search), like(search), like(search));
  }
  if (status) {
    where.push('po.status = ?');
    params.push(status);
  }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const [[countRow]] = await pool.execute(
    `SELECT COUNT(*) AS total
     FROM payment_orders po
     JOIN users u ON u.id = po.user_id
     LEFT JOIN subsc_plans sp ON sp.id = po.plan_id
     ${whereSql}`,
    params,
  );
  const [items] = await pool.execute(
    `SELECT po.*, u.full_name, u.mobile_number, sp.name AS plan_name
     FROM payment_orders po
     JOIN users u ON u.id = po.user_id
     LEFT JOIN subsc_plans sp ON sp.id = po.plan_id
     ${whereSql}
     ORDER BY po.created_at DESC, po.id DESC
     LIMIT ${safeLimit} OFFSET ${offset}`,
    params,
  );
  return paged(items.map((row) => normalizeJsonRow(row, ['metadata'])), countRow, page, safeLimit);
};

const listSubscriptions = async ({ page = 1, limit = 10, search = '', status }) => {
  const safeLimit = clampLimit(limit);
  const offset = offsetFor(page, safeLimit);
  const params = [];
  const where = [];

  if (search) {
    where.push('(u.full_name LIKE ? OR u.mobile_number LIKE ? OR sp.name LIKE ?)');
    params.push(like(search), like(search), like(search));
  }
  if (status) {
    where.push(`${subscriptionStatusSql} = ?`);
    params.push(status);
  }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const [[countRow]] = await pool.execute(
    `SELECT COUNT(*) AS total
     FROM user_subscriptions us
     JOIN users u ON u.id = us.user_id
     JOIN subsc_plans sp ON sp.id = us.plan_id
     ${whereSql}`,
    params,
  );
  const [items] = await pool.execute(
    `SELECT us.*, ${subscriptionStatusSql} AS status, u.full_name, u.mobile_number, sp.name AS plan_name,
            sp.type, sp.amount, sp.plan_timeperiod
     FROM user_subscriptions us
     JOIN users u ON u.id = us.user_id
     JOIN subsc_plans sp ON sp.id = us.plan_id
     ${whereSql}
     ORDER BY us.created_at DESC, us.id DESC
     LIMIT ${safeLimit} OFFSET ${offset}`,
    params,
  );
  return paged(items, countRow, page, safeLimit);
};

const listNotifications = async ({ page = 1, limit = 10, search = '' }) => {
  const safeLimit = clampLimit(limit);
  const offset = offsetFor(page, safeLimit);
  const params = [];
  const where = [];

  if (search) {
    where.push('(n.title LIKE ? OR n.body LIKE ? OR u.full_name LIKE ?)');
    params.push(like(search), like(search), like(search));
  }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const [[countRow]] = await pool.execute(
    `SELECT COUNT(*) AS total
     FROM notifications n
     LEFT JOIN users u ON u.id = n.user_id
     ${whereSql}`,
    params,
  );
  const [items] = await pool.execute(
    `SELECT n.*, u.full_name, u.mobile_number
     FROM notifications n
     LEFT JOIN users u ON u.id = n.user_id
     ${whereSql}
     ORDER BY n.created_at DESC, n.id DESC
     LIMIT ${safeLimit} OFFSET ${offset}`,
    params,
  );
  return paged(items.map((row) => normalizeJsonRow(row, ['data'])), countRow, page, safeLimit);
};

const createNotification = async ({ userId, title, body, type = 'info', data = {} }) => {
  const [result] = await pool.execute(
    `INSERT INTO notifications (user_id, title, body, type, data)
     VALUES (?, ?, ?, ?, ?)`,
    [userId || null, title, body, type, JSON.stringify(data || {})],
  );
  const [[notification]] = await pool.execute(
    'SELECT * FROM notifications WHERE id = ? LIMIT 1',
    [result.insertId],
  );
  return normalizeJsonRow(notification, ['data']);
};

const broadcastNotification = async ({ title, body, type = 'info', data = {} }) => {
  const [users] = await pool.execute('SELECT id FROM users ORDER BY id');
  for (const user of users) {
    await createNotification({ userId: user.id, title, body, type, data });
  }
  return { sent: users.length };
};

const listResource = async (resource, { page = 1, limit = 10, search = '', language = '' }) => {
  const definition = getResourceDefinition(resource);
  const safeLimit = clampLimit(limit);
  const offset = offsetFor(page, safeLimit);
  const params = [];
  const where = [];

  if (search) {
    where.push(`(${definition.search.map((column) => `\`${column}\` LIKE ?`).join(' OR ')})`);
    params.push(...definition.search.map(() => like(search)));
  }

  const languageColumn = definition.columns.includes('language')
    ? 'language'
    : definition.columns.includes('Language')
      ? 'Language'
      : null;
  if (language && languageColumn) {
    where.push(`\`${languageColumn}\` = ?`);
    params.push(language);
  }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const [[countRow]] = await pool.execute(
    `SELECT COUNT(*) AS total FROM \`${definition.table}\` ${whereSql}`,
    params,
  );
  const [items] = await pool.execute(
    `SELECT id, ${definition.columns.map((column) => `\`${column}\``).join(', ')}
     FROM \`${definition.table}\`
     ${whereSql}
     ORDER BY id DESC
     LIMIT ${safeLimit} OFFSET ${offset}`,
    params,
  );

  return paged(normalizeResourceRows(definition, items), countRow, page, safeLimit);
};

const getResource = async (resource, id) => {
  const definition = getResourceDefinition(resource);
  const [rows] = await pool.execute(
    `SELECT id, ${definition.columns.map((column) => `\`${column}\``).join(', ')}
     FROM \`${definition.table}\`
     WHERE id = ?
     LIMIT 1`,
    [id],
  );
  return normalizeResourceRows(definition, rows)[0] || null;
};

const createResource = async (resource, payload) => {
  const definition = getResourceDefinition(resource);
  await validateResourcePayload(resource, definition, payload, true);
  const columns = definition.columns;
  const values = columns.map((column) => valueForColumn(definition, column, payload[column]));
  const [result] = await pool.execute(
    `INSERT INTO \`${definition.table}\`
      (${columns.map((column) => `\`${column}\``).join(', ')})
     VALUES (${columns.map(() => '?').join(', ')})`,
    values,
  );
  return getResource(resource, result.insertId);
};

const updateResource = async (resource, id, payload) => {
  const definition = getResourceDefinition(resource);
  const existing = await getResource(resource,id);
  if (!existing) return null;
  await validateResourcePayload(resource, definition, payload, false, existing);
  await require('./adminContentRelations').update(definition,resource,id,payload,valueForColumn);
  return getResource(resource,id);
};

const deleteResource = async (resource,id) => require('./adminContentRelations').remove(getResourceDefinition(resource),resource,id);

const getResourceSchema = () =>
  Object.entries(learningResources).map(([key, definition]) => ({
    key,
    columns: definition.columns,
    json_columns: definition.jsonColumns || [],
  }));

const getResourceDefinition = (resource) => {
  const definition = Object.hasOwn(learningResources, resource) ? learningResources[resource] : null;
  if (!definition) {
    const error = new Error('Unknown learning resource');
    error.statusCode = 404;
    throw error;
  }
  return definition;
};

const validateResourcePayload = async (resource, definition, payload, creating, existing = {}) => {
  if (resource === 'quizzes' && Object.hasOwn(payload,'show_plan')) throw new ApiError('Access is managed for the whole quiz topic. Use Edit topic.',422);
  const parentField = ({quizzes:'topic',phonics:'coursename',alphabets:'coursename',content:'course'})[resource];
  if (parentField && (creating || Object.hasOwn(payload,parentField)) && !String(payload[parentField] || '').trim()) throw new ApiError('Choose or enter a topic before saving this item.',422);
  const primary = ({ content: 'content', alphabets: 'letter', quizzes: 'Question', phonics: 'word', plans: 'name' })[resource] || 'title';
  if ((creating || Object.hasOwn(payload, primary)) && (typeof payload[primary] !== 'string' || !payload[primary].trim())) {
    throw new ApiError(`${primary} is required`, 422);
  }
  for (const column of definition.columns) {
    if (!Object.hasOwn(payload, column)) continue;
    const value = payload[column];
    if ((definition.jsonColumns || []).includes(column)) {
      try {
        const parsed = typeof value === 'string' ? JSON.parse(value) : value;
        if (!parsed || typeof parsed !== 'object') throw new Error();
      } catch { throw new ApiError(`${column} must be a JSON object or array`, 422); }
    } else if (value != null && typeof value !== 'string' && typeof value !== 'number') {
      throw new ApiError(`${column} must be text or a number`, 422);
    }
  }
  const combined = { ...existing, ...payload };
  const languageField = definition.columns.includes('language') ? 'language' : definition.columns.includes('Language') ? 'Language' : null;
  if (languageField && Object.hasOwn(payload,languageField) && payload[languageField] !== existing[languageField] && !String(payload[languageField] || '').trim()) throw new ApiError('Language is required',422);
  if (Object.hasOwn(payload,'show_plan') && payload.show_plan !== existing.show_plan && !String(payload.show_plan || '').trim()) throw new ApiError('Choose an access value',422);
  const { options } = await require('./adminCatalogRepository').formOptions(resource,combined[languageField] || '');
  for (const [field, values] of Object.entries(options)) {
    if (!Object.hasOwn(payload,field) || payload[field] === existing[field] || payload[field] == null || payload[field] === '') continue;
    if (!values.some(value => String(value).toLowerCase() === String(payload[field]).toLowerCase())) throw new ApiError(`Choose an existing ${field} value from the catalog`,422);
  }
  if (creating && languageField && !String(combined[languageField] || '').trim()) throw new ApiError('Language is required',422);
  if (resource === 'quizzes' && (creating || ['ca','o1','o2','o3'].some(field => Object.hasOwn(payload,field)))) {
    const answers = [combined.ca,combined.o1,combined.o2,combined.o3].map(value => String(value || '').trim()).filter(Boolean);
    if (!String(combined.ca || '').trim() || new Set(answers).size < 2) throw new ApiError('A quiz needs a correct answer and at least one different alternative',422);
  }
  if (resource === 'plans') {
    if (Object.hasOwn(payload,'permission') && JSON.stringify(payload.permission) !== JSON.stringify(existing.permission)) {
      const permission = typeof payload.permission === 'string' ? JSON.parse(payload.permission) : payload.permission;
      if (Object.keys(permission || {}).length) throw new ApiError('Per-content permissions are not supported. Plan access is determined by Free or Premium type.',422);
    }
    if ((creating || Object.hasOwn(payload,'type')) && !['free','premium'].includes(combined.type)) throw new ApiError('Choose a Free or Premium plan',422);
    if (combined.type === 'free' && Number(combined.amount || 0) !== 0) throw new ApiError('Free plans must have a zero price',422);
    if (combined.type === 'premium' && (!String(combined.plan_timeperiod || '').trim() || !require('../../shared/utils/subscriptionExpiry').buildExpiry(new Date(),combined.plan_timeperiod))) throw new ApiError('Choose a valid subscription period',422);
  }
  if (resource === 'plans' && Object.hasOwn(payload, 'amount') && (!Number.isFinite(Number(payload.amount)) || Number(payload.amount) < 0)) {
    throw new ApiError('Amount must be zero or more', 422);
  }
};

const valueForColumn = (definition, column, value) => {
  if ((definition.jsonColumns || []).includes(column) && typeof value !== 'string') {
    return JSON.stringify(value || []);
  }
  if (value == null) return '';
  return value;
};

const normalizeResourceRows = (definition, rows) =>
  rows.map((row) => normalizeJsonRow(row, definition.jsonColumns || []));

const normalizeJsonRow = (row, columns) => {
  if (!row) return null;
  const next = { ...row };
  for (const column of columns) {
    try {
      next[column] = typeof next[column] === 'string' ? JSON.parse(next[column]) : next[column];
    } catch (_) {
      next[column] = {};
    }
  }
  return next;
};

const paged = (items, countRow, page, limit) => ({
  items,
  total: Number(countRow?.total || 0),
  page: Math.max(Number(page) || 1, 1),
  limit,
});

const nullable = (value) => {
  const text = value?.toString().trim() ?? '';
  return text || null;
};

module.exports = {
  findAdminByEmail,
  findAdminById,
  updateAdminLogin,
  getOverview,
  listUsers,
  getUserDetail,
  updateUser,
  deleteUser,
  listPaymentOrders,
  listSubscriptions,
  listNotifications,
  createNotification,
  broadcastNotification,
  listResource,
  getResource,
  createResource,
  updateResource,
  deleteResource,
  getResourceSchema,
  validateResource: (resource,payload,existing) => validateResourcePayload(resource,getResourceDefinition(resource),payload,!existing,existing),
};
