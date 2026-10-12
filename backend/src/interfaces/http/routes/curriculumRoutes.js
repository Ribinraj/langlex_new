const router = require('express').Router();
const Joi = require('joi');
const validate = require('../middleware/validate');
const asyncHandler = require('../../../shared/utils/asyncHandler');
const repo = require('../../../infrastructure/repositories/curriculumRepository');
const audit = require('../../../application/admin/auditService');
const policy = require('../../../application/learning/standards');
const paging = Joi.object({
  resource: Joi.string().valid(...Object.keys(repo.defs)),
  language: Joi.string().max(255).allow(''),
  search: Joi.string().max(255).allow(''),
  standard: Joi.string().valid('', 'review', ...policy.standards),
  page: Joi.number().integer().min(1),
  limit: Joi.number().integer().min(1).max(100),
});
const topic = Joi.object({
  resource: Joi.string().valid(...Object.keys(repo.defs)),
  title: Joi.string().trim().max(255).required(),
  language: Joi.string().max(255),
  group_name: Joi.string().max(255).allow(''),
  standards: Joi.array()
    .items(Joi.string().valid('*', ...policy.standards))
    .min(1)
    .max(6)
    .unique()
    .required(),
  access: Joi.string().valid('Free', 'Login', 'Premium'),
  image: Joi.string().max(2048).allow(''),
  audio: Joi.string().max(2048).allow(''),
  revision: Joi.number().integer().positive(),
  apply_to_items: Joi.boolean(),
});
async function itemSnapshot(topicId, itemId) {
  const topic = await repo.get(topicId);
  const { pool } = require('../../../infrastructure/database/db');
  const [[mapping]] = await pool.query(
    'SELECT standards FROM learning_topic_items WHERE topic_id=? AND item_id=?',
    [topicId, itemId],
  );
  if (!mapping) return null;
  return {
    item: await require('../../../infrastructure/repositories/adminRepository').getResource(
      repo.definition(topic.resource).item,
      itemId,
    ),
    standard_override: policy.parse(mapping.standards),
  };
}
router.get(
  '/options',
  asyncHandler(async (_req, res) =>
    res.json({
      standards: policy.standards,
      languages:
        await require('../../../infrastructure/repositories/learningRepository').listLanguages(),
    }),
  ),
);
router.get(
  '/',
  validate(paging, 'query'),
  asyncHandler(async (req, res) => res.json(await repo.list(req.query))),
);
router.get(
  '/:id',
  validate(paging, 'query'),
  asyncHandler(async (req, res) =>
    res.json(await repo.detail(req.params.id, req.query)),
  ),
);
router.post(
  '/',
  validate(topic),
  asyncHandler(async (req, res) =>
    res
      .status(201)
      .json(
        await audit.mutate(
          req.admin,
          { action: 'create', entity: 'learning_topics' },
          null,
          () => repo.create(req.body),
        ),
      ),
  ),
);
router.put(
  '/:id',
  validate(topic),
  asyncHandler(async (req, res) =>
    res.json(
      await audit.mutate(
        req.admin,
        { action: 'update', entity: 'learning_topics', id: req.params.id },
        () => repo.detail(req.params.id, { limit: 1 }),
        () => repo.update(req.params.id, req.body),
      ),
    ),
  ),
);
router.post(
  '/:id/items',
  validate(Joi.object().unknown(true)),
  asyncHandler(async (req, res) =>
    res.status(201).json({
      item: await audit.mutate(
        req.admin,
        {
          action: 'create_item',
          entity: 'learning_topics',
          id: req.params.id,
        },
        null,
        () => repo.saveItem(req.params.id, null, req.body),
      ),
    }),
  ),
);
router.put(
  '/:id/items/:itemId',
  validate(Joi.object().unknown(true)),
  asyncHandler(async (req, res) =>
    res.json({
      item: await audit.mutate(
        req.admin,
        { action: 'update_item', entity: 'learning_topics', id: req.params.id },
        () => itemSnapshot(req.params.id, req.params.itemId),
        () => repo.saveItem(req.params.id, req.params.itemId, req.body),
      ),
    }),
  ),
);
router.delete(
  '/:id/items/:itemId',
  asyncHandler(async (req, res) =>
    res.json(
      await audit.mutate(
        req.admin,
        { action: 'delete_item', entity: 'learning_topics', id: req.params.id },
        () => itemSnapshot(req.params.id, req.params.itemId),
        () => repo.deleteItem(req.params.id, req.params.itemId),
      ),
    ),
  ),
);
router.delete(
  '/:id',
  asyncHandler(async (req, res) =>
    res.json(
      await audit.mutate(
        req.admin,
        { action: 'delete', entity: 'learning_topics', id: req.params.id },
        () => repo.get(req.params.id),
        () => repo.removeTopic(req.params.id),
      ),
    ),
  ),
);
module.exports = router;
