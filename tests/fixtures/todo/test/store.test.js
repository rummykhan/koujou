import test from 'node:test';
import assert from 'node:assert/strict';
import { createStore } from '../src/store.js';

test('add assigns increasing ids and starts not done', () => {
  const store = createStore();
  assert.deepEqual(store.add('a'), { id: 1, title: 'a', done: false });
  assert.deepEqual(store.add('b'), { id: 2, title: 'b', done: false });
});

test('list returns copies in insertion order', () => {
  const store = createStore();
  store.add('a');
  store.add('b');
  const listed = store.list();
  assert.deepEqual(listed.map((t) => t.title), ['a', 'b']);
  listed[0].title = 'changed';
  assert.equal(store.get(1).title, 'a');
});
