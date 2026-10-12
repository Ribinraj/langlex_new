const test = require('node:test');
const assert = require('node:assert/strict');

test('admin activities, database choices, safe relations and learner access stay aligned', {skip: process.env.RUN_DB_TESTS !== '1'}, async () => {
  process.env.DB_NAME = `langlex_alignment_${process.pid}_${Date.now()}`;
  const database = process.env.DB_NAME;
  const {pool,createBootstrapConnection} = require('../src/infrastructure/database/db');
  const admin = require('../src/infrastructure/repositories/adminRepository');
  const catalog = require('../src/infrastructure/repositories/adminCatalogRepository');
  const progress = require('../src/application/learning/contentProgressService');
  const {signToken} = require('../src/shared/utils/jwt');
  let server, checks = 0;
  async function insert(table, values) {
    const [columns] = await pool.query(`SHOW COLUMNS FROM \`${table}\``);
    const row = Object.fromEntries(columns.filter(c=>!c.Extra.includes('auto_increment') && c.Default == null && c.Null === 'NO').map(c=>[c.Field,'']));
    Object.assign(row,values);
    const [result] = await pool.query(`INSERT INTO \`${table}\` (${Object.keys(row).map(k=>`\`${k}\``).join(',')}) VALUES (${Object.keys(row).map(()=>'?').join(',')})`,Object.values(row));
    return result.insertId;
  }
  try {
    await require('../src/infrastructure/database/initDatabase')();
    server = require('../src/app').listen(0,'127.0.0.1');
    await new Promise(resolve=>server.once('listening',resolve));
    const base = `http://127.0.0.1:${server.address().port}/api`;
    const env = require('../src/infrastructure/config/env');
    const login = await fetch(base+'/admin/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(env.admin)});
    const adminToken = (await login.json()).token;
    assert.ok(adminToken);
    async function request(path, {token=adminToken,method='GET',body,status=200}={}) {
      const response = await fetch(base+path,{method,headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},...(body?{body:JSON.stringify(body)}:{})});
      const data = await response.json();
      assert.equal(response.status,status,`${method} ${path}: ${JSON.stringify(data)}`); checks++;
      return data;
    }
    const options = (await request('/admin/resource-form-options/quizzes?language=English')).options;
    const [levels] = await pool.query("SELECT DISTINCT difflvl FROM quizz WHERE Language='English' AND difflvl<>'' ORDER BY difflvl");
    assert.deepEqual(options.difflvl,levels.map(row=>row.difflvl));
    assert.ok(options.difflvl.includes('Nursery')); assert.ok(!options.difflvl.includes('easy'));
    await request('/admin/resources/quizzes',{method:'POST',body:{Question:'QA question',Language:'English',ca:'A',o1:'B',difflvl:'easy'},status:422});
    await request('/admin/resources/plans',{method:'POST',body:{name:'Unsupported permissions',amount:19,type:'premium',plan_timeperiod:'Monthly',permission:{courses:'all'}},status:422});
    const course = await admin.createResource('courses',{title:'QA access lesson',language:'English',show_plan:'Premium'});
    const word = await insert('Content',{course:course.title,language:'English',content:'secret word',category:'Nursery'});
    const otherLanguage = await insert('Content',{course:course.title,language:'Hindi',content:'other language'});
    await request(`/admin/resources/courses/${course.id}`,{method:'PUT',body:{title:'QA renamed lesson'}});
    const [[moved]] = await pool.query('SELECT course FROM Content WHERE id=?',[word]);
    assert.equal(moved.course,'QA renamed lesson');
    const [[unchanged]] = await pool.query('SELECT course FROM Content WHERE id=?',[otherLanguage]);
    assert.equal(unchanged.course,course.title);
    const members = await request(`/admin/catalog/courses/${course.id}/items`);
    assert.equal(members.total,1); assert.equal(members.items[0].id,word);
    await request(`/admin/resources/courses/${course.id}`,{method:'DELETE',status:409});
    await insert('Content',{course:'QA implicit lesson',language:'English',content:'keep separate'});
    await request(`/admin/resources/courses/${course.id}`,{method:'PUT',body:{title:'QA implicit lesson'},status:409});
    assert.equal((await admin.getResource('courses',course.id)).title,'QA renamed lesson');
    const references = await request('/admin/reference-options/content/course?language=Hindi&search=QA');
    assert.deepEqual(references.items,[course.title]);
    const passage = await insert('stories',{title:'QA story',language:'English',grade:'Nursery',show_plan:'Free',text:'First secret passage',audio:'secret-one.mp3'});
    await insert('stories',{title:'QA story',language:'English',grade:'Nursery',show_plan:'Premium',text:'Second secret passage',audio:'secret-two.mp3'});
    const groups = await request('/admin/catalog/stories?language=English&search=QA');
    assert.equal(groups.items[0].item_count,2); assert.equal(groups.items[0].show_plan,'Premium');
    await request(`/admin/catalog/stories/${passage}`,{method:'PUT',body:{title:'QA whole story',show_plan:'Premium'}});
    const updated = await request(`/admin/catalog/stories/${passage}/items`);
    assert.equal(updated.total,2); assert.ok(updated.items.every(row=>row.title==='QA whole story' && row.show_plan==='Premium'));
    const quiz = await insert('quizz',{Question:'QA select',topic:'QA topic',Language:'English',ca:'A',o1:'B'});
    await insert('quizz',{Question:'QA select again',topic:'QA topic',Language:'English',ca:'A',o1:'B'});
    await request(`/admin/catalog/quizzes/${quiz}`,{method:'PUT',body:{topic:'QA new topic'}});
    assert.equal((await request(`/admin/catalog/quizzes/${quiz}/items`)).total,2);
    const user = {id:await insert('users',{mobile_number:'1990000001',full_name:'Alignment learner'})};
    await insert('user_learning_setups',{user_id:user.id,primary_language:'English',learning_language:'English',level:'Nursery',selected_languages:JSON.stringify(['English','Hindi','Kannada'])});
    const learnerToken = signToken(user);
    await request('/content?course=QA%20renamed%20lesson&language=English',{token:'',status:401});
    await request('/content?course=QA%20renamed%20lesson',{token:learnerToken,status:403});
    await request('/content?course[]=broken',{token:'',status:400});
    const publicList = await request('/stories?language=English&search=QA',{token:''});
    assert.equal(publicList.stories[0].locked,true); assert.equal(publicList.stories[0].text,''); assert.equal(publicList.stories[0].audio,''); assert.deepEqual(publicList.stories[0].sections,[]);
    await request(`/stories/${passage}`,{token:learnerToken,status:403});
    await request('/user/learning-progress',{status:403}); // Admin credentials cannot impersonate a learner.
    const freeSnapshot = (await request(`/admin/users/${user.id}/learning-progress`)).progress;
    assert.deepEqual(freeSnapshot,(await request('/user/learning-progress',{token:learnerToken})).progress);
    const plan = await insert('subsc_plans',{name:'QA Premium',type:'premium',amount:'19',plan_timeperiod:'Monthly',permission:'[]'});
    await pool.query("INSERT INTO user_subscriptions(user_id,plan_id,status,started_at,expires_at) VALUES (?,?,'active',DATE_ADD(NOW(),INTERVAL 1 DAY),DATE_ADD(NOW(),INTERVAL 2 DAY))",[user.id,plan]);
    await request(`/stories/${passage}`,{token:learnerToken,status:403}); // Future subscription is not active yet.
    await pool.query('UPDATE user_subscriptions SET started_at=DATE_SUB(NOW(),INTERVAL 1 DAY) WHERE user_id=?',[user.id]);
    assert.equal((await request('/content?course=QA%20renamed%20lesson',{token:learnerToken})).content[0].id,word);
    const story = (await request(`/stories/${passage}`,{token:learnerToken})).story;
    assert.equal(story.locked,false); assert.equal(story.sections.length,2); assert.ok(story.text.includes('Second secret'));
    await progress.recordItemProgress(user,{content_type:'course',content_key:`course-${course.id}`,item_key:`content-${word}`});
    let earned = (await request(`/admin/users/${user.id}/learning-progress`)).progress;
    assert.equal(earned.topics.find(row=>row.content_key===`course-${course.id}`).completed_items,1);
    assert.ok(earned.total_items>freeSnapshot.total_items);
    await pool.query('UPDATE user_subscriptions SET expires_at=DATE_SUB(NOW(),INTERVAL 1 SECOND) WHERE user_id=?',[user.id]);
    earned = (await request(`/admin/users/${user.id}/learning-progress`)).progress;
    assert.equal(earned.total_items,freeSnapshot.total_items); assert.equal(earned.saved_locked_items,1);
    await request(`/stories/${passage}`,{token:learnerToken,status:403});
    await request(`/admin/resources/plans/${plan}`,{method:'DELETE',status:409});
    // A course inferred from words can be renamed and assigned access atomically.
    const implicitWord = await insert('Content',{course:'QA virtual course',language:'English',content:'Virtual word',category:'Nursery'});
    const materialized = await request(`/admin/catalog/courses/${1000000+implicitWord}`,{method:'PUT',body:{title:'QA saved virtual course',language:'English',show_plan:'Premium'}});
    assert.ok(materialized.id < 1000000);
    assert.equal((await request(`/admin/catalog/courses/${materialized.id}/items`)).items[0].id,implicitWord);
    await request(`/admin/catalog/courses/${materialized.id}`,{method:'PUT',body:{title:'qa saved virtual course'}});
    assert.equal((await admin.getResource('content',implicitWord)).course,'qa saved virtual course');
    // One setting controls the whole quiz, including later questions and legacy clients.
    const beforeQuizLock = (await request(`/admin/users/${user.id}/learning-progress`)).progress;
    await request(`/admin/catalog/quizzes/${quiz}`,{method:'PUT',body:{show_plan:'Premium'}});
    await require('../src/infrastructure/database/quizTopicSettings')(pool);
    const quizPreview = (await request('/quizzes?view=sets&search=QA',{token:learnerToken})).quizzes.find(row=>row.id===quiz);
    assert.equal(quizPreview.show_plan,'Premium'); assert.equal(quizPreview.locked,true); assert.equal(quizPreview.question_count,2);
    assert.equal('ca' in quizPreview,false);
    await request('/quizzes?topic=QA%20new%20topic',{token:learnerToken,status:403});
    await request('/quizzes?topic=QA%20new%20topic&language=English',{token:'',status:401});
    assert.equal((await request('/quizzes?search=QA',{token:learnerToken})).quizzes.length,0);
    const quizPayload={content_type:'quiz',content_key:`quiz-topic-${quiz}`,item_key:`quiz-${quiz}`,answer:'A'};
    await assert.rejects(progress.recordItemProgress(user,quizPayload),{statusCode:403});
    await assert.rejects(progress.recordItemProgress(user,{...quizPayload,content_key:'quiz-English'}),{statusCode:400});
    const lockedSnapshot = (await request(`/admin/users/${user.id}/learning-progress`)).progress;
    assert.equal(lockedSnapshot.total_items,beforeQuizLock.total_items-2);
    const extra = await admin.createResource('quizzes',{Question:'QA added later',topic:'QA new topic',Language:'English',ca:'A',o1:'B'});
    assert.equal((await request(`/admin/catalog/quizzes/${quiz}/items`)).group.show_plan,'Premium');
    await request(`/admin/catalog/quizzes/${quiz}`,{method:'PUT',body:{topic:'QA premium renamed'}});
    assert.equal((await request(`/admin/catalog/quizzes/${quiz}/items`)).total,3);
    await pool.query('UPDATE user_subscriptions SET expires_at=DATE_ADD(NOW(),INTERVAL 1 DAY) WHERE user_id=?',[user.id]);
    const questions = (await request('/quizzes?topic=QA%20premium%20renamed',{token:learnerToken})).quizzes;
    assert.equal(questions.length,3);assert.ok(questions.some(row=>row.id===extra.id));
    await progress.recordItemProgress(user,quizPayload);
    await pool.query('UPDATE user_subscriptions SET expires_at=DATE_SUB(NOW(),INTERVAL 1 SECOND) WHERE user_id=?',[user.id]);
    await request(`/admin/catalog/quizzes/${quiz}`,{method:'PUT',body:{show_plan:'Free'}});
    assert.equal((await request('/quizzes?topic=QA%20premium%20renamed',{token:learnerToken})).quizzes.length,3);
    const finalQuiz = (await request(`/admin/users/${user.id}/learning-progress`)).progress.topics.find(row=>row.content_key===`quiz-topic-${quiz}`);
    assert.equal(finalQuiz.completed_items,1); assert.equal(finalQuiz.accessible,true);
    await request(`/admin/catalog/quizzes/${quiz}`,{method:'PUT',body:{show_plan:'Login'},status:422});
    // Shared labels/media remain editable for sounds and letter examples too.
    const sound = await insert('Phonics',{word:'QA sound',coursename:'QA sound topic',language:'English'});
    const sound2 = await insert('Phonics',{word:'QA sound two',coursename:'QA sound topic',language:'English'});
    await request(`/admin/catalog/phonics/${sound}`,{method:'PUT',body:{coursename:'QA sound renamed',title_image:'/media/qa.png'}});
    const sounds = await request(`/admin/catalog/phonics/${sound}/items`);
    assert.equal(sounds.total,2);assert.ok(sounds.items.every(row=>row.title_image==='/media/qa.png' && row.coursename==='QA sound renamed'));
    assert.ok(sounds.items.some(row=>row.id===sound2));
    const letter = await insert('Alphabets',{letter:'QA',coursename:'QA letters',language:'English',ill_word:'Example one'});
    await insert('Alphabets',{letter:'QA',coursename:'QA letters',language:'English',ill_word:'Example two'});
    await request(`/admin/catalog/alphabets/${letter}`,{method:'PUT',body:{letter:'QB',coursename:'QA letters renamed'}});
    const letters = await request(`/admin/catalog/alphabets/${letter}/items`);
    assert.equal(letters.total,2);assert.ok(letters.items.every(row=>row.letter==='QB' && row.coursename==='QA letters renamed'));
    await request(`/admin/resources/quizzes/${quiz}`,{method:'PUT',body:{show_plan:'Premium'},status:422});
    console.log(`Alignment checks passed: ${checks} HTTP assertions in an isolated database.`);
  } finally {
    if(server) await new Promise(resolve=>server.close(resolve));
    await pool.end();
    const conn = await createBootstrapConnection();
    try {await conn.query(`DROP DATABASE IF EXISTS \`${database}\``);} finally {await conn.end();}
  }
});
