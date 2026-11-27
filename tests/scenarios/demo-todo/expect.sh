#!/bin/bash
# Outcome checks only: what is true of the repository and the tracker afterwards, not how the run got there.
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"; . "$(dirname "$0")/../../lib/todo.sh"
cd "$WORK/todo" || exit 2
q() { bd list "$@" --all --limit 0 --json --readonly; }
epic=$(q --type epic | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d[0]["id"] if len(d)==1 else "")')

echo "    plan"
check "exactly one epic was created" test -n "$epic"
wo=$(ls -d docs/factory/*/ 2>/dev/null | head -1)
check "requirements exist and are approved" grep -q '^status: approved' "${wo}requirements.md"
check "the plan was saved" test -f "${wo}plan.json"
check "the epic has at least two tasks" test "$(q --parent "$epic" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')" -ge 2
check "bd lint is clean" bd lint

echo "    delivery"
check "work is on main, past the starting commit" bash -c "test \"\$(git rev-parse --abbrev-ref HEAD)\" = main && ! test \"\$(git rev-parse HEAD)\" = \"$(cat "$WORK/base-sha")\""
check "the working tree is clean" test -z "$(git status --porcelain)"
check "the gate is green on main" npm run gate
check "every task and the epic are closed" bash -c "bd list --parent $epic --all --limit 0 --json --readonly | python3 -c 'import json,sys; sys.exit(any(i[\"status\"]!=\"closed\" for i in json.load(sys.stdin)))' && bd show $epic --json --readonly | python3 -c 'import json,sys; sys.exit(json.load(sys.stdin)[0][\"status\"]!=\"closed\")'"
check "every task has an acceptance command and all pass on main" koujou accept --parent "$epic"
check "nothing is stuck" test "$(q --label factory:stuck | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')" = 0
check "no task worktrees or task branches are left" bash -c "test \"\$(git worktree list | wc -l | tr -d ' ')\" = 1 && ! git branch --list 'factory-task/*' | grep -q ."

echo "    the product does what was asked"
check "mark done, mark not done, delete, filter, ids not reused" node --input-type=module -e "
import { createServer } from './src/server.js';
const s = createServer(); await new Promise(r => s.listen(0, '127.0.0.1', r)); const u = 'http://127.0.0.1:' + s.address().port;
const j = (m, p, b) => fetch(u + p, { method: m, headers: { 'content-type': 'application/json' }, body: b && JSON.stringify(b) });
const fail = (why) => { console.error(why); s.close(); process.exit(1); };
for (const t of ['a', 'b', 'c']) await j('POST', '/todos', { title: t });
if ((await (await j('PATCH', '/todos/2', { done: true })).json()).done !== true) fail('mark done');
let open = (await (await j('GET', '/todos?done=false')).json()).todos, done = (await (await j('GET', '/todos?done=true')).json()).todos;
if (open.length !== 2 || done.length !== 1 || done[0].id !== 2) fail('filter');
if ((await (await j('PATCH', '/todos/2', { done: false })).json()).done !== false) fail('mark not done');
const del = await j('DELETE', '/todos/1'); if (del.status < 200 || del.status > 204) fail('delete ' + del.status);
const left = (await (await j('GET', '/todos')).json()).todos.map(t => t.id); if (left.join() !== '2,3') fail('other ids disturbed: ' + left);
if ((await (await j('POST', '/todos', { title: 'd' })).json()).id !== 4) fail('id reused');
s.close();"

echo "    records"
check "report.md exists and names what shipped" grep -qi 'shipped\|outcome' "${wo}report.md"
check "no security review ran in the loop (it is on demand only)" bash -c "test ! -e '${wo}security.md'"
check "validation left evidence" bash -c "ls '${wo}evidence/' | grep -q ."
check "time was recorded: every task has merged_at" bash -c "for i in \$(bd list --parent $epic --all --limit 0 --json --readonly | python3 -c 'import json,sys; print(\" \".join(i[\"id\"] for i in json.load(sys.stdin)))'); do bd show \$i --json --readonly | python3 -c 'import json,sys; sys.exit(\"merged_at\" not in (json.load(sys.stdin)[0].get(\"metadata\") or {}))' || exit 1; done"
check "koujou times runs on the epic" koujou times "$epic"
check "the run stayed inside its budget of agents and time" koujou budget "$epic"
check "the System design in AGENTS.md mentions the new routes" bash -c "grep -q 'DELETE' AGENTS.md && grep -q 'PATCH' AGENTS.md"
check "a retro was written" test -f "${wo}retro.md"
check "the retro has a Speed table comparing the run with doing it by hand" bash -c "grep -q '^## Speed' '${wo}retro.md' && grep -qi 'by hand' '${wo}retro.md'"
finish
