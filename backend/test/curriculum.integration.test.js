const test = require('node:test');
const assert = require('node:assert/strict');

test(
  'curriculum preserves source data, applies standards consistently and audits local administration',
  { skip: process.env.RUN_DB_TESTS !== '1' },
  async () => {
    process.env.DB_NAME = `langlex_curriculum_${process.pid}_${Date.now()}`;
    const {
      pool,
      createBootstrapConnection,
    } = require('../src/infrastructure/database/db');
    const repo = require('../src/infrastructure/repositories/curriculumRepository');
    const catalog = require('../src/infrastructure/repositories/catalogRepository');
    const progress = require('../src/infrastructure/repositories/progressCatalogRepository');
    const env = require('../src/infrastructure/config/env');
    let server;
    try {
      await require('../src/infrastructure/database/initDatabase')();
      const [[before]] = await pool.query('SELECT COUNT(*) count FROM Content');
      const [topics] = await pool.query(
        "SELECT * FROM learning_topics WHERE resource='courses' AND language='English' AND title='Pet Animals'",
      );
      assert.equal(topics.length, 1);
      const topic = await repo.get(topics[0].id);
      assert.deepEqual(topic.standards, ['Nursery']);
      const original = await repo.detail(topic.id, { limit: 100 });
      assert.equal(original.total, 25);
      await repo.backfill();
      assert.equal((await repo.detail(topic.id, { limit: 100 })).total, 25);
      const [[after]] = await pool.query('SELECT COUNT(*) count FROM Content');
      assert.equal(after.count, before.count);
      server = require('../src/app').listen(0, '127.0.0.1');
      await new Promise((r) => server.once('listening', r));
      const base = `http://127.0.0.1:${server.address().port}/api`;
      const login = await fetch(base + '/admin/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(env.admin),
      });
      const token = (await login.json()).token;
      assert.ok(token);
      async function request(
        path,
        { method = 'GET', body, status = 200, auth = token } = {},
      ) {
        const r = await fetch(base + path, {
          method,
          headers: {
            'Content-Type': 'application/json',
            ...(auth ? { Authorization: `Bearer ${auth}` } : {}),
          },
          ...(body ? { body: JSON.stringify(body) } : {}),
        });
        const data = await r.json();
        assert.equal(r.status, status, `${path}: ${JSON.stringify(data)}`);
        return data;
      }
      await request('/admin/curriculum?resource=courses', {
        auth: null,
        status: 401,
      });
      const body = (t) => ({
        title: t.title,
        language: t.language,
        standards: t.standards,
        access: t.access,
        image: t.image,
        audio: t.audio,
        group_name: t.group_name,
        revision: t.revision,
      });
      const updated = await request(`/admin/curriculum/${topic.id}`, {
        method: 'PUT',
        body: { ...body(topic), standards: ['Nursery', 'LKG'] },
      });
      await request(`/admin/curriculum/${topic.id}`, {
        method: 'PUT',
        body: { ...body(topic), title: 'Stale change' },
        status: 409,
      });
      assert.ok(
        (
          await catalog.courses({
            language: 'English',
            level: 'LKG',
            limit: 100,
          })
        ).items.some((c) => c.title === 'Pet Animals'),
      );
      const eligible = await catalog.list('content', {
        course: topic.title,
        language: 'English',
        level: 'LKG',
        limit: 100,
      });
      assert.equal(eligible.items.length, 25);
      assert.deepEqual(
        eligible.items.map((r) => r.id),
        original.items.map((r) => r.id),
      );
      assert.ok(
        (await progress.topics('English', 'LKG')).some(
          (t) => t.content_key === `course-${topic.legacy_id}`,
        ),
      );
      await repo.backfill();
      assert.deepEqual((await repo.get(topic.id)).standards, [
        'Nursery',
        'LKG',
      ]);
      const newTopic = await request('/admin/curriculum', {
        method: 'POST',
        status: 201,
        body: {
          resource: 'quizzes',
          title: 'Curriculum QA',
          language: 'English',
          standards: ['Class 1'],
          access: 'Free',
        },
      });
      const question = await request(`/admin/curriculum/${newTopic.id}/items`, {
        method: 'POST',
        status: 201,
        body: {
          Question: 'Which one?',
          ca: 'One',
          o1: 'Two',
          Language: 'Hindi',
          topic: 'Wrong group',
          difflvl: 'Nursery',
        },
      });
      assert.equal(question.item.Language, 'English');
      assert.equal(question.item.topic, newTopic.title);
      let detail = await repo.detail(newTopic.id);
      assert.deepEqual(detail.items[0].effective_standards, ['Class 1']);
      assert.equal(
        (
          await catalog.list('quizzes', {
            language: 'English',
            level: 'Nursery',
            topic: newTopic.title,
          })
        ).items.length,
        0,
      );
      assert.equal(
        (
          await catalog.list('quizzes', {
            language: 'English',
            level: 'Class 1',
            topic: newTopic.title,
          })
        ).items.length,
        1,
      );
      await request(
        `/admin/curriculum/${newTopic.id}/items/${question.item.id}`,
        {
          method: 'PUT',
          body: { Question: 'Overridden', standard_override: ['UKG'] },
        },
      );
      detail = await repo.detail(newTopic.id);
      assert.deepEqual(detail.items[0].effective_standards, ['UKG']);
      assert.equal(detail.topic.override_count, 1);
      const second = await repo.saveItem(newTopic.id, null, {
        Question: 'Second',
        ca: 'Yes',
        o1: 'No',
      });
      const sets = await catalog.list('quizzes', {
        language: 'English',
        level: 'Class 1',
        view: 'sets',
        search: 'Curriculum QA',
      });
      assert.equal(
        sets.items[0].id,
        question.item.id,
        'Topic identity remains anchored even when first question is excluded',
      );
      assert.equal(sets.items[0].question_count, 1);
      let saved = await repo.get(newTopic.id);
      await request(`/admin/curriculum/${newTopic.id}`, {
        method: 'PUT',
        body: { ...body(saved), standards: ['LKG'] },
      });
      detail = await repo.detail(newTopic.id);
      assert.deepEqual(
        detail.items.find((i) => i.id === question.item.id).effective_standards,
        ['UKG'],
      );
      assert.deepEqual(
        detail.items.find((i) => i.id === second.id).effective_standards,
        ['LKG'],
      );
      saved = await repo.get(newTopic.id);
      await request(`/admin/curriculum/${newTopic.id}`, {
        method: 'PUT',
        body: {
          ...body(saved),
          standards: ['*'],
          apply_to_items: true,
          title: 'Curriculum QA renamed',
        },
      });
      assert.equal((await repo.detail(newTopic.id)).topic.override_count, 0);
      assert.equal(
        (
          await catalog.list('quizzes', {
            language: 'English',
            level: 'Playgroup',
            topic: 'Curriculum QA renamed',
          })
        ).items.length,
        2,
      );
      const preview = await repo.list({
        resource: 'quizzes',
        language: 'English',
        standard: 'Playgroup',
        search: 'Curriculum QA',
      });
      assert.equal(preview.items[0].eligible_count, 2);
      await request(`/admin/curriculum/${topic.id}/items/${question.item.id}`, {
        method: 'PUT',
        body: { content: 'Wrong parent' },
        status: 404,
      });
      const itemBefore = await repo.detail(newTopic.id);
      await request(
        `/admin/curriculum/${newTopic.id}/items/${question.item.id}`,
        {
          method: 'PUT',
          body: { Question: 'Must roll back', standard_override: ['Class 99'] },
          status: 422,
        },
      );
      assert.equal(
        (await repo.detail(newTopic.id)).items[0].Question,
        itemBefore.items[0].Question,
      );
      saved = await repo.get(newTopic.id);
      await request(`/admin/curriculum/${newTopic.id}`, {
        method: 'PUT',
        body: { ...body(saved), standards: ['*', 'Nursery'] },
        status: 422,
      });
      await request('/admin/curriculum', {
        method: 'POST',
        body: {
          resource: 'quizzes',
          title: 'Curriculum QA renamed',
          language: 'English',
          standards: ['LKG'],
        },
        status: 409,
      });
      // Signed-in requests use the saved standard even if the client requests a different one.
      const [u] = await pool.query(
        "INSERT INTO users(mobile_number,full_name) VALUES ('9911223344','Curriculum test')",
      );
      await pool.query(
        "INSERT INTO user_learning_setups(user_id,primary_language,learning_language,level,selected_languages) VALUES (?,'English','English','Nursery',?)",
        [u.insertId, JSON.stringify(['English', 'Hindi', 'Kannada'])],
      );
      const userToken = require('../src/shared/utils/jwt').signToken({
        id: u.insertId,
        mobile_number: '9911223344',
      });
      const nursery = await request(
        '/quizzes?level=UKG&language=English&topic=Insects',
        { auth: userToken },
      );
      assert.equal(nursery.quizzes.length, 0);
      // Standards never erase already earned completion records.
      await pool.query(
        "INSERT INTO user_learning_completions(user_id,content_type,item_id) VALUES (?,'course',?)",
        [u.insertId, original.items[0].id],
      );
      const latest = await repo.get(topic.id);
      await repo.update(topic.id, {
        ...body(latest),
        standards: ['Class 2'],
        apply_to_items: true,
      });
      assert.equal(
        (
          await pool.query(
            'SELECT COUNT(*) count FROM user_learning_completions WHERE user_id=?',
            [u.insertId],
          )
        )[0][0].count,
        1,
      );
      assert.equal(
        (
          await catalog.list('content', {
            language: 'English',
            course: 'Pet Animals',
            level: 'Nursery',
          })
        ).items.length,
        0,
      );
      const [[audit]] = await pool.query(
        "SELECT COUNT(*) count FROM admin_audit_log WHERE entity='learning_topics'",
      );
      assert.ok(audit.count >= 6);
      const [[virtualRow]] = await pool.query(
        "SELECT id FROM learning_topics WHERE resource='courses' AND legacy_id>=1000000 LIMIT 1",
      );
      const virtual = await repo.get(virtualRow.id);
      const [[courseCount]] = await pool.query(
        'SELECT COUNT(*) count FROM courses',
      );
      await repo.update(virtual.id, { ...body(virtual), standards: ['LKG'] });
      assert.equal(
        (await pool.query('SELECT COUNT(*) count FROM courses'))[0][0].count,
        courseCount.count,
        'Assigning standards must not materialize or replace original course records',
      );
      const previewTopics = await repo.list({
        resource: 'courses',
        language: 'English',
        standard: 'Nursery',
        limit: 100,
      });
      for (const row of previewTopics.items) {
        const actual = await catalog.list('content', {
          language: 'English',
          level: 'Nursery',
          course: row.title,
          limit: 1,
        });
        assert.equal(
          row.eligible_count,
          actual.pagination.total,
          'Preview counts exclude the same legacy placeholders as the learner API',
        );
      }
      const emptyTopic = await repo.create({
        resource: 'courses',
        title: 'Empty QA',
        language: 'English',
        standards: ['LKG'],
        access: 'Free',
      });
      await request(`/admin/curriculum/${emptyTopic.id}`, { method: 'DELETE' });
      await assert.rejects(repo.get(emptyTopic.id), { statusCode: 404 });
      await request(`/admin/curriculum/${newTopic.id}`, {
        method: 'DELETE',
        status: 409,
      });
      const [[overrideAudit]] = await pool.query(
        "SELECT after_data FROM admin_audit_log WHERE entity='learning_topics' AND action='update_item' ORDER BY id DESC LIMIT 1",
      );
      const logged =
        typeof overrideAudit.after_data === 'string'
          ? JSON.parse(overrideAudit.after_data)
          : overrideAudit.after_data;
      assert.deepEqual(logged.standard_override, ['UKG']);
      const bulkTopic = await repo.create({
        resource: 'quizzes',
        title: 'Bulk curriculum QA',
        language: 'English',
        standards: ['Class 1'],
        access: 'Free',
      });
      const batch = await request(`/admin/bulk/topic:${bulkTopic.id}/preview`, {
        method: 'POST',
        body: {
          operation: 'import',
          rows: [
            { Question: 'First bulk', ca: 'A', o1: 'B' },
            { Question: 'Second bulk', ca: 'C', o1: 'D' },
          ],
        },
      });
      assert.equal(
        (await repo.detail(bulkTopic.id)).total,
        0,
        'Preview does not persist content or mapping rows',
      );
      const applied = await request(`/admin/bulk/${batch.id}/apply`, {
        method: 'POST',
      });
      assert.equal(applied.count, 2);
      assert.equal(
        (await request(`/admin/bulk/${batch.id}/apply`, { method: 'POST' }))
          .already_applied,
        true,
      );
      const bulkItems = await repo.detail(bulkTopic.id);
      assert.equal(bulkItems.total, 2);
      assert.deepEqual(bulkItems.items[0].effective_standards, ['Class 1']);
      const stale = await request(`/admin/bulk/topic:${bulkTopic.id}/preview`, {
        method: 'POST',
        body: {
          operation: 'edit',
          rows: [{ id: bulkItems.items[0].id, Question: 'New question' }],
        },
      });
      const bt = await repo.get(bulkTopic.id);
      await repo.update(bt.id, { ...body(bt), standards: ['LKG'] });
      await request(`/admin/bulk/${stale.id}/apply`, {
        method: 'POST',
        status: 409,
      });
      await request(`/admin/bulk/topic:${bulkTopic.id}/preview`, {
        method: 'POST',
        body: {
          operation: 'import',
          rows: [
            { Question: 'Valid', ca: 'A', o1: 'B' },
            { Question: 'Invalid', ca: 'A' },
          ],
        },
        status: 422,
      });
      assert.equal((await repo.detail(bulkTopic.id)).total, 2);
      // All original primary keys and legacy grade values survive metadata assignment.
      const [[source]] = await pool.query(
        'SELECT category FROM Content WHERE id=?',
        [original.items[0].id],
      );
      assert.equal(source.category, 'Nursery');
      for (const [resource, title, fields] of [
        ['alphabets', 'Ω', { ill_word: 'Omega' }],
        ['stories', 'QA story', { text: 'Passage one' }],
        ['phonics', 'QA sound', { word: 'Hello' }],
      ]) {
        const t = await repo.create({
          resource,
          title,
          language: 'English',
          standards: ['Class 2'],
          access: 'Free',
        });
        await repo.saveItem(t.id, null, fields);
        assert.equal(
          (await repo.detail(t.id, { standard: 'Class 2' })).total,
          1,
        );
        assert.equal(
          (await repo.detail(t.id, { standard: 'Nursery' })).total,
          0,
        );
        const fresh = await repo.get(t.id);
        await repo.update(t.id, { ...body(fresh), title: title + ' revised' });
        await repo.backfill();
        assert.equal(
          (
            await repo.list({
              resource,
              language: 'English',
              search: title + ' revised',
            })
          ).total,
          1,
        );
      }
    } finally {
      if (server) await new Promise((r) => server.close(r));
      await pool.end();
      const c = await createBootstrapConnection();
      await c.query(`DROP DATABASE IF EXISTS \`${process.env.DB_NAME}\``);
      await c.end();
    }
  },
);
