const crypto = require('node:crypto');
const { pool, withTransaction } = require('../database/db');
const policy = require('../../application/learning/standards');
const ApiError = require('../../shared/errors/apiError');
const { pagination, textFilter } = require('../../shared/utils/pagination');
const defs = {
  courses: {
    table: 'Content',
    item: 'content',
    title: 'course',
    language: 'language',
    level: 'category',
  },
  alphabets: {
    table: 'Alphabets',
    item: 'alphabets',
    title: 'letter',
    language: 'language',
    level: 'level',
  },
  quizzes: {
    table: 'quizz',
    item: 'quizzes',
    title: 'topic',
    language: 'Language',
    level: 'difflvl',
  },
  stories: {
    table: 'stories',
    item: 'stories',
    title: 'title',
    language: 'language',
    level: 'grade',
  },
  phonics: {
    table: 'Phonics',
    item: 'phonics',
    title: 'coursename',
    language: 'language',
    level: 'level',
  },
};
const definition = (resource) => {
  if (!Object.hasOwn(defs, resource))
    throw new ApiError('Unknown learning section', 404);
  return defs[resource];
};
const sourceKey = (resource, language, title, groupName = '', grade = '') =>
  crypto
    .createHash('sha256')
    .update(
      JSON.stringify([
        resource,
        language.toLowerCase(),
        title.trim(),
        groupName,
        grade,
      ]),
    )
    .digest('hex');
const decoded = (row) =>
  row && {
    ...row,
    standards: policy.parse(row.standards),
    item_count: Number(row.item_count || 0),
    override_count: Number(row.override_count || 0),
    review_count: Number(row.review_count || 0),
  };

