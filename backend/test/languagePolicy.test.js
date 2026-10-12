const { test } = require('node:test');
const assert = require('node:assert/strict');
const { resolveLanguages } = require('../src/application/learning/languagePolicy');
const supported = ['English', 'Hindi', 'Kannada', 'Maithili', 'Assamese'];
const chosen = ['English', 'Hindi', 'Kannada'];
test('exactly three distinct supported languages are required', () => {
  for (const selected_languages of [[], ['Hindi'], ['Hindi','Hindi','English'], ['English','Hindi','Other'], supported]) {
    assert.throws(() => resolveLanguages(null, {selected_languages}, supported));
  }
});
test('first selection unifies interface and content languages', () => {
  const result = resolveLanguages(null, {selected_languages: chosen, active_language: 'Hindi'}, supported);
  assert.equal(result.active_language, 'Hindi');
  assert.equal(result.primary_language, 'Hindi');
  assert.equal(result.learning_language, 'Hindi');
});
test('saved choices are immutable, including when omitted by legacy clients', () => {
  const existing = {selected_languages: chosen, learning_language: 'English'};
  assert.throws(() => resolveLanguages(existing, {selected_languages: ['English','Hindi','Assamese']}, supported), /cannot be replaced/);
  assert.throws(() => resolveLanguages(existing, {learning_language: 'Assamese'}, supported), /one of your three/);
  const changed = resolveLanguages(existing, {active_language: 'Kannada'}, supported);
  assert.deepEqual(changed.selected_languages, chosen);
  assert.equal(changed.primary_language, 'Kannada');
  assert.equal(changed.learning_language, 'Kannada');
});
