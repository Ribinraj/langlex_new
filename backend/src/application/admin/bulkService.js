const { isDeepStrictEqual } = require('node:util');
const { randomUUID, createHash } = require('node:crypto');
const { pool, withTransaction } = require('../../infrastructure/database/db');
const repo = require('../../infrastructure/repositories/adminRepository');
const catalog = require('../../infrastructure/repositories/adminCatalogRepository');
const audit = require('./auditService');
const ApiError = require('../../shared/errors/apiError');
const shared = {
  courses: ['title', 'language', 'image', 'show_plan'],
  alphabets: ['letter', 'coursename', 'language'],
  quizzes: ['topic', 'Language', 'show_plan'],
  phonics: ['coursename', 'language', 'title_image'],
  stories: [
    'title',
    'language',
    'grade',
    'show_plan',
    'title_image',
    'title_audio',
  ],
};
const json = (value) => (typeof value === 'string' ? JSON.parse(value) : value);
const snapshot = async (resource, id, operation) => {
  if (operation === 'topics') {
    // Include member identities and values so concurrent content edits invalidate a preview.
    const scope = await catalog.groupScope(resource, id, pool, true);
    let members = [];
    if (scope.where && scope.table)
      [members] = await pool.query(
        `SELECT * FROM \`${scope.table}\` WHERE ${scope.where} ORDER BY id FOR UPDATE`,
        scope.values,
      );
    const data = await catalog.groupItems(resource, id, { page: 1, limit: 1 });
    return {
      group: data.group,
      total: data.total,
      members_hash: createHash('sha256')
        .update(JSON.stringify(members))
        .digest('hex'),
    };
  }
  const table = catalog.definition(resource).table;
  await pool.query(`SELECT id FROM \`${table}\` WHERE id=? FOR UPDATE`, [id]);
  const item = await repo.getResource(resource, id);
  if (!item) throw new ApiError(`Record ${id} not found`, 404);
  return item;
};
const validateRows = (resource, operation, rows) => {
  const schema = repo.getResourceSchema().find((item) => item.key === resource);
  if (!schema) throw new ApiError('Unknown resource', 404);
  if (operation === 'topics' && !shared[resource])
    throw new ApiError('This resource has no topics', 422);
  const allowed = operation === 'topics' ? shared[resource] : schema.columns;
  const ids = new Set();
  rows.forEach((row, index) => {
    if (!row || typeof row !== 'object' || Array.isArray(row))
      throw new ApiError(`Row ${index + 1}: expected an object`, 422);
    for (const field of Object.keys(row)) {
      if (field === 'id' && operation !== 'import') continue;
      if (!allowed.includes(field))
        throw new ApiError(`Row ${index + 1}: unsupported field ${field}`, 422);
      if (operation === 'edit' && shared[resource]?.includes(field))
        throw new ApiError(
          `Row ${index + 1}: edit ${field} in Topics mode to update the whole topic`,
          422,
        );
    }
    if (operation !== 'import') {
      if (!Number.isSafeInteger(Number(row.id)) || Number(row.id) <= 0)
        throw new ApiError(`Row ${index + 1}: valid ID required`, 422);
      if (ids.has(String(row.id)))
        throw new ApiError(`Row ${index + 1}: duplicate ID`, 422);
      ids.add(String(row.id));
      if (Object.keys(row).length < 2)
        throw new ApiError(
          `Row ${index + 1}: provide at least one change`,
          422,
        );
    }
  });
};
const runRows = async (resource, operation, rows, expected) => {
  const changes = [];
  for (let index = 0; index < rows.length; index++) {
    const { id, ...payload } = rows[index];
    try {
      const before =
        operation === 'import' ? null : await snapshot(resource, id, operation);
      if (
        expected &&
        !isDeepStrictEqual(JSON.parse(JSON.stringify(before)), expected[index])
      )
        throw new ApiError(
          'Data changed since preview. Create a new preview.',
          409,
        );
      let result;
      if (operation === 'topics')
        result = await catalog.updateGroup(resource, id, payload);
      else if (operation === 'edit')
        result = await repo.updateResource(resource, id, payload);
      else result = await repo.createResource(resource, payload);
      const after =
        operation === 'topics'
          ? await snapshot(resource, result.id || id, operation)
          : result;
      changes.push({
        row: index + 1,
        id: result?.id || id || null,
        before,
        after,
      });
    } catch (error) {
      throw new ApiError(
        `Row ${index + 1}: ${error.message}`,
        error.statusCode || 422,
      );
    }
  }
  return changes;
};
const curriculum = require('../../infrastructure/repositories/curriculumRepository');
const topicId = (resource) =>
  /^topic:[1-9][0-9]*$/.test(resource) ? resource.slice(6) : null;
