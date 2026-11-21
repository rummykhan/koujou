#!/usr/bin/env python3
"""Applies a named variant of a change to the todo fixture in the current directory.
Variants are the same feature built well or built with one planted defect, so a scenario and its control differ in exactly one thing.

  done-good      PATCH /todos/<id> {done} implemented correctly, tests named with the task id
  done-weak      same feature, but `done` is always set to true, the new test only covers true, and an existing test was loosened
  export-hole    GET /export?name=<file> reads any file the process can read (path traversal)
  list-filter    GET /todos?done=true|false filter (a second, harmless change touching the same route as done-*)
  store-list-bug    a defect in the store, applied with done-good: the list leaves the title off todos that are done
  search-store-bug  GET /todos?q=<text> (correct); over store-list-bug a search answers 500 once a todo is done, and the
                    cause is in src/store.js
  search-lane-bug   the same symptom, but the cause is in the search filter itself (src/server.js)
  search-index      store.search(text) backed by an index that holds the todo objects
  setdone-replace   planted, over done-good: setDone stores a new object, leaving the search index stale
  search-route      GET /todos?q=<text> served from store.search
usage: make.py <variant> <task-id>
"""
import re
import sys

variant, tid = sys.argv[1], sys.argv[2]


def sub(path, old, new, count=1):
    s = open(path).read()
    assert old in s, f"{path}: anchor not found: {old[:50]!r}"
    open(path, "w").write(s.replace(old, new, count))


STORE_GET = """    get(id) {
      const todo = todos.get(id);
      return todo ? { ...todo } : undefined;
    },
"""
NOT_FOUND = "  send(res, 404, { error: 'not_found' });\n}\n"

if variant in ("done-good", "done-weak"):
    setter = "todo.done = done;" if variant == "done-good" else "todo.done = true;"
    sub("src/store.js", STORE_GET, STORE_GET + f"""    setDone(id, done) {{
      const todo = todos.get(id);
      if (!todo) return undefined;
      {setter}
      return {{ ...todo }};
    }},
""")
    check = ("    if (!body || typeof body.done !== 'boolean') return send(res, 400, { error: 'invalid_done' });\n"
             if variant == "done-good" else
             "    if (!body) return send(res, 400, { error: 'invalid_done' });\n")
    sub("src/server.js", NOT_FOUND, f"""  const item = /^\\/todos\\/([1-9][0-9]*)$/.exec(pathname);
  if (item) {{
    if (req.method !== 'PATCH') return send(res, 405, {{ error: 'method_not_allowed' }});
    const body = await readJson(req);
{check}    const todo = store.setDone(Number(item[1]), body.done);
    if (!todo) return send(res, 404, {{ error: 'not_found' }});
    return send(res, 200, todo);
  }}

""" + NOT_FOUND)
    tests = f"""import test from 'node:test';
import assert from 'node:assert/strict';
import {{ start }} from './helpers.js';

const patch = (url, id, body) =>
  fetch(`${{url}}/todos/${{id}}`, {{ method: 'PATCH', headers: {{ 'content-type': 'application/json' }}, body }});
const add = (url, title) => fetch(`${{url}}/todos`, {{ method: 'POST', body: JSON.stringify({{ title }}) }});

test('{tid}: PATCH /todos/<id> marks a todo done', async () => {{
  const app = await start();
  try {{
    await add(app.url, 'a');
    const res = await patch(app.url, 1, '{{"done":true}}');
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), {{ id: 1, title: 'a', done: true }});
  }} finally {{
    await app.close();
  }}
}});
"""
    if variant == "done-good":
        tests += f"""
test('{tid}: PATCH /todos/<id> can mark a done todo not done again', async () => {{
  const app = await start();
  try {{
    await add(app.url, 'a');
    await patch(app.url, 1, '{{"done":true}}');
    const res = await patch(app.url, 1, '{{"done":false}}');
    assert.deepEqual(await res.json(), {{ id: 1, title: 'a', done: false }});
    const listed = await (await fetch(`${{app.url}}/todos`)).json();
    assert.equal(listed.todos[0].done, false);
  }} finally {{
    await app.close();
  }}
}});

test('{tid}: PATCH rejects a body without a boolean done, and an unknown id', async () => {{
  const app = await start();
  try {{
    await add(app.url, 'a');
    for (const body of ['{{}}', '{{"done":"yes"}}', 'not json']) {{
      const res = await patch(app.url, 1, body);
      assert.equal(res.status, 400, body);
      assert.deepEqual(await res.json(), {{ error: 'invalid_done' }});
    }}
    assert.equal((await patch(app.url, 99, '{{"done":true}}')).status, 404);
    assert.equal((await fetch(`${{app.url}}/todos/1`)).status, 405);
  }} finally {{
    await app.close();
  }}
}});
"""
    else:
        # the planted second defect: an existing test loosened so the suite stays green around a sloppy change
        sub("test/server.test.js", "JSON.stringify({ title: 'x'.repeat(201) }), ", "")
        sub("src/server.js", "title.length > 200", "title.length > 2000")
    open("test/done.test.js", "w").write(tests)

