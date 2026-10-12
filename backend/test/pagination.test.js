const test = require('node:test');
const assert = require('node:assert/strict');
const { pagination, pageResult, textFilter } = require('../src/shared/utils/pagination');
test('pagination has bounded defaults and rejects malformed or excessive requests', () => {
  assert.deepEqual(pagination(), { page: 1, limit: 20, offset: 0 });
  assert.deepEqual(pagination({ page: '3', limit: '25' }), { page: 3, limit: 25, offset: 50 });
  for (const query of [{ page: 0 }, { limit: 101 }, { page: '1.5' }, { page: ['1'] }, { page: '1;DROP' }, { page: 'Infinity' }, { limit: -1 }]) {
    assert.throws(() => pagination(query), (error) => error.statusCode === 400);
  }
  assert.throws(() => textFilter(['Hindi'], 'language'), (error) => error.statusCode === 400);
});
test('last, empty and out-of-range page metadata stays accurate', () => {
  assert.deepEqual(pageResult([], 41, { page: 3, limit: 20 }).pagination, { page: 3, limit: 20, total: 41, total_pages: 3, has_more: false });
  assert.equal(pageResult([], 0, { page: 1, limit: 20 }).pagination.total_pages, 0);
  assert.equal(pageResult([], 41, { page: 100, limit: 20 }).pagination.has_more, false);
});
