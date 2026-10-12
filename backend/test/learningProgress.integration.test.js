const test = require('node:test');
const assert = require('node:assert/strict');

test('earned progress is user-scoped, authoritative, replay-safe and entitlement-aware', { skip: process.env.RUN_DB_TESTS !== '1' }, async () => {
  process.env.DB_NAME = `langlex_progress_test_${process.pid}_${Date.now()}`;
  const database = process.env.DB_NAME;
  const initialize = require('../src/infrastructure/database/initDatabase');
  const { pool, createBootstrapConnection } = require('../src/infrastructure/database/db');
  const service = require('../src/application/learning/contentProgressService');
  async function insert(table, values) {
    const [columns] = await pool.query(`SHOW COLUMNS FROM \`${table}\``);
    const fields = columns.filter((c) => !c.Extra.includes('auto_increment') && c.Default == null && c.Null === 'NO').map((c) => c.Field);
    const row = Object.fromEntries(fields.map((f) => [f, values[f] ?? '']));
    Object.assign(row, values);
    const [result] = await pool.query(`INSERT INTO \`${table}\` (${Object.keys(row).map((k) => `\`${k}\``).join(',')}) VALUES (${Object.keys(row).map(() => '?').join(',')})`, Object.values(row));
    return result.insertId;
  }
  let server;
  try {
    await initialize();
    await require('../src/infrastructure/database/learningProgress')(pool); // repeatable migration
    const user = { id: await insert('users',{mobile_number:'1230000001',full_name:'Progress test'}) };
    const other = { id: await insert('users',{mobile_number:'1230000002',full_name:'Other test'}) };
    for (const u of [user,other]) await pool.execute("INSERT INTO user_learning_setups(user_id,primary_language,learning_language,level,selected_languages) VALUES (?,'Test','Test','Nursery',?)", [u.id, JSON.stringify(['Test','English','Hindi'])]);
    const free = await insert('courses',{title:'Free topic',language:'Test',show_plan:'login'});
    const paid = await insert('courses',{title:'Paid topic',language:'Test',show_plan:'premium'});
    const words = [];
    for (let i=0;i<3;i++) words.push(await insert('Content',{content:`Word ${i}`,course:'Free topic',language:'Test',category:'Nursery'}));
    const premiumWord = await insert('Content',{content:'Premium word',course:'Paid topic',language:'Test',category:'Nursery'});
    const q = await insert('quizz',{Question:'Choose',ca:'right',o1:'wrong',topic:'Test quiz',Language:'Test'});
    const payload = (id) => ({content_type:'course',content_key:`course-${free}`,item_key:`content-${id}`,total_items:1,status:'completed',position:999});
    let snapshot = await service.overview(user);
    assert.equal(snapshot.total_items,4);
    assert.equal(snapshot.locked_topics,1);
    assert.equal(snapshot.percent,0);
    let record = await service.recordItemProgress(user,{...payload(words[2]),event_id:'last-card-first'});
    assert.equal(record.status,'in_progress');
    assert.equal(record.total_items,3);
    assert.equal(record.position,2);
    await service.recordItemProgress(user,{...payload(words[2]),event_id:'last-card-first'});
    assert.equal((await service.overview(user)).completed_items,1);
    assert.equal((await service.overview(other)).completed_items,0);
    await assert.rejects(service.recordItemProgress(user,payload(premiumWord)), { statusCode:400 });
    await Promise.all(words.slice(0,2).map((id) => service.recordItemProgress(user,payload(id))));
    record = await service.getProgress(user,payload(words[0]));
    assert.equal(record.status,'completed');
    const restarted = await service.restartSession(user,{...payload(words[0]),event_id:'restart-once'});
    assert.equal(restarted.completed_item_keys.length,0);
    assert.equal((await service.overview(user)).completed_items,3);
    await service.recordItemProgress(user,{...payload(words[0]),session_id:restarted.metadata.session_id});
    await service.restartSession(user,{...payload(words[0]),event_id:'restart-once'});
    assert.equal((await service.getProgress(user,payload(words[0]))).completed_item_keys.length,1);
    await service.recordItemProgress(user,{...payload(words[1]),session_id:'legacy'});
    assert.equal((await service.getProgress(user,payload(words[0]))).completed_item_keys.length,1, 'stale sessions may earn work but cannot change the restarted session');
    const quiz = {content_type:'quiz',content_key:`quiz-topic-${q}`,item_key:`quiz-${q}`,answer:'wrong',is_correct:true};
    assert.equal((await service.recordItemProgress(user,{...quiz,answer:undefined})).score,0);
    await assert.rejects(service.recordItemProgress(user,{...quiz,answer:undefined,event_id:'new-missing-answer'}),{statusCode:400});
    assert.equal((await service.recordItemProgress(user,quiz)).score,0);
    assert.equal((await service.recordItemProgress(user,{...quiz,answer:'right'})).score,1);
    const locked = {content_type:'course',content_key:`course-${paid}`,item_key:`content-${premiumWord}`};
    await assert.rejects(service.recordItemProgress(user,locked), {statusCode:403});
    const planId = await insert('subsc_plans',{name:'Premium',type:'premium',amount:'100',permission:'[]',plan_timeperiod:'Monthly'});
    await pool.execute("INSERT INTO user_subscriptions(user_id,plan_id,status,started_at,expires_at) VALUES (?,?,'active',NOW(),DATE_ADD(NOW(), INTERVAL 1 DAY))",[user.id,planId]);
    snapshot = await service.overview(user);
    assert.equal(snapshot.total_items,5);
    assert.equal(snapshot.completed_items,4);
    assert.equal(snapshot.percent,80);
    await service.recordItemProgress(user,locked);
    assert.equal((await service.overview(user)).percent,100);
    await pool.execute('UPDATE user_subscriptions SET expires_at=DATE_SUB(NOW(),INTERVAL 1 DAY) WHERE user_id=?',[user.id]);
    snapshot = await service.overview(user);
    assert.equal(snapshot.total_items,4);
    assert.equal(snapshot.completed_items,4);
    assert.equal(snapshot.saved_locked_items,1);
    assert.equal(snapshot.topics.find((t)=>t.content_key===`course-${paid}`).completed_items,1);
    await insert('Content',{content:'New word',course:'Free topic',language:'Test',category:'Nursery'});
    snapshot = await service.overview(user);
    assert.equal(snapshot.total_items,5);
    assert.equal(snapshot.completed_items,4);
    assert.equal(snapshot.topics.find((t)=>t.content_key===`course-${free}`).status,'in_progress');
    await pool.execute('DELETE FROM Content WHERE id=?',[words[0]]);
    snapshot = await service.overview(user);
    assert.equal(snapshot.completed_items,3);
    assert.equal(snapshot.total_items,4);
    await assert.rejects(service.overview(user,{language:'Unselected'}), {statusCode:403});
    await pool.execute("UPDATE user_learning_setups SET level='Class 2' WHERE user_id=?",[user.id]);
    assert.equal((await service.overview(user)).total_items,1); // Unmapped legacy questions with no standard remain compatible.
    // Renewal restores earned premium items without replaying them.
    await pool.execute("UPDATE user_learning_setups SET level='Nursery' WHERE user_id=?",[user.id]);
    await pool.execute('UPDATE user_subscriptions SET expires_at=DATE_ADD(NOW(),INTERVAL 1 DAY) WHERE user_id=?',[user.id]);
    assert.equal((await service.overview(user)).topics.find(t=>t.content_key===`course-${paid}`).completed_items,1);
    // Explicit alphabet practice records exactly the examples shown, including a filtered search.
    const a = await insert('Alphabets',{letter:'A',coursename:'Letters',language:'Test',ill_word:'Apple'});
    const a2 = await insert('Alphabets',{letter:'A',coursename:'Letters',language:'Test',ill_word:'Ant'});
    const letter = {content_type:'alphabet',content_key:`alphabet-${a}`};
    await service.recordItemProgress(user,{...letter,item_key:`alphabet-${a2}`});
    let letters = (await service.overview(user)).topics.find(t=>t.content_key===letter.content_key);
    assert.equal(letters.completed_items,1);assert.equal(letters.total_items,2);
    const filtered = await require('../src/infrastructure/repositories/catalogRepository').list('alphabets',{language:'Test',search:'Ant',view:'letters'});
    assert.equal(filtered.items[0].progress_key,letter.content_key);
    assert.equal(filtered.items[0].examples.length,1);
    await service.recordItemProgress(user,{...letter,item_key:`alphabet-${a}`});
    assert.equal((await service.getProgress(user,letter)).status,'completed');
    // Story completion means the complete group, and replay never erases earned passages.
    const story = await insert('stories',{title:'Complete story',language:'Test',grade:'Nursery',text:'Part one'});
    await insert('stories',{title:'Complete story',language:'Test',grade:'Nursery',text:'Part two'});
    const storyPayload = {content_type:'story',content_key:`story-${story}`,status:'completed'};
    await service.saveProgress(user,{...storyPayload,status:'in_progress'});
    assert.equal((await service.overview(user)).topics.find(t=>t.content_key===storyPayload.content_key).completed_items,0);
    await service.saveProgress(user,storyPayload);
    await service.restartSession(user,storyPayload);
    assert.equal((await service.overview(user)).topics.find(t=>t.content_key===storyPayload.content_key).completed_items,2);
    // Migration preserves verified legacy items and stories but does not infer all
    // words from the old completed flag (which used to mean the last card).
    await pool.execute("INSERT INTO user_content_progress_items(user_id,content_type,content_key,item_key,position) VALUES (?,'course',?,?,0)",[other.id,`course-${free}`,`content-${words[1]}`]);
    await pool.execute("INSERT INTO user_content_progress(user_id,content_type,content_key,status,total_items,completed_at) VALUES (?,'course',?,'completed',999,NOW()),(?,'story',?,'completed',2,NOW())",[other.id,`course-${free}`,other.id,storyPayload.content_key]);
    await pool.query("DELETE FROM learning_progress_migrations WHERE version='earned-items-v1'");
    await require('../src/infrastructure/database/learningProgress')(pool);
    await require('../src/infrastructure/database/learningProgress')(pool);
    const migrated = await service.overview(other);
    assert.equal(migrated.topics.find(t=>t.content_key===`course-${free}`).completed_items,1);
    assert.equal(migrated.topics.find(t=>t.content_key===storyPayload.content_key).completed_items,2);
    // An empty selected language is 0/0, never 100%, and cannot borrow another language's work.
    await pool.execute("UPDATE user_learning_setups SET selected_languages=?,learning_language='Empty' WHERE user_id=?",[JSON.stringify(['Empty','Test']),other.id]);
    const empty = await service.overview(other);
    assert.equal(empty.total_items,0);assert.equal(empty.completed_items,0);assert.equal(empty.percent,0);
    // HTTP authentication, validation and full JSON response shape.
    const app = require('../src/app');
    server = app.listen(0,'127.0.0.1');
    await new Promise(resolve=>server.once('listening',resolve));
    const base = `http://127.0.0.1:${server.address().port}/api/user/`;
    assert.equal((await fetch(base+'learning-progress')).status,401);
    const headers = {Authorization:`Bearer ${require('../src/shared/utils/jwt').signToken(user)}`,'Content-Type':'application/json'};
    let http = await fetch(base+'learning-progress?language=Test',{headers});
    assert.equal(http.status,200);assert.ok(Array.isArray((await http.json()).progress.topics));
    assert.equal((await fetch(base+'learning-progress?language=Unselected',{headers})).status,403);
    assert.equal((await fetch(base+'learning-progress?language[]=Test',{headers})).status,422);
    http = await fetch(base+'content-progress/item',{method:'POST',headers,body:JSON.stringify({...letter,item_key:`alphabet-${a}`,event_id:'http-letter-event',session_id:'legacy'})});
    assert.equal(http.status,200);
    assert.equal((await http.json()).progress.status,'completed');

  } finally {
    if (server) await new Promise(resolve=>server.close(resolve));
    await pool.end();
    const connection=await createBootstrapConnection();
    await connection.query(`DROP DATABASE IF EXISTS \`${database}\``);
    await connection.end();
  }
});
