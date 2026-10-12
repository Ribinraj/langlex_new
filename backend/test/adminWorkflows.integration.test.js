const test = require('node:test');
const assert = require('node:assert/strict');

test('admin authentication, all catalog CRUD, users, billing and notification isolation', { skip: process.env.RUN_DB_TESTS !== '1' }, async () => {
  process.env.DB_NAME = `langlex_admin_test_${process.pid}_${Date.now()}`;
  const database = process.env.DB_NAME;
  const initialize = require('../src/infrastructure/database/initDatabase');
  const { pool, createBootstrapConnection } = require('../src/infrastructure/database/db');
  const env = require('../src/infrastructure/config/env');
  const push = require('../src/infrastructure/firebase/fcmService');
  const originalPush = push.sendToTokens;
  const deliveries = [];
  push.sendToTokens = async payload => { deliveries.push(payload); return { enabled: false, success: 0, requested: payload.tokens.length, invalidTokens: [] }; };
  let server, checks = 0;
  try {
    await initialize();
    server = require('../src/app').listen(0, '127.0.0.1');
    await new Promise(resolve => server.once('listening', resolve));
    const base = `http://127.0.0.1:${server.address().port}/api/admin`;
    let token = '';
    async function request(path, method = 'GET', body, expected = 200) {
      const response = await fetch(base + path, { method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, ...(body ? { body: JSON.stringify(body) } : {}) });
      const data = await response.json();
      assert.equal(response.status, expected, `${method} ${path}: ${JSON.stringify(data)}`);
      checks++;
      return data;
    }
    await request('/overview', 'GET', undefined, 401);
    await request('/auth/login', 'POST', { email: env.admin.email, password: 'wrong-password' }, 401);
    token = (await request('/auth/login', 'POST', { email: env.admin.email, password: env.admin.password })).token;
    assert.ok((await request('/auth/me')).admin.id);
    const schema = (await request('/resources/schema')).resources;
    for (const resource of schema) {
      const primary = ({ content: 'content', alphabets: 'letter', quizzes: 'Question', phonics: 'word', plans: 'name' })[resource.key] || 'title';
      const marker = `Admin QA ${resource.key}`;
      const payload = Object.fromEntries(resource.columns.map(column => [column, column === 'created' ? '2026-10-09' : column.toLowerCase() === 'language' ? 'English' : column === 'amount' ? '19' : column === 'permission' ? [] : column === 'show_plan' ? 'Premium' : '']));
      payload[primary] = marker;
      if (resource.key === 'quizzes') Object.assign(payload,{ca:'Correct',o1:'Incorrect',topic:marker});
      if (resource.key === 'content') payload.course = marker;
      if (['alphabets','phonics'].includes(resource.key)) payload.coursename = marker;
      if (resource.key === 'plans') Object.assign(payload,{type:'premium',plan_timeperiod:'Monthly'});
      await request(`/resources/${resource.key}`, 'POST', { ...payload, [primary]: '' }, 422);
      const { item } = await request(`/resources/${resource.key}`, 'POST', payload, 201);
      assert.ok(item.id);
      const found = await request(`/resources/${resource.key}?search=${encodeURIComponent(marker)}&limit=1&page=1&language=English`);
      assert.equal(found.total, 1); assert.equal(found.items.length, 1);
      assert.equal((await request(`/resources/${resource.key}/${item.id}`)).item[primary], marker);
      assert.equal((await request(`/resources/${resource.key}/${item.id}`, 'PUT', { [primary]: marker + ' revised' })).item[primary], marker + ' revised');
      await request(`/resources/${resource.key}/${item.id}`, 'DELETE');
      await request(`/resources/${resource.key}/${item.id}`, 'GET', undefined, 404);
    }
    await request('/resources/plans', 'POST', { name: 'Invalid', amount: -1 }, 422);
    await request('/resources/plans', 'POST', { name: 'Invalid JSON', amount: 1, permission: 'broken' }, 422);
    await request('/resources/constructor', 'GET', undefined, 404);
    for (const resource of ['categories', 'subcategories', 'courses', 'topics']) assert.ok(Array.isArray((await request(`/resource-options/${resource}?limit=1`)).items));
    for (const [mobile, name] of [['1000000001', 'Admin QA learner'], ['1000000002', 'Admin QA other']]) await pool.execute('INSERT INTO users (mobile_number, full_name) VALUES (?, ?)', [mobile, name]);
    const users = (await request('/users?search=Admin%20QA')).items;
    const user = users.find(row => row.full_name === 'Admin QA learner');
    const other = users.find(row => row.id !== user.id);
    assert.equal(users.length, 2);
    const edit = { full_name: 'Admin QA revised', email: 'admin-qa@example.com', school: 'QA school', city: 'QA city', state: 'QA state' };
    assert.equal((await request(`/users/${user.id}`, 'PUT', edit)).user.full_name, edit.full_name);
    await request(`/users/${user.id}`, 'PUT', { ...edit, email: 'invalid' }, 422);
    const { item: plan } = await request('/resources/plans', 'POST', { name: 'QA plan', amount: 19, type: 'premium', permission: [], plan_timeperiod: 'Monthly' }, 201);
    await pool.execute("INSERT INTO user_subscriptions(user_id,plan_id,status,started_at,expires_at) VALUES (?,?,'active',NOW(),DATE_ADD(NOW(),INTERVAL 1 DAY)),(?,?,'active',NOW(),DATE_ADD(NOW(),INTERVAL 2 DAY)),(?,?,'active',DATE_SUB(NOW(),INTERVAL 10 DAY),DATE_SUB(NOW(),INTERVAL 1 DAY))",[user.id,plan.id,user.id,plan.id,other.id,plan.id]);
    const active = await request('/users?search=Admin%20QA&status=active');
    assert.equal(active.total,1,'overlapping subscriptions must not duplicate learners'); assert.equal(active.items.length,1);
    assert.equal((await request('/users?search=Admin%20QA&status=inactive')).total,1);
    assert.equal((await request('/subscriptions?search=QA%20plan&status=expired')).total,1);
    assert.equal((await request('/subscriptions?search=QA%20plan&status=active')).total,2);
    assert.equal((await request(`/users/${other.id}`)).subscriptions[0].status,'expired');
    for (const status of ['paid','created','failed']) {
      await pool.execute("INSERT INTO payment_orders(user_id,plan_id,provider,provider_order_id,amount,currency,status) VALUES (?,?,'dummy',?,19,'INR',?)",[user.id,plan.id,`qa-${status}`,status]);
      assert.equal((await request(`/payments?search=Admin%20QA&status=${status}`)).items.length,1);
    }
    assert.ok((await request('/overview')).stats.users >= 2);
    await request('/notifications', 'POST', { title: 'QA notice', body: 'Test message', broadcast: false }, 422);
    assert.equal(deliveries.length,0,'missing user must not broadcast');
    const sent = await request('/notifications','POST',{userId:user.id,broadcast:false,title:'QA notice',body:'Only in temporary database'},201);
    assert.equal(sent.sent,1); assert.equal(deliveries.length,1);
    assert.equal((await request('/notifications?search=QA%20notice')).total,1);
    const broadcast = await request('/notifications','POST',{broadcast:true,title:'QA broadcast',body:'Only synthetic users; push mocked'},201);
    assert.equal(broadcast.sent,2); assert.equal(deliveries.length,2);
    await request(`/users/${user.id}`,'DELETE');
    await request(`/users/${user.id}`,'GET',undefined,404);
    const [[remaining]] = await pool.execute('SELECT COUNT(*) AS total FROM notifications WHERE user_id=?',[user.id]);
    assert.equal(remaining.total,0);
    await request(`/users/${other.id}`,'DELETE');
    await request(`/resources/plans/${plan.id}`,'DELETE');
    console.log(`Admin checks passed: ${checks} HTTP assertions; notifications used mocked push delivery.`);
  } finally {
    push.sendToTokens = originalPush;
    if (server) await new Promise(resolve => server.close(resolve));
    await pool.end();
    const connection = await createBootstrapConnection();
    try { await connection.query(`DROP DATABASE IF EXISTS \`${database}\``); } finally { await connection.end(); }
  }
});
