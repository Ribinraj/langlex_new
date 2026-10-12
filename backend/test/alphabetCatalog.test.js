const test = require('node:test');
const assert = require('node:assert/strict');
const { groupLetters, sequences } = require('../src/infrastructure/repositories/alphabetCatalog');

test('letter groups preserve every original example without repeating letter tiles', () => {
  const rows = [
    { id: 1, group_id: 1, example_count: 2, letter: 'A', ill_word: 'Apple' },
    { id: 2, group_id: 1, example_count: 2, letter: 'A', ill_word: 'Ant' },
    { id: 3, group_id: 3, example_count: 1, letter: 'B', ill_word: 'Ball' },
  ];
  const groups = groupLetters(rows);
  assert.deepEqual(groups.map((row) => row.letter), ['A', 'B']);
  assert.deepEqual(groups[0].examples.map((row) => row.ill_word), ['Apple', 'Ant']);
  assert.equal(groups[0].example_count, 2);
});
test('alphabet teaching sequences are unique and preserve varga order', () => {
  assert.equal(sequences.english.replaceAll(' ', ''), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
  for (const sequence of Object.values(sequences)) {
    const letters = sequence.split(' ');
    assert.equal(new Set(letters).size, letters.length);
  }
  assert.ok(sequences.hindi.indexOf('ट') < sequences.hindi.indexOf('त'));
  assert.ok(sequences.kannada.indexOf('ಟ') < sequences.kannada.indexOf('ತ'));
});
