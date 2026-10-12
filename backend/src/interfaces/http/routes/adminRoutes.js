const express = require('express');
const Joi = require('joi');

const adminController = require('../controllers/adminController');
const authenticateAdmin = require('../middleware/adminAuthMiddleware');
const validate = require('../middleware/validate');
const asyncHandler = require('../../../shared/utils/asyncHandler');

const router = express.Router();
const audit = require('../../../application/admin/auditService');
const operations = require('../../../application/admin/operationsService');
const bulk = require('../../../application/admin/bulkService');
const media = require('../../../application/admin/mediaService');
const catalogAdmin = require('../../../infrastructure/repositories/adminCatalogRepository');

const loginSchema = Joi.object({
  email: Joi.string()
    .trim()
    .email({ tlds: { allow: false } })
    .required(),
  password: Joi.string().min(8).max(160).required(),
});

const pagingSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(10),
  search: Joi.string().trim().allow('', null).default(''),
  language: Joi.string().trim().allow('', null).optional(),
  status: Joi.string().trim().allow('', null).optional(),
  account: Joi.string().valid('active', 'blocked', '').optional(),
});

const userUpdateSchema = Joi.object({
  full_name: Joi.string().trim().min(2).max(120).required(),
  email: Joi.string().trim().email().allow('', null).optional(),
  school: Joi.string().trim().max(160).allow('', null).optional(),
  city: Joi.string().trim().max(120).allow('', null).optional(),
  state: Joi.string().trim().max(120).allow('', null).optional(),
});

const notificationSchema = Joi.object({
  userId: Joi.number().integer().positive().allow(null).optional(),
  broadcast: Joi.boolean().default(false),
  title: Joi.string().trim().min(2).max(160).required(),
  body: Joi.string().trim().min(2).max(500).required(),
  type: Joi.string().trim().min(2).max(60).default('info'),
  data: Joi.object().unknown(true).default({}),
});

const resourceSchema = Joi.object().unknown(true);

router.post(
  '/auth/login',
  validate(loginSchema),
  asyncHandler(adminController.login),
);

router.use(authenticateAdmin);
router.use('/curriculum', require('./curriculumRoutes'));

const reason = Joi.string().trim().min(3).max(500).required();
router.get(
  '/audit',
  validate(pagingSchema, 'query'),
  asyncHandler(async (req, res) => res.json(await audit.list(req.query))),
);
router.put(
  '/users/:id/access',
  validate(Joi.object({ blocked: Joi.boolean().required(), reason })),
  asyncHandler(async (req, res) =>
    res.json(await operations.setBlocked(req.admin, req.params.id, req.body)),
  ),
);
router.post(
  '/users/:id/subscriptions',
  validate(
    Joi.object({
      plan_id: Joi.number().integer().positive().required(),
      expires_at: Joi.date().iso().required(),
      reason,
    }),
  ),
  asyncHandler(async (req, res) =>
    res
      .status(201)
      .json(await operations.grant(req.admin, req.params.id, req.body)),
  ),
);
router.put(
  '/subscriptions/:id',
  validate(
    Joi.object({
      action: Joi.string().valid('cancel', 'change_expiry').required(),
      expires_at: Joi.when('action', {
        is: 'change_expiry',
        then: Joi.date().iso().required(),
        otherwise: Joi.forbidden(),
      }),
      reason,
    }),
  ),
  asyncHandler(async (req, res) =>
    res.json(await operations.manage(req.admin, req.params.id, req.body)),
  ),
);
router.get(
  '/media',
  validate(pagingSchema, 'query'),
  asyncHandler(async (req, res) => res.json(await media.list(req.query))),
);
router.post(
  '/media',
  express.raw({ type: 'application/octet-stream', limit: '20mb' }),
  asyncHandler(async (req, res) =>
    res
      .status(201)
      .json({
        item: await media.upload(
          req.admin,
          req.body,
          req.headers['x-file-name'],
        ),
      }),
  ),
);
router.post(
  '/bulk/:resource/preview',
  validate(
    Joi.object({
      operation: Joi.string().valid('import', 'edit', 'topics').required(),
      rows: Joi.array()
        .items(Joi.object().unknown(true))
        .min(1)
        .max(100)
        .required(),
    }),
  ),
  asyncHandler(async (req, res) =>
    res.json(await bulk.preview(req.admin, req.params.resource, req.body)),
  ),
);
router.post(
  '/bulk/:id/apply',
  asyncHandler(async (req, res) =>
    res.json(await bulk.apply(req.admin, req.params.id)),
  ),
);

