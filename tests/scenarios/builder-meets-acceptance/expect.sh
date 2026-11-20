#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"; . "$(dirname "$0")/../../lib/todo.sh"
id=$(cat "$WORK/task"); wt="$WORK/wt"
report_has "builder reports done" '^status:[[:space:]]*done'
check "work is committed on the task branch" test -n "$(git -C "$wt" log --oneline factory/epic..factory-task/$id)"
check "worktree is clean (nothing left uncommitted)" test -z "$(git -C "$wt" status --porcelain)"
check "acceptance command passes on tests named with the task id" bash -c "cd '$wt' && '$TESTS_DIR/../bin/koujou' accept $id"
check "gate is green" bash -c "cd '$wt' && npm run gate"
check "only lane files changed" bash -c "! git -C '$wt' diff --name-only factory/epic...factory-task/$id | grep -Ev '^(src/store\.js|src/server\.js|test/delete\.test\.js)$'"
check "existing tests were not edited" test -z "$(git -C "$wt" diff --name-only factory/epic...factory-task/$id -- test/server.test.js test/store.test.js test/helpers.js)"
check "the behaviour is real: DELETE answers 204 then 404" bash -c "cd '$wt' && node --input-type=module -e \"
import { createServer } from './src/server.js';
const s = createServer(); await new Promise(r => s.listen(0, '127.0.0.1', r)); const u = 'http://127.0.0.1:' + s.address().port;
await fetch(u + '/todos', { method: 'POST', body: JSON.stringify({ title: 'a' }) });
const a = (await fetch(u + '/todos/1', { method: 'DELETE' })).status, b = (await fetch(u + '/todos/1', { method: 'DELETE' })).status;
const n = (await (await fetch(u + '/todos')).json()).todos.length; s.close(); process.exit(a === 204 && b === 404 && n === 0 ? 0 : 1);\""
check "builder wrote no bead state (task still in progress)" test "$(cd "$WORK/todo" && bd show "$id" --json --readonly | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["status"])')" = in_progress
check "builder did not merge into the epic branch" test "$(git -C "$WORK/todo" rev-parse factory/epic)" = "$(git -C "$WORK/todo" rev-parse main)"
finish
