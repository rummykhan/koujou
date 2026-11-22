#!/bin/bash
# Outcome checks only: what is true of the repository and the tracker afterwards.
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"; . "$(dirname "$0")/../../lib/todo.sh"
cd "$WORK/todo" || exit 2
epic=$(cat "$WORK/epic")
bd list --parent "$epic" --all --limit 0 --json --readonly | python3 -c 'import json,sys; print(" ".join(i["id"] for i in json.load(sys.stdin) if i.get("issue_type")=="bug"))' > "$WORK/bugs"
shown() { bd show $(cat "$WORK/bugs") --json --readonly; }

echo "    the product"
check "still on the epic branch, past the starting commit, nothing merged to main" bash -c "test \"\$(git rev-parse --abbrev-ref HEAD)\" = factory/$epic && ! test \"\$(git rev-parse HEAD)\" = \"$(cat "$WORK/base-sha")\" && git merge-base --is-ancestor main $(cat "$WORK/base-sha")"
check "the gate is green" npm run gate
check "the bug is gone: a search after marking done shows done true, and false again after unmarking" node --input-type=module -e "
import { createServer } from './src/server.js';
const s = createServer(); await new Promise(r => s.listen(0, '127.0.0.1', r)); const u = 'http://127.0.0.1:' + s.address().port;
const j = (m, p, b) => fetch(u + p, { method: m, body: b && JSON.stringify(b) });
await j('POST', '/todos', { title: 'buy milk' }); await j('POST', '/todos', { title: 'walk dog' });
await j('PATCH', '/todos/1', { done: true });
const a = (await (await j('GET', '/todos?q=milk')).json()).todos;
await j('PATCH', '/todos/1', { done: false });
const b = (await (await j('GET', '/todos?q=milk')).json()).todos;
s.close(); process.exit(a.length === 1 && a[0].done === true && a[0].title === 'buy milk' && b[0].done === false ? 0 : 1);"
check "the fix is in the store, where the cause was" bash -c "git diff --name-only $(cat "$WORK/base-sha") HEAD | grep -qx src/store.js"

echo "    the loop"
check "at least two bugs were filed under the epic" test "$(wc -w < "$WORK/bugs")" -ge 2
check "one bug was put underneath another (a blocks dependency between two bugs)" bash -c "bd show $(cat "$WORK/bugs") --json --readonly | python3 -c '
import json, sys
bugs = json.load(sys.stdin); ids = {b[\"id\"] for b in bugs}
sys.exit(0 if any(d.get(\"dependency_type\") == \"blocks\" and d[\"id\"] in ids for b in bugs for d in b.get(\"dependencies\") or []) else 1)'"
check "every bug is closed, and so is every task" bash -c "bd list --parent $epic --all --limit 0 --json --readonly | python3 -c 'import json,sys; sys.exit(any(i[\"status\"]!=\"closed\" for i in json.load(sys.stdin)))'"
check "bd lint is clean: every bug filed in triage, deferred ones too, has its Steps to Reproduce" bd lint
check "nothing is stuck" test "$(bd list --label factory:stuck --all --limit 0 --json --readonly | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')" = 0
check "each round was recorded, bugs open fell to zero, and it took at least two rounds" bash -c "bd show $epic --json --readonly | python3 -c '
import json, sys
h = [int(x) for x in str((json.load(sys.stdin)[0].get(\"metadata\") or {}).get(\"round_open\", \"\")).split(\",\") if x.strip()]
sys.exit(0 if len(h) >= 2 and h[0] >= 1 and h[-1] == 0 else 1)'"
check "the epic is validated" bash -c "bd show $epic --json --readonly | python3 -c 'import json,sys; sys.exit(\"validated_at\" not in (json.load(sys.stdin)[0].get(\"metadata\") or {}))'"
check "koujou converge agrees there is nothing left" bash -c "koujou converge $epic | grep -q '^continue: 0 open'"

echo "    records"
check "every bug has an acceptance command and all pass" koujou accept $(cat "$WORK/bugs")
check "no task worktrees or task branches are left" bash -c "test \"\$(git worktree list | wc -l | tr -d ' ')\" = 1 && ! git branch --list 'factory-task/*' | grep -q ."
check "the working tree is clean" test -z "$(git status --porcelain)"
check "report.md exists and names the bugs" bash -c "for b in $(cat "$WORK/bugs"); do grep -q \"\$b\" docs/factory/search/report.md || exit 1; done"
check "validation left evidence" bash -c "ls docs/factory/search/evidence/ | grep -q ."
finish