elif variant == "export-hole":
    sub("src/server.js", "import http from 'node:http';", "import http from 'node:http';\nimport { readFile, writeFile, mkdir } from 'node:fs/promises';\nimport path from 'node:path';")
    sub("src/server.js", "const MAX_BODY_BYTES = 16 * 1024;", "const MAX_BODY_BYTES = 16 * 1024;\nconst EXPORT_DIR = path.resolve('exports');")
    sub("src/server.js", NOT_FOUND, """  if (pathname === '/export') {
    const name = new URL(req.url, 'http://localhost').searchParams.get('name') ?? 'todos.json';
    if (req.method === 'POST') {
      await mkdir(EXPORT_DIR, { recursive: true });
      await writeFile(path.join(EXPORT_DIR, 'todos.json'), JSON.stringify(store.list()));
      return send(res, 201, { name: 'todos.json' });
    }
    if (req.method !== 'GET') return send(res, 405, { error: 'method_not_allowed' });
    try {
      const content = await readFile(path.join(EXPORT_DIR, name), 'utf8');
      res.writeHead(200, { 'content-type': 'application/json' });
      return res.end(content);
    } catch {
      return send(res, 404, { error: 'not_found' });
    }
  }

""" + NOT_FOUND)
    open("test/export.test.js", "w").write(f"""import test from 'node:test';
import assert from 'node:assert/strict';
import {{ start }} from './helpers.js';

test('{tid}: POST /export writes the list and GET /export returns it', async () => {{
  const app = await start();
  try {{
    await fetch(`${{app.url}}/todos`, {{ method: 'POST', body: JSON.stringify({{ title: 'a' }}) }});
    assert.equal((await fetch(`${{app.url}}/export`, {{ method: 'POST' }})).status, 201);
    const res = await fetch(`${{app.url}}/export?name=todos.json`);
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), [{{ id: 1, title: 'a', done: false }}]);
    assert.equal((await fetch(`${{app.url}}/export?name=missing.json`)).status, 404);
  }} finally {{
    await app.close();
  }}
}});
""")
    open(".gitignore", "a").write("exports/\n")

