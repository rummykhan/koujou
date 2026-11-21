#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"; . "$(dirname "$0")/../../lib/todo.sh"; . "$(dirname "$0")/../../lib/search_bug.sh"
id=$(cat "$WORK/task"); wt="$WORK/wt"
report_has "builder reports done" '^status:[[:space:]]*done'
report_has "nothing deeper is claimed" '^blocked_by:[[:space:]]*none'
check "the bug no longer reproduces" test "$(search_status "$wt")" = 200
check "work is committed and the worktree is clean" bash -c "test -n \"\$(git -C '$wt' log --oneline factory/epic..factory-task/$id)\" && test -z \"\$(git -C '$wt' status --porcelain)\""
check "acceptance command passes on a test named with the bug's id" bash -c "cd '$wt' && '$TESTS_DIR/../bin/koujou' accept $id"
check "gate is green" bash -c "cd '$wt' && npm run gate"
check "only lane files changed" bash -c "! git -C '$wt' diff --name-only factory/epic...factory-task/$id | grep -Ev '^(src/server\.js|test/search\.test\.js)$'"
check "builder wrote no bead state (bug still in progress)" test "$(cd "$WORK/todo" && bd show "$id" --json --readonly | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["status"])')" = in_progress
finish
