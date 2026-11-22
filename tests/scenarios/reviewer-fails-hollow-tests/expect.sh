#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"
report_has "verdict is fail" '^verdict:[[:space:]]*fail'
report_has "the finding is about the tests, in the test file" 'done\.test'
report_has "says the tests would not notice a broken product" 'would (still )?pass|still pass|stays? green|does not (assert|check|pin|fail)|doesn.t (assert|check|pin|fail)|never (assert|check)|mutat|always true|against a stub|without the|not pinned|weak|hollow|vacuous'
report_lacks "does not invent a defect in the product code" '^[[:space:]]*-[[:space:]]*src/(store|server)\.js:[0-9]+ — .*(always|ignores|accepted|missing validation)'
check "reviewer changed nothing in the worktree" test -z "$(git -C "$WORK/wt" status --porcelain)"
check "reviewer wrote no bead state" test "$(cd "$WORK/todo" && bd show "$(cat "$WORK/task")" --json --readonly | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["status"])')" = in_progress
finish