router.get('/auth/me', asyncHandler(adminController.me));
router.get('/overview', asyncHandler(adminController.overview));
router.get(
  '/users',
  validate(pagingSchema, 'query'),
  asyncHandler(adminController.listUsers),
);
router.get('/users/:id', asyncHandler(adminController.getUser));
router.put(
  '/users/:id',
  validate(userUpdateSchema),
  asyncHandler(adminController.updateUser),
);
router.delete('/users/:id', asyncHandler(adminController.deleteUser));
router.get(
  '/payments',
  validate(pagingSchema, 'query'),
  asyncHandler(adminController.listPayments),
);
router.get(
  '/subscriptions',
  validate(pagingSchema, 'query'),
  asyncHandler(adminController.listSubscriptions),
);
router.get(
  '/notifications',
  validate(pagingSchema, 'query'),
  asyncHandler(adminController.listNotifications),
);
router.post(
  '/notifications',
  validate(notificationSchema),
  asyncHandler(adminController.createNotification),
);
router.get(
  '/resource-options/:resource',
  validate(pagingSchema, 'query'),
  asyncHandler(async (req, res) => {
    const result =
      await require('../../../infrastructure/repositories/catalogRepository').options(
        req.params.resource,
        req.query,
      );
    res.json(result);
  }),
);
router.get(
  '/reference-options/:resource/:field',
  validate(pagingSchema, 'query'),
  asyncHandler(async (req, res) => {
    res.json(
      await catalogAdmin.references(
        req.params.resource,
        req.params.field,
        req.query,
      ),
    );
  }),
);
router.get(
  '/resource-form-options/:resource',
  validate(pagingSchema, 'query'),
  asyncHandler(async (req, res) => {
    res.json(
      await catalogAdmin.formOptions(req.params.resource, req.query.language),
    );
  }),
);
router.get(
  '/catalog/:resource',
  validate(pagingSchema, 'query'),
  asyncHandler(async (req, res) => {
    res.json(await catalogAdmin.groups(req.params.resource, req.query));
  }),
);
router.get(
  '/catalog/:resource/:id/items',
  validate(pagingSchema, 'query'),
  asyncHandler(async (req, res) => {
    res.json(
      await catalogAdmin.groupItems(
        req.params.resource,
        req.params.id,
        req.query,
      ),
    );
  }),
);
router.put(
  '/catalog/:resource/:id',
  validate(resourceSchema),
  asyncHandler(async (req, res) => {
    res.json(
      await audit.mutate(
        req.admin,
        {
          action: 'update_topic',
          entity: req.params.resource,
          id: req.params.id,
        },
        async () => {
          const data = await catalogAdmin.groupItems(
            req.params.resource,
            req.params.id,
            { page: 1, limit: 1 },
          );
          return { group: data.group, total: data.total };
        },
        () =>
          catalogAdmin.updateGroup(
            req.params.resource,
            req.params.id,
            req.body,
          ),
      ),
    );
  }),
);
router.get(
  '/users/:id/learning-progress',
  validate(pagingSchema, 'query'),
  asyncHandler(async (req, res) => {
    const detail =
      await require('../../../infrastructure/repositories/adminRepository').getUserDetail(
        req.params.id,
      );
    if (!detail)
      throw new (require('../../../shared/errors/apiError'))(
        'User not found',
        404,
      );
    if (detail.learning_setup?.selected_languages?.length !== 3)
      return res.json({ configured: false, progress: null });
    const progress =
      await require('../../../application/learning/contentProgressService').overview(
        detail.user,
        req.query,
      );
    res.json({ configured: true, progress });
  }),
);
router.get('/resources/schema', asyncHandler(adminController.resourceSchema));
router.get(
  '/resources/:resource',
  validate(pagingSchema, 'query'),
  asyncHandler(adminController.listResource),
);
router.get(
  '/resources/:resource/:id',
  asyncHandler(adminController.getResource),
);
router.post(
  '/resources/:resource',
  validate(resourceSchema),
  asyncHandler(adminController.createResource),
);
router.put(
  '/resources/:resource/:id',
  validate(resourceSchema),
  asyncHandler(adminController.updateResource),
);
router.delete(
  '/resources/:resource/:id',
  asyncHandler(adminController.deleteResource),
);

module.exports = router;