const runTopicRows = async (resource, operation, rows, expected) => {
  if (!['import', 'edit'].includes(operation))
    throw new ApiError('Choose import or edit inside a topic.', 422);
  if (!Array.isArray(rows) || !rows.length || rows.length > 100)
    throw new ApiError('Include between 1 and 100 rows.', 422);
  const id = topicId(resource),
    topic = await curriculum.get(id, true),
    def = curriculum.definition(topic.resource);
  const locked = new Set([
    def.title,
    def.language,
    def.level,
    'category',
    'subcategory',
    'course',
    'coursename',
    'show_plan',
    'title_image',
    'title_audio',
    'created',
  ]);
  const allowed = repo
    .getResourceSchema()
    .find((s) => s.key === def.item)
    .columns.filter((k) => !locked.has(k));
  const changes = [],
    seen = new Set();
  for (let index = 0; index < rows.length; index++) {
    const row = rows[index];
    if (!row || typeof row !== 'object' || Array.isArray(row))
      throw new ApiError(`Row ${index + 1}: expected an object`, 422);
    const { id: itemId, ...payload } = row;
    if (
      operation === 'edit' &&
      (!/^[1-9][0-9]*$/.test(String(itemId)) || seen.has(String(itemId)))
    )
      throw new ApiError(`Row ${index + 1}: use a unique item ID`, 422);
    if (operation === 'import' && itemId !== undefined)
      throw new ApiError(`Row ${index + 1}: imports cannot include IDs`, 422);
    seen.add(String(itemId));
    if (
      !Object.keys(payload).length ||
      Object.keys(payload).some((k) => !allowed.includes(k))
    )
      throw new ApiError(
        `Row ${index + 1}: use the topic template; language, standards and parent fields are inherited`,
        422,
      );

    let item = null,
      override = null;
    if (operation === 'edit') {
      const [[link]] = await pool.query(
        'SELECT standards FROM learning_topic_items WHERE topic_id=? AND item_id=?',
        [id, itemId],
      );
      if (!link)
        throw new ApiError(`Row ${index + 1}: item is outside this topic`, 422);
      item = await repo.getResource(def.item, itemId);
      override = json(link.standards);
    }
    const before = { topic, item, standard_override: override };
    if (
      expected &&
      !isDeepStrictEqual(JSON.parse(JSON.stringify(before)), expected[index])
    )
      throw new ApiError(
        'Topic or content changed since preview. Create a new preview.',
        409,
      );
    try {
      const after = await curriculum.saveItem(
        id,
        operation === 'edit' ? itemId : null,
        payload,
      );
      changes.push({ row: index + 1, id: after.id, before, after });
    } catch (error) {
      throw new ApiError(
        `Row ${index + 1}: ${error.message}`,
        error.statusCode || 422,
      );
    }
  }
  return changes;
};
const preview = async (admin, resource, { operation, rows }) => {
  if (!topicId(resource)) validateRows(resource, operation, rows);
  const changes = await withTransaction(
    () =>
      (topicId(resource) ? runTopicRows : runRows)(resource, operation, rows),
    { rollback: true },
  );
  const id = randomUUID();
  await pool.execute(
    'DELETE FROM admin_bulk_previews WHERE expires_at<NOW() AND applied_at IS NULL',
  );
  await pool.execute(
    `INSERT INTO admin_bulk_previews(id,admin_id,resource,operation,payload,snapshots,expires_at)
    VALUES(?,?,?,?,?,?,DATE_ADD(NOW(),INTERVAL 15 MINUTE))`,
    [
      id,
      admin.id,
      resource,
      operation,
      JSON.stringify(rows),
      JSON.stringify(changes.map((c) => c.before)),
    ],
  );
  return { id, operation, count: rows.length, changes, expires_in_minutes: 15 };
};
const apply = (admin, id) =>
  withTransaction(async () => {
    const [[preview]] = await pool.execute(
      'SELECT * FROM admin_bulk_previews WHERE id=? AND admin_id=? FOR UPDATE',
      [id, admin.id],
    );
    if (!preview) throw new ApiError('Preview not found', 404);
    if (preview.applied_at)
      return { ...json(preview.result), already_applied: true };
    if (new Date(preview.expires_at) <= new Date())
      throw new ApiError('Preview expired. Create a new preview.', 409);
    const changes = await (topicId(preview.resource) ? runTopicRows : runRows)(
      preview.resource,
      preview.operation,
      json(preview.payload),
      json(preview.snapshots),
    );
    for (const change of changes)
      await audit.record(admin, {
        action: `bulk_${preview.operation}`,
        entity: preview.resource,
        id: change.id,
        before: change.before,
        after: change.after,
        reason: `Batch ${id}`,
      });
    const result = {
      applied: true,
      count: changes.length,
      ids: changes.map((c) => c.id),
    };
    await pool.execute(
      'UPDATE admin_bulk_previews SET applied_at=NOW(),result=? WHERE id=?',
      [JSON.stringify(result), id],
    );
    return result;
  });
module.exports = { preview, apply, shared };
