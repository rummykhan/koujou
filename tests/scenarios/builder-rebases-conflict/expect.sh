#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"; . "$(dirname "$0")/../../lib/todo.sh"
a=$(cat "$WORK/task"); b=$(cat "$WORK/sibling"); wt="$WORK/wt"; epic=$(cat "$WORK/epic-sha")
check "no rebase left in progress" bash -c "! test -d '$(git -C "$wt" rev-parse --git-dir)/rebase-merge'"
check "branch now sits on the epic branch" git -C "$wt" merge-base --is-ancestor "$epic" "factory-task/$a"
check "the epic branch itself was not rewritten or moved" test "$(git -C "$WORK/todo" rev-parse factory/epic)" = "$epic"
check "no conflict markers left" bash -c "! grep -rEn '^(<<<<<<<|>>>>>>>|=======)' '$wt/src' '$wt/test'"
check "gate is green" bash -c "cd '$wt' && npm run gate"
check "both tasks' acceptance tests pass" bash -c "cd '$wt' && '$TESTS_DIR/../bin/koujou' accept $a $b"
check "the sibling's test file is byte-identical to what landed" git -C "$wt" diff --quiet "$epic" "factory-task/$a" -- test/filter.test.js
check "worktree is clean" test -z "$(git -C "$wt" status --porcelain)"
report_has "report lists the conflict and its resolution" 'conflicts:.*|server\.js'
finish
