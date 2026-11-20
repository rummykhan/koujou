import test from 'node:test';
import assert from 'node:assert/strict';
import { start } from './helpers.js';

test('GET /health answers ok', async () => {
  const app = await start();
  try {
    const res = await fetch(`${app.url}/health`);
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), { ok: true });
  } finally {
    await app.close();
  }
});

test('POST /todos creates a todo and GET /todos lists it', async () => {
  const app = await start();
  try {
    const created = await fetch(`${app.url}/todos`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ title: '  buy milk ' }),
    });
    assert.equal(created.status, 201);
    assert.deepEqual(await created.json(), { id: 1, title: 'buy milk', done: false });
    const listed = await (await fetch(`${app.url}/todos`)).json();
    assert.deepEqual(listed, { todos: [{ id: 1, title: 'buy milk', done: false }] });
  } finally {
    await app.close();
  }
});

test('POST /todos rejects a missing, empty or over-long title with 400 invalid_title', async () => {
  const app = await start();
  try {
    for (const body of ['{}', '{"title":""}', '{"title":"   "}', JSON.stringify({ title: 'x'.repeat(201) }), 'not json']) {
      const res = await fetch(`${app.url}/todos`, { method: 'POST', body });
      assert.equal(res.status, 400, body);
      assert.deepEqual(await res.json(), { error: 'invalid_title' });
    }
  } finally {
    await app.close();
  }
});

test('unknown paths answer 404 and wrong methods 405', async () => {
  const app = await start();
  try {
    assert.equal((await fetch(`${app.url}/nope`)).status, 404);
    assert.equal((await fetch(`${app.url}/todos`, { method: 'PUT' })).status, 405);
  } finally {
    await app.close();
  }
});
