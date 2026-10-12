const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
test(
  'admin operations: blocking, manual subscriptions, audit atomicity, bulk previews and media',
  { skip: process.env.RUN_DB_TESTS !== '1' },
  async () => {
    process.env.DB_NAME = `langlex_operations_test_${process.pid}_${Date.now()}`;
    const db = process.env.DB_NAME;
    const initialize = require('../src/infrastructure/database/initDatabase');
    const {
      pool,
      createBootstrapConnection,
    } = require('../src/infrastructure/database/db');
    const env = require('../src/infrastructure/config/env');
    const fcm = require('../src/infrastructure/firebase/fcmService');
    const originalSend=fcm.sendToTokens;
    let sends=0;
    fcm.sendToTokens=async()=>{sends++;return {invalidTokens:[],requested:0,success:0}};
    let server,
      checks = 0,
      uploaded = [];
    try {
      await initialize();
      server = require('../src/app').listen(0, '127.0.0.1');
      await new Promise((r) => server.once('listening', r));
      const base = `http://127.0.0.1:${server.address().port}/api`;
      let token = '';
      const req = async (
        url,
        method = 'GET',
        body,
        status = 200,
        auth = token,
        raw = false,
      ) => {
        const res = await fetch(base + url, {
          method,
          headers: {
            'Content-Type': raw
              ? 'application/octet-stream'
              : 'application/json',
            'X-File-Name': 'qa.png',
            ...(auth ? { Authorization: `Bearer ${auth}` } : {}),
          },
          ...(body ? { body: raw ? body : JSON.stringify(body) } : {}),
        });
        const data = await res.json();
        assert.equal(
          res.status,
          status,
          `${method} ${url}: ${JSON.stringify(data)}`,
        );
        checks++;
        return data;
      };
      await req('/admin/audit', 'GET', null, 401);
      token = (
        await req('/admin/auth/login', 'POST', {
          email: env.admin.email,
          password: env.admin.password,
        })
      ).token;
      const [created] = await pool.execute(
        "INSERT INTO users(mobile_number,full_name,push_token) VALUES('1000000099','Operations QA','secret-token')",
      );
      const uid = created.insertId;
      const learner = require('../src/shared/utils/jwt').signToken({
        id: uid,
        mobile_number: '1000000099',
      });
      await req(
        `/admin/users/${uid}/access`,
        'PUT',
        { blocked: true, reason: 'QA moderation' },
        200,
      );
      assert.equal((await req(`/admin/users/${uid}`)).user.is_blocked, 1);
      assert.equal(
        (await req('/user/profile', 'GET', null, 403, learner)).details.code,
        'ACCOUNT_BLOCKED',
      );
      await req(
        '/auth/send-otp',
        'POST',
        { mobile_number: '1000000099' },
        403,
        '',
      );
      await req(
        '/auth/verify-otp',
        'POST',
        { mobile_number: '1000000099', otp: '123456' },
        403,
        '',
      );
      await req(`/admin/users/${uid}/access`, 'PUT', {
        blocked: false,
        reason: 'QA restored',
      });
      await req('/user/profile', 'GET', null, 200, learner);
      await req(
        `/admin/users/${uid}/access`,
        'PUT',
        { blocked: true, reason: '' },
        422,
      );
      const [{ id: pid }] = (
        await pool.query(
          "SELECT id FROM subsc_plans WHERE LOWER(type)='premium' LIMIT 1",
        )
      )[0];
      const expires = new Date(Date.now() + 86400000).toISOString();
      const first = (
        await req(
          `/admin/users/${uid}/subscriptions`,
          'POST',
          { plan_id: pid, expires_at: expires, reason: 'Complimentary access' },
          201,
        )
      ).subscription;
      assert.equal(first.payment_order_id, null);
      assert.equal(first.source, 'manual');
      assert.equal(
        (await req('/subscriptions/me', 'GET', null, 200, learner)).subscription
          .id,
        first.id,
      );
      const second = (
        await req(
          `/admin/users/${uid}/subscriptions`,
          'POST',
          { plan_id: pid, expires_at: expires, reason: 'Replace access' },
          201,
        )
      ).subscription;
      assert.equal(
        (
          await pool.execute(
            'SELECT status FROM user_subscriptions WHERE id=?',
            [first.id],
          )
        )[0][0].status,
        'cancelled',
      );
      assert.equal(
        (
          await pool.execute(
            'SELECT COUNT(*) count FROM payment_orders WHERE user_id=?',
            [uid],
          )
        )[0][0].count,
        0,
      );
      await req(`/admin/subscriptions/${second.id}`, 'PUT', {
        action: 'change_expiry',
        expires_at: new Date(Date.now() + 2 * 86400000).toISOString(),
        reason: 'Extension granted',
      });
      await req(
        `/admin/subscriptions/${second.id}`,
        'PUT',
        {
          action: 'change_expiry',
          expires_at: '2020-01-01T00:00:00Z',
          reason: 'Invalid expiry',
        },
        422,
      );
      await req(`/admin/subscriptions/${second.id}`, 'PUT', {
        action: 'cancel',
        reason: 'Requested cancellation',
      });
      assert.equal(
        (await req('/subscriptions/me', 'GET', null, 200, learner)).subscription
          .type,
        'free',
      );
      await req(
        `/admin/subscriptions/${second.id}`,
        'PUT',
        {
          action: 'change_expiry',
          expires_at: expires,
          reason: 'Invalid reactivation',
        },
        409,
      );
      await req('/admin/audit','GET',null,403,learner);
      await Promise.all([1,2].map(n=>req(`/admin/users/${uid}/subscriptions`,'POST',{plan_id:pid,expires_at:expires,reason:`Concurrent QA ${n}`},201)));
      assert.equal((await pool.execute("SELECT COUNT(*) total FROM user_subscriptions WHERE user_id=? AND status='active'",[uid]))[0][0].total,1);
      const batch = {
        operation: 'import',
        rows: [
          { title: 'Bulk QA one', language: 'English' },
          { title: 'Bulk QA two', language: 'English' },
        ],
      };
      const preview = await req(
        '/admin/bulk/categories/preview',
        'POST',
        batch,
      );
      assert.equal(
        (await req('/admin/resources/categories?search=Bulk%20QA')).total,
        0,
        'preview must not write content',
      );
      const applied = await req(`/admin/bulk/${preview.id}/apply`, 'POST', {});
      assert.equal(applied.count, 2);
      assert.equal(
        (await req(`/admin/bulk/${preview.id}/apply`, 'POST', {}))
          .already_applied,
        true,
      );
      assert.equal(
        (await req('/admin/resources/categories?search=Bulk%20QA')).total,
        2,
      );
      await req(
        '/admin/bulk/categories/preview',
        'POST',
        {
          operation: 'import',
          rows: [
            { title: 'Bulk QA rollback', language: 'English' },
            { title: '', language: 'English' },
          ],
        },
        422,
      );
      assert.equal(
        (await req('/admin/resources/categories?search=Bulk%20QA%20rollback'))
          .total,
        0,
      );
      await req(
        '/admin/bulk/categories/preview',
        'POST',
        { operation: 'edit', rows: [{ id: applied.ids[0], is_admin: 1 }] },
        422,
      );
      await req('/admin/bulk/categories/preview','POST',{operation:'edit',rows:[{id:applied.ids[0],language:''}]},422);
      const [[course]]=await pool.execute("SELECT id FROM courses WHERE language='English' LIMIT 1");
      await req('/admin/bulk/courses/preview','POST',{operation:'topics',rows:[{id:course.id,show_plan:''}]},422);
      const editing = await req('/admin/bulk/categories/preview', 'POST', {
        operation: 'edit',
        rows: [{ id: applied.ids[0], title: 'Bulk QA changed' }],
      });
      await req(`/admin/resources/categories/${applied.ids[0]}`, 'PUT', {
        title: 'Bulk QA newer',
      });
      await req(`/admin/bulk/${editing.id}/apply`, 'POST', {}, 409);
      const stale = await req('/admin/bulk/categories/preview', 'POST', {
        operation: 'edit',
        rows: [
          { id: applied.ids[0], title: 'Bulk QA row1' },
          { id: applied.ids[1], title: 'Bulk QA row2' },
        ],
      });
      await req(`/admin/resources/categories/${applied.ids[1]}`, 'PUT', {
        title: 'Bulk QA concurrent',
      });
      await req(`/admin/bulk/${stale.id}/apply`, 'POST', {}, 409);
      assert.equal(
        (await req(`/admin/resources/categories/${applied.ids[0]}`)).item.title,
        'Bulk QA newer',
        'failed second row rolls back first row',
      );
      const quiz = (
        await req(
          '/admin/resources/quizzes',
          'POST',
          {
            Question: 'Operations quiz?',
            ca: 'Yes',
            o1: 'No',
            topic: 'Operations QA topic',
            Language: 'English',
          },
          201,
        )
      ).item;
      const quiz2 = (
        await req(
          '/admin/resources/quizzes',
          'POST',
          {
            Question: 'Operations quiz 2?',
            ca: 'Yes',
            o1: 'No',
            topic: 'Operations QA topic',
            Language: 'English',
          },
          201,
        )
      ).item;
      const topicPreview = await req('/admin/bulk/quizzes/preview', 'POST', {
        operation: 'topics',
        rows: [
          { id: quiz.id, topic: 'Operations renamed', show_plan: 'Premium' },
        ],
      });
      assert.equal(
        (await req(`/admin/catalog/quizzes/${quiz.id}/items`)).group.show_plan,
        'Free',
      );
      await req(`/admin/bulk/${topicPreview.id}/apply`, 'POST', {});
      assert.equal(
        (await req(`/admin/catalog/quizzes/${quiz2.id}/items`)).group.show_plan,
        'Premium',
      );
      assert.equal(
        (await req(`/admin/resources/quizzes/${quiz2.id}`)).item.topic,
        'Operations renamed',
      );
      await req(
        '/admin/bulk/quizzes/preview',
        'POST',
        { operation: 'edit', rows: [{ id: quiz.id, show_plan: 'Free' }] },
        422,
      );
      const expired = await req(
        '/admin/bulk/categories/preview',
        'POST',
        batch,
      );
      await pool.execute(
        'UPDATE admin_bulk_previews SET expires_at=DATE_SUB(NOW(),INTERVAL 1 SECOND) WHERE id=?',
        [expired.id],
      );
      await req(`/admin/bulk/${expired.id}/apply`, 'POST', {}, 409);
      // Audit failure must roll back the business mutation as well.
      await pool.query(
        "CREATE TRIGGER qa_deny_audit BEFORE INSERT ON admin_audit_log FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='QA audit unavailable'",
      );
      await req(
        `/admin/resources/categories/${applied.ids[0]}`,
        'PUT',
        { title: 'Must roll back' },
        500,
      );
      assert.equal(
        (await req(`/admin/resources/categories/${applied.ids[0]}`)).item.title,
        'Bulk QA newer',
      );
      await req('/admin/notifications','POST',{userId:uid,title:'QA failure',body:'Never deliver this message'},500);
      assert.equal(sends,0,'an audit failure must prevent push delivery');
      assert.equal((await pool.execute('SELECT COUNT(*) total FROM notifications WHERE user_id=?',[uid]))[0][0].total,0);
      await pool.query('DROP TRIGGER qa_deny_audit');
      await req(
        '/admin/media',
        'POST',
        Buffer.from('<svg><script>alert(1)</script></svg>'),
        422,
        token,
        true,
      );
      const png = Buffer.from(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
        'base64',
      );
      await req('/admin/media','POST',Buffer.concat([png,Buffer.alloc(5*1024*1024)]),413,token,true);
      const media = (await req('/admin/media', 'POST', png, 201, token, true))
        .item;
      uploaded.push(media.path);
      const wav=Buffer.alloc(46);
      wav.write('RIFF',0);wav.writeUInt32LE(38,4);wav.write('WAVEfmt ',8);
      wav.writeUInt32LE(16,16);wav.writeUInt16LE(1,20);wav.writeUInt16LE(1,22);
      wav.writeUInt32LE(8000,24);wav.writeUInt32LE(16000,28);wav.writeUInt16LE(2,32);wav.writeUInt16LE(16,34);
      wav.write('data',36);wav.writeUInt32LE(2,40);
      const audio=(await req('/admin/media','POST',wav,201,token,true)).item;
      uploaded.push(audio.path);assert.equal(audio.mime_type,'audio/wav');assert.match(audio.path,/\.wav$/);
      const audioResponse=await fetch(base.replace('/api','')+audio.path);
      assert.equal(audioResponse.status,200);assert.deepEqual(Buffer.from(await audioResponse.arrayBuffer()),wav);

      assert.match(media.path, /^\/media\/uploads\/[a-f0-9-]+\.png$/);
      assert.equal((await req('/admin/media?search=qa.png')).total, 2);
      const file = await fetch(base.replace('/api', '') + media.path);
      assert.equal(file.status, 200);
      assert.equal(file.headers.get('content-type'), 'image/png');
      await req(`/admin/users/${uid}`, 'DELETE');
      const history = await req('/admin/audit?limit=100');
      assert.ok(
        history.items.find(
          (x) =>
            x.entity === 'users' &&
            x.action === 'block' &&
            String(x.entity_id) === String(uid),
        ),
        'history retained after user deletion',
      );
      assert.ok(history.items.every((x) => x.admin_email === env.admin.email));
      assert.ok(!JSON.stringify(history).includes('secret-token'));
      assert.ok(history.items.find((x) => x.action === 'upload'));
      console.log(
        `Admin operations: ${checks} HTTP assertions plus database rollback and audit checks passed`,
      );
    } finally {
      fcm.sendToTokens=originalSend;
      if (server) await new Promise((r) => server.close(r));
      await pool.end();
      const c = await createBootstrapConnection();
      await c.query(`DROP DATABASE IF EXISTS \`${db}\``);
      await c.end();
      for (const name of uploaded)
        await fs
          .unlink(path.join(__dirname, '../public', name))
          .catch(() => {});
    }
  },
);
