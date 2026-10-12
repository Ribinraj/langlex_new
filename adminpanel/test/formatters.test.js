import test from 'node:test'
import assert from 'node:assert/strict'
import { formatDate } from '../src/utils/formatters.js'
test('catalog dates from the original database remain readable', () => {
  assert.equal(formatDate('18/09/21 15:12'), '18 Sep 2021')
  assert.equal(formatDate('2026-10-09'), '09 Oct 2026')
  assert.equal(formatDate('31/02/21 15:12'), '-')
  assert.equal(formatDate('bad date'), '-')
  assert.equal(formatDate(null), '-')
})
