const { pool } = require('../database/db');
const catalog = require('./catalogRepository');
const learning = require('./learningRepository');
const ApiError = require('../../shared/errors/apiError');
const { pagination, pageResult } = require('../../shared/utils/pagination');

// These are storage names, not editable SQL identifiers supplied by the client.
const resources = {
  categories: { table: 'categories', language: 'language' },
  subcategories: { table: 'subcategories', language: 'language' },
  courses: { table: 'courses', language: 'language' },
  content: { table: 'Content', language: 'language' },
  alphabets: { table: 'Alphabets', language: 'language', group: ['coursename', 'letter'], title: 'letter' },
  quizzes: { table: 'quizz', language: 'Language', group: ['topic'], title: 'topic' },
  phonics: { table: 'Phonics', language: 'language', group: ['coursename'], title: 'coursename' },
  stories: { table: 'stories', language: 'language', group: ['title', 'grade'], title: 'title' },
  plans: { table: 'subsc_plans' },
};
const optionFields = {
  categories: [], subcategories: [], courses: ['show_plan'], content: [],
  alphabets: ['level', 'letter_type'], quizzes: ['difflvl', 'QType', 'show_plan'],
  phonics: ['level'], stories: ['grade', 'show_plan'], plans: ['type', 'plan_timeperiod'],
};
const definition = resource => {
  if (!Object.hasOwn(resources, resource)) throw new ApiError('Unknown catalog resource', 404);
  return resources[resource];
};
const columnSql = (column) => column === 'letter' ? 'BINARY TRIM(`letter`)' : `\`${column}\``;
async function formOptions(resource, language = '') {
  const def = definition(resource);
  const options = { language: await learning.listLanguages() };
  options.Language = options.language;
  for (const column of optionFields[resource]) {
    // Access values are shared by courses and stories; both come from original rows.
    if (resource === 'quizzes' && column === 'show_plan') {
      options.show_plan = ['Free','Premium'];
    } else if (column === 'show_plan') {
      const [rows] = await pool.query("SELECT DISTINCT show_plan AS value FROM (SELECT show_plan FROM courses UNION SELECT show_plan FROM stories) access_values WHERE TRIM(show_plan) <> '' ORDER BY value");
      options[column] = rows.map(row => row.value);
    } else {
      const scoped = Boolean(language && def.language);
      const [rows] = await pool.query(`SELECT DISTINCT \`${column}\` AS value FROM \`${def.table}\` WHERE TRIM(\`${column}\`) <> '' ${scoped ? `AND \`${def.language}\`=?` : ''} ORDER BY value`, scoped ? [language] : []);
      options[column] = rows.map(row => row.value);
    }
  }
  return { options };
}

async function references(resource, field, query = {}) {
  const def = definition(resource);
  const mappings = {
    p_cat: [['categories','title','language']],
    category: [['categories','title','language'],[def.table,'category',def.language]],
    subcategory: [['subcategories','title','language'],[def.table,'subcategory',def.language]],
    course: [['courses','title','language'],['Content','course','language']],
    coursename: [[def.table,'coursename',def.language]],
    topic: [['quizz','topic','Language']],
  };
  const supported = ({ subcategories:['p_cat'], content:['category','subcategory','course'], alphabets:['category','subcategory','coursename'], phonics:['category','subcategory','coursename'], quizzes:['topic'] })[resource] || [];
  if (!supported.includes(field)) throw new ApiError('Unknown reference field',404);
  const params = [];
  const sources = mappings[field].map(([table,column,language]) => {
    if (query.language) params.push(query.language);
    return `SELECT \`${column}\` AS value FROM \`${table}\` ${query.language ? `WHERE \`${language}\`=?` : ''}`;
  });
  const paging = pagination(query);
  const sql = `SELECT DISTINCT value FROM (${sources.join(' UNION ALL ')}) choices WHERE TRIM(value)<>'' ${query.search ? 'AND LOCATE(?,value)>0' : ''}`;
  if (query.search) params.push(query.search);
  const [[count]] = await pool.query(`SELECT COUNT(*) AS total FROM (${sql}) counted`,params);
  const [rows] = await pool.query(`${sql} ORDER BY value LIMIT ? OFFSET ?`,[...params,paging.limit,paging.offset]);
  return pageResult(rows.map(row=>row.value),count.total,paging);
}

async function groups(resource, query = {}) {
  const def = definition(resource);
  if (resource === 'courses') {
    const result = await catalog.courses(query);
    return { items: result.items.map(row => ({ ...row, item_count: row.word_count, virtual: Number(row.id) >= 1000000 })), total: result.pagination.total, page: result.pagination.page, limit: result.pagination.limit };
  }
  if (!def.group) throw new ApiError('This resource does not have grouped activities', 400);
  const paging = pagination(query);
  const where = [], params = [];
  if (query.language) { where.push(`\`${def.language}\`=?`); params.push(query.language); }
  // Search selects complete groups, rather than dropping nonmatching passages/examples.
  if (query.search) { where.push(`LOCATE(?, \`${def.title}\`)>0`); params.push(query.search); }
  const keys = [def.language, ...def.group];
  const groupSql = keys.map(columnSql).join(',');
  const summaries = `SELECT MIN(id) AS id, MIN(\`${def.title}\`) AS title, MIN(\`${def.language}\`) AS language, COUNT(*) AS item_count ${resource === 'stories' ? ", MIN(grade) AS grade, CASE WHEN SUM(LOWER(TRIM(show_plan)) IN ('premium','paid','1')) > 0 THEN 'Premium' WHEN SUM(LOWER(TRIM(show_plan))='login') > 0 THEN 'Login' ELSE 'Free' END AS show_plan" : ''} ${resource === 'alphabets' ? ', MIN(coursename) AS course' : ''} FROM \`${def.table}\` ${where.length ? `WHERE ${where.join(' AND ')}` : ''} GROUP BY ${groupSql}`;
  const [[count]] = await pool.query(`SELECT COUNT(*) AS total FROM (${summaries}) groups_count`, params);
  const [items] = await pool.query(`${summaries} ORDER BY id LIMIT ? OFFSET ?`, [...params, paging.limit, paging.offset]);
  if (resource === 'quizzes' && items.length) {
    const [settings] = await pool.query(`SELECT language,topic,show_plan FROM quiz_topic_settings WHERE (language,topic) IN (${items.map(()=>'(?,?)').join(',')})`,items.flatMap(row=>[row.language,row.title]));
    const key = (language,topic) => JSON.stringify([language.toLowerCase(),topic.toLowerCase()]);
    const access = new Map(settings.map(row=>[key(row.language,row.topic),row.show_plan]));
    for (const row of items) row.show_plan = access.get(key(row.language,row.title)) || 'Free';
  }
  return { items, total: Number(count.total), page: paging.page, limit: paging.limit };
}

