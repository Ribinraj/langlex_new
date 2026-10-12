const test = require('node:test');
const assert = require('node:assert/strict');
const { summarize } = require('../src/application/learning/progressSummary');
const topic=(key,items,premium=false)=>({content_type:'course',content_key:key,title:key,language:'English',premium,items:items.map(id=>({id}))});
test('overall completion weights distinct available items, not topic percentages',()=>{
 const result=summarize([topic('small',[1]),topic('large',[2,3,4]),topic('shared',[1,1]),topic('locked',[5],true)], [{content_type:'course',item_id:1},{content_type:'course',item_id:5}], false);
 assert.equal(result.total_items,4);assert.equal(result.completed_items,1);assert.equal(result.percent,25);
 assert.equal(result.saved_locked_items,1);assert.equal(result.total_topics,3);
 assert.equal(result.topics.find(t=>t.content_key==='shared').total_items,1);
});
test('empty topics cannot produce completion and removed records cannot inflate progress',()=>{
 const result=summarize([topic('empty',[])],[{content_type:'course',item_id:123}],true);
 assert.equal(result.percent,0);assert.equal(result.total_topics,0);assert.equal(result.completed_items,0);assert.equal(result.topics[0].status,'empty');
});
test('latest practice date uses chronological order and quiz accuracy remains separate',()=>{
 const result=summarize([{...topic('quiz',[1,2]),content_type:'quiz'}],[
  {content_type:'quiz',item_id:1,best_correct:1,last_practiced_at:new Date('2026-09-01')},
  {content_type:'quiz',item_id:2,best_correct:0,last_practiced_at:new Date('2026-10-01')}
 ],false);
 assert.equal(result.percent,100);assert.equal(result.topics[0].correct_items,1);
 assert.equal(result.topics[0].last_practiced_at.toISOString(),'2026-10-01T00:00:00.000Z');
});