// Idempotent import of previously unmapped records. Explicit admin assignments are never replaced.
async function backfill() {
  await withTransaction(async () => {
    for (const [resource, d] of Object.entries(defs)) {
      const [rows] = await pool.query(
        `SELECT r.* FROM \`${d.table}\` r LEFT JOIN learning_topic_items m ON m.resource=? AND m.item_id=r.id WHERE m.item_id IS NULL ORDER BY r.id`,
        [resource],
      );
      const groups = new Map();
      for (const row of rows) {
        const title = String(row[d.title] || '').trim();
        if (!title || title.toLowerCase() === 'skip') continue;
        const groupName = resource === 'alphabets' ? row.coursename : '';
        const grade = resource === 'stories' ? row.grade : '';
        const key = sourceKey(
          resource,
          row[d.language],
          title,
          groupName,
          grade,
        );
        if (!groups.has(key)) groups.set(key, []);
        groups.get(key).push(row);
      }
      for (const [key, items] of groups) {
        const first = items[0];
        const perItem = items.map((r) => {
          const s = policy.normalize(r[d.level]);
          return s ? [s] : [];
        });
        const distinct = [...new Set(perItem.map((s) => JSON.stringify(s)))];
        const standards = [...new Set(perItem.flat())];
        let legacyId = first.id,
          access = 'Free',
          image = first.title_image || '',
          audio = first.title_audio || '';
        if (resource === 'courses') {
          const [[course]] = await pool.query(
            'SELECT * FROM courses WHERE title=? AND language=? ORDER BY id LIMIT 1',
            [first.course, first.language],
          );
          legacyId = course?.id || 1000000 + Number(first.id);
          access = course?.show_plan || 'Free';
          image = course?.image || first.content_image || '';
        } else if (resource === 'stories')
          access = items.some(
            (r) =>
              require('../../application/learning/contentAccess').normalizeAccess(
                r.show_plan,
              ) === 'Premium',
          )
            ? 'Premium'
            : first.show_plan;
        else if (resource === 'quizzes') {
          const [[setting]] = await pool.query(
            'SELECT show_plan FROM quiz_topic_settings WHERE language=? AND topic=?',
            [first.Language, first.topic],
          );
          access = setting?.show_plan || 'Free';
        }
        await pool.query(
          `INSERT IGNORE INTO learning_topics(resource,source_key,legacy_id,title,language,group_name,legacy_grade,standards,image,audio,access) VALUES (?,?,?,?,?,?,?,?,?,?,?)`,
          [
            resource,
            key,
            legacyId,
            String(first[d.title]).trim(),
            first[d.language],
            resource === 'alphabets' ? first.coursename : '',
            resource === 'stories' ? first.grade : '',
            JSON.stringify(standards),
            image,
            audio,
            require('../../application/learning/contentAccess').normalizeAccess(
              access,
            ),
          ],
        );
        const [[topic]] = await pool.query(
          'SELECT id,standards,revision FROM learning_topics WHERE source_key=? FOR UPDATE',
          [key],
        );
        const inherited = policy.parse(topic.standards);
        const values = items.map((r, i) => [
          resource,
          r.id,
          topic.id,
          distinct.length === 1 &&
          JSON.stringify(perItem[i]) === JSON.stringify(inherited)
            ? null
            : JSON.stringify(perItem[i]),
        ]);
        await pool.query(
          'INSERT IGNORE INTO learning_topic_items(resource,item_id,topic_id,standards) VALUES ?',
          [values],
        );
      }
    }
    // Empty original courses are retained as editable topics too.
    const [courses] = await pool.query('SELECT * FROM courses');
    for (const c of courses)
      await pool.query(
        `INSERT IGNORE INTO learning_topics(resource,source_key,legacy_id,title,language,standards,image,audio,access) VALUES ('courses',?,?,?,?,?,?,?,?)`,
        [
          sourceKey('courses', c.language, c.title),
          c.id,
          c.title,
          c.language,
          '[]',
          c.image || '',
          '',
          require('../../application/learning/contentAccess').normalizeAccess(
            c.show_plan,
          ),
        ],
      );
  });
}
function effectiveSql(alias = 'm', topic = 't') {
  return `COALESCE(${alias}.standards,${topic}.standards)`;
}
// Bound values only; table/column identifiers always originate in the allowlist above.
function filter(resource, alias, level) {
  if (!level) return { sql: '1=1', params: [] };
  const d = definition(resource),
    normalized = policy.normalize(level) || level;
  const values = policy.aliases[normalized] || [normalized];
  return {
    sql: `(EXISTS (SELECT 1 FROM learning_topic_items cm JOIN learning_topics ct ON ct.id=cm.topic_id WHERE cm.resource=? AND cm.item_id=${alias}.id AND (JSON_CONTAINS(COALESCE(cm.standards,ct.standards),JSON_QUOTE(?)) OR JSON_CONTAINS(COALESCE(cm.standards,ct.standards),'"*"'))) OR (NOT EXISTS (SELECT 1 FROM learning_topic_items um WHERE um.resource=? AND um.item_id=${alias}.id) AND (${alias}.\`${d.level}\`='' OR ${alias}.\`${d.level}\` IN (${values.map(() => '?').join(',')}))))`,
    params: [resource, normalized, resource, ...values],
  };
}
async function get(id, lock = false) {
  const [[row]] = await pool.query(
    'SELECT * FROM learning_topics WHERE id=?' + (lock ? ' FOR UPDATE' : ''),
    [id],
  );
  if (!row) throw new ApiError('Topic not found', 404);
  return decoded(row);
}
const visibleWord = (alias) =>
  `EXISTS (SELECT 1 FROM Content vw WHERE vw.id=${alias}.item_id AND TRIM(vw.content)<>'' AND LOWER(TRIM(vw.content))<>'skip' AND LOWER(TRIM(vw.course))<>'skip')`;
const summary = `SELECT t.*, COUNT(m.item_id) AS item_count,
 SUM(m.standards IS NOT NULL) AS override_count,
 SUM(m.item_id IS NOT NULL AND JSON_LENGTH(COALESCE(m.standards,t.standards))=0) AS review_count
 FROM learning_topics t LEFT JOIN learning_topic_items m ON m.topic_id=t.id`;
