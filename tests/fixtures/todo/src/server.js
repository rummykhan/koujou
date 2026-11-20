import http from 'node:http';
import { createStore } from './store.js';

const MAX_BODY_BYTES = 16 * 1024;

function send(res, status, body) {
  res.writeHead(status, { 'content-type': 'application/json' });
  res.end(JSON.stringify(body));
}

function readJson(req) {
  return new Promise((resolve) => {
    const chunks = [];
    let size = 0;
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size <= MAX_BODY_BYTES) chunks.push(chunk);
    });
    req.on('end', () => {
      if (size > MAX_BODY_BYTES) return resolve(undefined);
      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString('utf8')));
      } catch {
        resolve(undefined);
      }
    });
    req.on('error', () => resolve(undefined));
  });
}

async function route(req, res, store) {
  const { pathname } = new URL(req.url, 'http://localhost');

  if (pathname === '/health') {
    if (req.method !== 'GET') return send(res, 405, { error: 'method_not_allowed' });
    return send(res, 200, { ok: true });
  }

  if (pathname === '/todos') {
    if (req.method === 'GET') return send(res, 200, { todos: store.list() });
    if (req.method !== 'POST') return send(res, 405, { error: 'method_not_allowed' });
    const body = await readJson(req);
    const title = body && typeof body.title === 'string' ? body.title.trim() : '';
    if (!title || title.length > 200) return send(res, 400, { error: 'invalid_title' });
    return send(res, 201, store.add(title));
  }

  send(res, 404, { error: 'not_found' });
}

// createServer(deps) returns an http.Server; the store is injected so tests can supply their own.
export function createServer({ store = createStore() } = {}) {
  return http.createServer((req, res) => {
    route(req, res, store).catch(() => send(res, 500, { error: 'internal' }));
  });
}