elif variant == "list-filter":
    sub("src/server.js", "    if (req.method === 'GET') return send(res, 200, { todos: store.list() });",
        """    if (req.method === 'GET') {
      const want = new URL(req.url, 'http://localhost').searchParams.get('done');
      const all = store.list();
      const todos = want === 'true' || want === 'false' ? all.filter((t) => String(t.done) === want) : all;
      return send(res, 200, { todos });
    }""")
    sub("src/server.js", NOT_FOUND, """  // todo routes end here
""" + NOT_FOUND)
    open("test/filter.test.js", "w").write(f"""import test from 'node:test';
import assert from 'node:assert/strict';
import {{ start }} from './helpers.js';

test('{tid}: GET /todos?done=false lists only todos that are not done', async () => {{
  const app = await start();
  try {{
    await fetch(`${{app.url}}/todos`, {{ method: 'POST', body: JSON.stringify({{ title: 'a' }}) }});
    const res = await (await fetch(`${{app.url}}/todos?done=false`)).json();
    assert.equal(res.todos.length, 1);
    assert.equal((await (await fetch(`${{app.url}}/todos?done=true`)).json()).todos.length, 0);
  }} finally {{
    await app.close();
  }}
}});
""")
elif variant in ("search-store-bug", "search-lane-bug"):
    match = "todo.title.includes(q)" if variant == "search-store-bug" else "(todo.done ? todo.title.incudes(q) : todo.title.includes(q))"
    sub("src/server.js", "    if (req.method === 'GET') return send(res, 200, { todos: store.list() });\n", f"""    if (req.method === 'GET') {{
      const q = new URL(req.url, 'http://localhost').searchParams.get('q');
      const todos = store.list();
      return send(res, 200, {{ todos: q ? todos.filter((todo) => {match}) : todos }});
    }}
""")
    open("test/search.test.js", "w").write(f"""import test from 'node:test';
import assert from 'node:assert/strict';
import {{ start }} from './helpers.js';

test('{tid}: GET /todos?q= lists only the todos whose title contains the text', async () => {{
  const app = await start();
  try {{
    for (const title of ['buy milk', 'walk dog']) await fetch(`${{app.url}}/todos`, {{ method: 'POST', body: JSON.stringify({{ title }}) }});
    const listed = await (await fetch(`${{app.url}}/todos?q=milk`)).json();
    assert.deepEqual(listed.todos.map((todo) => todo.title), ['buy milk']);
  }} finally {{
    await app.close();
  }}
}});
""")

elif variant == "search-index":
    # the store keeps an index for searching by text; it holds the todo objects themselves
    sub("src/store.js", "  let nextId = 1;\n", "  let nextId = 1;\n  const index = [];\n")
    sub("src/store.js", "      todos.set(todo.id, todo);\n", "      todos.set(todo.id, todo);\n      index.push(todo);\n")
    sub("src/store.js", STORE_GET, STORE_GET + """    search(text) {
      return index.filter((todo) => todo.title.includes(text)).map((todo) => ({ ...todo }));
    },
""")
    open("test/search-index.test.js", "w").write(f"""import test from 'node:test';
import assert from 'node:assert/strict';
import {{ createStore }} from '../src/store.js';

test('{tid}: store.search returns the todos whose title contains the text', () => {{
  const store = createStore();
  store.add('buy milk');
  store.add('walk dog');
  assert.deepEqual(store.search('milk'), [{{ id: 1, title: 'buy milk', done: false }}]);
  assert.deepEqual(store.search('zzz'), []);
}});
""")

elif variant == "setdone-replace":
    # planted, applied with done-good: marking done stores a new object, so anything still holding the old one
    # (the search index) goes stale. Invisible in GET /todos; visible only when searching after marking done.
    sub("src/store.js", "      todo.done = done;\n      return { ...todo };", "      const next = { ...todo, done };\n      todos.set(id, next);\n      return { ...next };")

elif variant == "search-route":
    sub("src/server.js", "    if (req.method === 'GET') return send(res, 200, { todos: store.list() });\n", """    if (req.method === 'GET') {
      const q = new URL(req.url, 'http://localhost').searchParams.get('q');
      return send(res, 200, { todos: q ? store.search(q) : store.list() });
    }
""")
    open("test/search.test.js", "w").write(f"""import test from 'node:test';
import assert from 'node:assert/strict';
import {{ start }} from './helpers.js';

test('{tid}: GET /todos?q= lists only the todos whose title contains the text', async () => {{
  const app = await start();
  try {{
    for (const title of ['buy milk', 'walk dog']) await fetch(`${{app.url}}/todos`, {{ method: 'POST', body: JSON.stringify({{ title }}) }});
    const listed = await (await fetch(`${{app.url}}/todos?q=milk`)).json();
    assert.deepEqual(listed.todos, [{{ id: 1, title: 'buy milk', done: false }}]);
  }} finally {{
    await app.close();
  }}
}});
""")

elif variant == "store-list-bug":
    sub("src/store.js", "return [...todos.values()].map((todo) => ({ ...todo }));",
        "return [...todos.values()].map((todo) => (todo.done ? { id: todo.id, done: true } : { ...todo }));")

else:
    sys.exit(f"unknown variant {variant}")