async function groupScope(resource, id, executor = pool, lock = false) {
  const def = definition(resource);
  if (!def.group && resource !== 'courses') throw new ApiError('This resource does not have grouped activities', 400);
  let row;
  if (resource === 'courses' && Number(id) >= 1000000) {
    [[row]] = await executor.query('SELECT course AS title, language, content_image AS image, created FROM Content WHERE id=?' + (lock ? ' FOR UPDATE' : ''), [Number(id) - 1000000]);
  } else {
    [[row]] = await executor.query(`SELECT * FROM \`${def.table}\` WHERE id=?${lock ? ' FOR UPDATE' : ''}`, [id]);
  }
  if (!row) throw new ApiError('Activity not found. Refresh the catalog.', 404);
  const childResource = resource === 'courses' ? 'content' : resource;
  const child = definition(childResource);
  const keys = resource === 'courses' ? ['language', 'course'] : [def.language, ...def.group];
  const values = resource === 'courses' ? [row.language, row.title] : keys.map(key => key === 'letter' ? row[key].trim() : row[key]);
  const where = keys.map(key => `${columnSql(key)}=?`).join(' AND ');
  return { resource, id: Number(id), row, childResource, table: child.table, where, values, keys };
}
async function groupItems(resource, id, query = {}) {
  const scope = await groupScope(resource, id);
  const paging = pagination(query);
  const [[count]] = await pool.query(`SELECT COUNT(*) AS total FROM \`${scope.table}\` WHERE ${scope.where}`, scope.values);
  const [items] = await pool.query(`SELECT * FROM \`${scope.table}\` WHERE ${scope.where} ORDER BY id LIMIT ? OFFSET ?`, [...scope.values, paging.limit, paging.offset]);
  const group = { ...scope.row };
  if (resource === 'quizzes') {
    const [[setting]] = await pool.query('SELECT show_plan FROM quiz_topic_settings WHERE language=? AND topic=?',[group.Language,group.topic]);
    group.show_plan = setting?.show_plan || 'Free';
  }
  if (resource === 'stories') {
    const [[access]] = await pool.query(`SELECT CASE WHEN SUM(LOWER(TRIM(show_plan)) IN ('premium','paid','1'))>0 THEN 'Premium' WHEN SUM(LOWER(TRIM(show_plan))='login')>0 THEN 'Login' ELSE 'Free' END AS show_plan FROM stories WHERE ${scope.where}`,scope.values);
    group.show_plan = access.show_plan;
  }
  if (resource === 'courses') group.show_plan = require('../../application/learning/contentAccess').normalizeAccess(group.show_plan);
  const defaults = Object.fromEntries(scope.keys.map((key,index)=>[key,scope.values[index]]));
  for (const key of ['show_plan','title_image','title_audio']) if (Object.hasOwn(group,key)) defaults[key] = group[key];
  return { ...pageResult(items, count.total, paging), total: Number(count.total), page: paging.page, limit: paging.limit, child_resource: scope.childResource, group, identity_fields: scope.keys, defaults };

}
async function updateGroup(resource, id, payload) {
  if (resource === 'courses') {
    const admin = require('./adminRepository');
    if (Number(id) < 1000000) return admin.updateResource(resource, id, payload);
    const scope = await groupScope(resource, id);
    const next = { title: scope.row.title, language: scope.row.language, image: scope.row.image || '', created: scope.row.created || new Date().toISOString().slice(0,10), show_plan: 'Free', ...payload };
    await admin.validateResource('courses',next);
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      const current = await groupScope(resource,id,conn,true);
      const [duplicates] = await conn.query('SELECT id FROM courses WHERE (title=? AND language=?) OR (title=? AND language=?) LIMIT 1 FOR UPDATE',[current.row.title,current.row.language,next.title,next.language]);
      if (duplicates.length) throw new ApiError('A course already exists with this name. Refresh the topics or choose another title.',409);
      const [targetWords] = await conn.query('SELECT id FROM Content WHERE course=? AND language=? AND NOT (course=? AND language=?) LIMIT 1 FOR UPDATE',[next.title,next.language,current.row.title,current.row.language]);
      if (targetWords.length) throw new ApiError('A topic already exists with this name. Choose another title.',409);
      const [result] = await conn.query('INSERT INTO courses(title,language,image,created,show_plan) VALUES (?,?,?,?,?)',[next.title,next.language,next.image,next.created,next.show_plan]);
      await conn.query('UPDATE Content SET course=?,language=? WHERE course=? AND language=?',[next.title,next.language,current.row.title,current.row.language]);
      await conn.commit();
      return admin.getResource('courses',result.insertId);
    } catch (error) { await conn.rollback(); throw error; } finally { conn.release(); }

  }
  const def = definition(resource);
  if (!def.group) throw new ApiError('This resource does not have grouped activities', 400);
  const allowed = ({stories:['title','language','grade','show_plan','title_image','title_audio'],alphabets:['letter','coursename','language'],quizzes:['topic','Language','show_plan'],phonics:['coursename','language','title_image']})[resource];
  const updates = Object.keys(payload).filter(key => allowed.includes(key));
  if (!updates.length) throw new ApiError('No activity fields supplied', 422);
  for (const field of updates) if (typeof payload[field] !== 'string' || (!payload[field].trim() && [def.title,def.language,'coursename'].includes(field))) throw new ApiError(`${field} is required`, 422);
  if (Object.hasOwn(payload,'show_plan') && !['Free','Login','Premium'].includes(payload.show_plan)) throw new ApiError('Choose Free, Login or Premium', 422);
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const scope = await groupScope(resource, id, conn, true);
    const { options } = await formOptions(resource, payload[def.language] || scope.row[def.language]);
    for (const field of ['grade', 'show_plan', def.language]) {
      if (payload[field] && payload[field] !== scope.row[field] && !options[field]?.includes(payload[field])) throw new ApiError(`Choose an existing ${field} value from the catalog`, 422);
    }
    const next = { ...scope.row, ...Object.fromEntries(updates.map(key=>[key,payload[key]])) };
    const keys = [def.language, ...def.group];
    const targetWhere = keys.map(key => `${columnSql(key)}=?`).join(' AND ');
    const values = keys.map(key => key === 'letter' ? next[key].trim() : next[key]);
    const [collision] = await conn.query(`SELECT id FROM \`${def.table}\` WHERE ${targetWhere} AND NOT (${scope.where}) LIMIT 1 FOR UPDATE`, [...values, ...scope.values]);
    if (collision.length) throw new ApiError('An activity with this name already exists. Choose a different name.', 409);
    if (resource === 'quizzes') {
      const [[setting]] = await conn.query('SELECT show_plan FROM quiz_topic_settings WHERE language=? AND topic=? FOR UPDATE',[scope.row.Language,scope.row.topic]);
      await conn.query('DELETE FROM quiz_topic_settings WHERE language=? AND topic=?',[scope.row.Language,scope.row.topic]);
      await conn.query('INSERT INTO quiz_topic_settings(language,topic,show_plan) VALUES (?,?,?) ON DUPLICATE KEY UPDATE show_plan=VALUES(show_plan)',[next.Language,next.topic,payload.show_plan || setting?.show_plan || 'Free']);
    }
    const stored = updates.filter(key => resource !== 'quizzes' || key !== 'show_plan');
    if (stored.length) await conn.query(`UPDATE \`${def.table}\` SET ${stored.map(key => `\`${key}\`=?`).join(',')} WHERE ${scope.where}`, [...stored.map(key => payload[key]), ...scope.values]);
    await conn.commit();
    return { updated: true };
  } catch (error) { await conn.rollback(); throw error; } finally { conn.release(); }
}
module.exports = { references, resources, definition, formOptions, groups, groupScope, groupItems, updateGroup };