async function list(query = {}) {
  const resource = textFilter(query.resource, 'resource');
  definition(resource);
  const paging = pagination(query),
    where = ['t.resource=?'],
    args = [resource];
  for (const key of ['language', 'search']) {
    const value = textFilter(query[key], key);
    if (!value) continue;
    where.push(
      key === 'language'
        ? 't.language=?'
        : 'LOCATE(?,CONCAT_WS(" ",t.title,t.group_name))>0',
    );
    args.push(value);
  }
  if (query.standard) {
    if (query.standard === 'review')
      where.push(
        `(JSON_LENGTH(t.standards)=0 OR EXISTS (SELECT 1 FROM learning_topic_items rm WHERE rm.topic_id=t.id AND JSON_LENGTH(rm.standards)=0))`,
      );
    else {
      policy.validate([query.standard]);
      where.push(
        `EXISTS (SELECT 1 FROM learning_topic_items sm WHERE sm.topic_id=t.id ${resource === 'courses' ? `AND ${visibleWord('sm')}` : ''} AND (JSON_CONTAINS(COALESCE(sm.standards,t.standards),JSON_QUOTE(?)) OR JSON_CONTAINS(COALESCE(sm.standards,t.standards),'"*"')))`,
      );
      args.push(query.standard);
    }
  }
  const [[count]] = await pool.query(
    `SELECT COUNT(*) AS total FROM learning_topics t WHERE ${where.join(' AND ')}`,
    args,
  );
  const [rows] = await pool.query(
    `${summary} WHERE ${where.join(' AND ')} GROUP BY t.id ORDER BY t.title,t.id LIMIT ? OFFSET ?`,
    [...args, paging.limit, paging.offset],
  );
  for (const row of rows) {
    row.eligible_count = Number(row.item_count);
    if (query.standard && query.standard !== 'review') {
      const [[count]] = await pool.query(
        `SELECT COUNT(*) AS total FROM learning_topic_items m JOIN learning_topics t ON t.id=m.topic_id WHERE m.topic_id=? ${resource === 'courses' ? `AND ${visibleWord('m')}` : ''} AND (JSON_CONTAINS(COALESCE(m.standards,t.standards),JSON_QUOTE(?)) OR JSON_CONTAINS(COALESCE(m.standards,t.standards),'"*"'))`,
        [row.id, query.standard],
      );
      row.eligible_count = Number(count.total);
    }
  }
  return {
    items: rows.map(decoded),
    total: Number(count.total),
    page: paging.page,
    limit: paging.limit,
  };
}
async function detail(id, query = {}) {
  const topic = await get(id),
    d = definition(topic.resource),
    paging = pagination(query);
  const where = ['m.topic_id=?'],
    args = [id];
  if (query.standard) {
    if (topic.resource === 'courses') where.push(visibleWord('m'));
    policy.validate([query.standard]);
    where.push(
      `(JSON_CONTAINS(${effectiveSql()},JSON_QUOTE(?)) OR JSON_CONTAINS(${effectiveSql()},'"*"'))`,
    );
    args.push(query.standard);
  }
  const [[count]] = await pool.query(
    `SELECT COUNT(*) AS total FROM learning_topic_items m JOIN learning_topics t ON t.id=m.topic_id JOIN \`${d.table}\` r ON r.id=m.item_id WHERE ${where.join(' AND ')}`,
    args,
  );
  const [items] = await pool.query(
    `SELECT r.*,m.standards AS standard_override,${effectiveSql()} AS effective_standards FROM learning_topic_items m JOIN learning_topics t ON t.id=m.topic_id JOIN \`${d.table}\` r ON r.id=m.item_id WHERE ${where.join(' AND ')} ORDER BY r.id LIMIT ? OFFSET ?`,
    [...args, paging.limit, paging.offset],
  );
  const [[stats]] = await pool.query(`${summary} WHERE t.id=? GROUP BY t.id`, [
    id,
  ]);
  return {
    topic: decoded(stats),
    items: items.map((r) => ({
      ...r,
      standard_override: policy.parse(r.standard_override),
      effective_standards: policy.parse(r.effective_standards),
    })),
    total: Number(count.total),
    page: paging.page,
    limit: paging.limit,
  };
}
async function validateTopic(payload, existing) {
  const resource = existing?.resource || payload.resource;
  definition(resource);
  if (
    typeof payload.title !== 'string' ||
    !payload.title.trim() ||
    payload.title.length > 255
  )
    throw new ApiError('Enter a topic title (up to 255 characters).', 422);
  const language = existing?.language || payload.language;
  if (
    !(await require('./learningRepository').listLanguages()).includes(language)
  )
    throw new ApiError('Choose a supported language.', 422);
  policy.validate(payload.standards);
  const access = payload.access || 'Free';
  if (
    !['Free', 'Login', 'Premium'].includes(access) ||
    (resource === 'quizzes' && access === 'Login') ||
    (['alphabets', 'phonics'].includes(resource) && access !== 'Free')
  )
    throw new ApiError('Choose a supported access option.', 422);
  const group_name =
    resource === 'alphabets'
      ? String(payload.group_name || existing?.group_name || 'Alphabets').trim()
      : '';
  if (group_name.length > 255)
    throw new ApiError('Lesson name is too long.', 422);
  return {
    resource,
    title: payload.title.trim(),
    language,
    group_name,
    standards: payload.standards,
    access,
    image: String(payload.image || ''),
    audio: String(payload.audio || ''),
  };
}
async function create(payload) {
  return withTransaction(async () => {
    const t = await validateTopic(payload);
    const key = sourceKey(t.resource, t.language, t.title, t.group_name, '');
    const [[duplicate]] = await pool.query(
      'SELECT id FROM learning_topics WHERE resource=? AND language=? AND title=? AND group_name=? LIMIT 1',
      [t.resource, t.language, t.title, t.group_name],
    );
    if (duplicate)
      throw new ApiError(
        'This topic already exists in this section and language.',
        409,
      );
    let legacyId = null;
    if (t.resource === 'courses')
      legacyId = (
        await require('./adminRepository').createResource('courses', {
          title: t.title,
          language: t.language,
          image: t.image,
          show_plan: t.access,
          created: new Date().toISOString().slice(0, 10),
        })
      ).id;
    const [r] = await pool.query(
      `INSERT INTO learning_topics(resource,source_key,legacy_id,title,language,group_name,standards,image,audio,access) VALUES (?,?,?,?,?,?,?,?,?,?)`,
      [
        t.resource,
        key,
        legacyId,
        t.title,
        t.language,
        t.group_name,
        JSON.stringify(t.standards),
        t.image,
        t.audio,
        t.access,
      ],
    );
    return get(r.insertId);
  });
}
async function update(id, payload) {
  return withTransaction(async () => {
    const before = await get(id, true);
    if (Number(payload.revision) !== before.revision)
      throw new ApiError('This topic changed. Reload it before saving.', 409);
    const t = await validateTopic(payload, before),
      d = definition(t.resource);
    const [[duplicate]] = await pool.query(
      'SELECT id FROM learning_topics WHERE id<>? AND resource=? AND language=? AND title=? AND group_name=? AND legacy_grade=? LIMIT 1',
      [id, t.resource, t.language, t.title, t.group_name, before.legacy_grade],
    );
    if (duplicate)
      throw new ApiError('Another topic already uses this name.', 409);
    // Update legacy labels for old clients; standard assignments live only in metadata.
    const legacyChanged = [
      'title',
      'group_name',
      'image',
      'audio',
      'access',
    ].some((key) => t[key] !== before[key]);
    if (before.legacy_id && legacyChanged) {
      const fields = {
        courses: { title: t.title, image: t.image, show_plan: t.access },
        alphabets: { letter: t.title, coursename: t.group_name },
        quizzes: { topic: t.title, show_plan: t.access },
        stories: {
          title: t.title,
          show_plan: t.access,
          title_image: t.image,
          title_audio: t.audio,
        },
        phonics: { coursename: t.title, title_image: t.image },
      };
      const [[anchor]] = await pool.query(
        `SELECT id FROM \`${t.resource === 'courses' ? 'courses' : d.table}\` WHERE id=?`,
        [before.legacy_id],
      );
      if (anchor || (t.resource === 'courses' && before.legacy_id >= 1000000)) {
        const result = await require('./adminCatalogRepository').updateGroup(
          t.resource,
          before.legacy_id,
          fields[t.resource],
        );
        if (t.resource === 'courses' && result?.id)
          before.legacy_id = result.id;
      }
    }
    await pool.query(
      `UPDATE learning_topics SET source_key=?,legacy_id=?,title=?,group_name=?,standards=?,image=?,audio=?,access=?,revision=revision+1 WHERE id=?`,
      [
        sourceKey(
          t.resource,
          t.language,
          t.title,
          t.group_name,
          before.legacy_grade,
        ),
        before.legacy_id,
        t.title,
        t.group_name,
        JSON.stringify(t.standards),
        t.image,
        t.audio,
        t.access,
        id,
      ],
    );
    if (payload.apply_to_items === true)
      await pool.query(
        'UPDATE learning_topic_items SET standards=NULL WHERE topic_id=?',
        [id],
      );
    return get(id);
  });
}
function defaults(topic) {
  const d = definition(topic.resource);
  return {
    [d.title]: topic.title,
    [d.language]: topic.language,
    ...(topic.resource === 'alphabets' ? { coursename: topic.group_name } : {}),
    ...(topic.resource === 'stories'
      ? {
          grade: topic.legacy_grade,
          show_plan: topic.access,
          title_image: topic.image,
          title_audio: topic.audio,
        }
      : {}),
    ...(topic.resource === 'phonics' ? { title_image: topic.image } : {}),
    created: new Date().toISOString().slice(0, 10),
  };
}
async function saveItem(id, itemId, payload) {
  return withTransaction(async () => {
    const t = await get(id, true),
      d = definition(t.resource),
      admin = require('./adminRepository');
    if (itemId) {
      const [[link]] = await pool.query(
        'SELECT item_id FROM learning_topic_items WHERE topic_id=? AND item_id=? FOR UPDATE',
        [id, itemId],
      );
      if (!link) throw new ApiError('Item not found in this topic.', 404);
    }
    // Only content fields are editable here. Group identity is inherited server-side.
    const schema = admin
      .getResourceSchema()
      .find((s) => s.key === d.item).columns;
    const locked = new Set([
      d.title,
      d.language,
      d.level,
      'category',
      'subcategory',
      'course',
      'coursename',
      'show_plan',
      'title_image',
      'title_audio',
      'created',
    ]);
    const clean = Object.fromEntries(
      Object.entries(payload).filter(
        ([k]) => schema.includes(k) && !locked.has(k),
      ),
    );
    const item = itemId
      ? await admin.updateResource(d.item, itemId, clean)
      : await admin.createResource(d.item, { ...clean, ...defaults(t) });
    const override = Object.hasOwn(payload, 'standard_override')
      ? payload.standard_override
      : undefined;
    if (override !== undefined && override !== null) policy.validate(override);
    if (!itemId)
      await pool.query(
        'INSERT INTO learning_topic_items(resource,item_id,topic_id,standards) VALUES (?,?,?,?)',
        [
          t.resource,
          item.id,
          id,
          override == null ? null : JSON.stringify(override),
        ],
      );
    else if (override !== undefined)
      await pool.query(
        'UPDATE learning_topic_items SET standards=? WHERE resource=? AND item_id=?',
        [
          override === null ? null : JSON.stringify(override),
          t.resource,
          item.id,
        ],
      );
    if (!t.legacy_id)
      await pool.query('UPDATE learning_topics SET legacy_id=? WHERE id=?', [
        item.id,
        id,
      ]);
    if (t.resource === 'quizzes')
      await pool.query(
        'INSERT INTO quiz_topic_settings(language,topic,show_plan) VALUES (?,?,?) ON DUPLICATE KEY UPDATE show_plan=VALUES(show_plan)',
        [t.language, t.title, t.access],
      );
    await pool.query(
      'UPDATE learning_topics SET revision=revision+1 WHERE id=?',
      [id],
    );
    return item;
  });
}
async function deleteItem(id, itemId) {
  return withTransaction(async () => {
    const t = await get(id, true),
      d = definition(t.resource);
    const [[link]] = await pool.query(
      'SELECT item_id FROM learning_topic_items WHERE topic_id=? AND item_id=?',
      [id, itemId],
    );
    if (!link) throw new ApiError('Item not found in this topic.', 404);
    await require('./adminRepository').deleteResource(d.item, itemId);
    await pool.query(
      'DELETE FROM learning_topic_items WHERE topic_id=? AND item_id=?',
      [id, itemId],
    );
    if (t.resource !== 'courses' && Number(t.legacy_id) === Number(itemId)) {
      const [[next]] = await pool.query(
        'SELECT MIN(item_id) AS id FROM learning_topic_items WHERE topic_id=?',
        [id],
      );
      await pool.query('UPDATE learning_topics SET legacy_id=? WHERE id=?', [
        next.id,
        id,
      ]);
    }
    await pool.query(
      'UPDATE learning_topics SET revision=revision+1 WHERE id=?',
      [id],
    );
    return { deleted: true };
  });
}
async function removeTopic(id) {
  return withTransaction(async () => {
    const topic = await get(id, true);
    const [[count]] = await pool.query(
      'SELECT COUNT(*) total FROM learning_topic_items WHERE topic_id=?',
      [id],
    );
    if (count.total)
      throw new ApiError('Remove the items before deleting this topic.', 409);
    if (
      topic.resource === 'courses' &&
      topic.legacy_id &&
      topic.legacy_id < 1000000
    )
      await require('./adminRepository').deleteResource(
        'courses',
        topic.legacy_id,
      );
    if (topic.resource === 'quizzes')
      await pool.query(
        'DELETE FROM quiz_topic_settings WHERE language=? AND topic=?',
        [topic.language, topic.title],
      );
    await pool.query('DELETE FROM learning_topics WHERE id=?', [id]);
    return { deleted: true };
  });
}
module.exports = {
  defs,
  definition,
  sourceKey,
  backfill,
  filter,
  get,
  list,
  detail,
  create,
  update,
  saveItem,
  deleteItem,
  removeTopic,
  defaults,
};
