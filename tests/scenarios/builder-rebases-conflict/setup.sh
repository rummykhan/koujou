#!/bin/bash
. "$(dirname "$0")/../../lib/todo.sh"
work="$1"; todo_repo "$work" || exit 1
a=$(new_task "PATCH /todos/<id> marks a todo done or not done" "Mark a todo done or not done." "- PATCH sets done and returns the todo — test: API" "Lane: src/store.js, src/server.js, test/done.test.js.") || exit 1
b=$(new_task "GET /todos?done=true|false filters the list" "List only done or only open todos." "- GET /todos?done=false lists only todos that are not done — test: API" "Lane: src/server.js (GET /todos), test/filter.test.js.") || exit 1
for t in $a $b; do bd update $t --set-metadata accept="node --test --test-name-pattern \"$t\"" >/dev/null; bd update $t --claim >/dev/null; done
git checkout -q -b factory/epic
git worktree add -q "$work/wt" -b "factory-task/$a" factory/epic
( cd "$work/wt" && python3 "$TESTS_DIR/fixtures/variants/make.py" done-good "$a" && git add -A && git commit -q -m "feat(todos): mark a todo done ($a)" ) || exit 1
# the sibling lands first, on the epic branch, touching the same place in src/server.js
python3 "$TESTS_DIR/fixtures/variants/make.py" list-filter "$b" && git add -A && git commit -q -m "feat(todos): filter the list by done ($b)" || exit 1
git -C "$work/wt" rebase factory/epic >/dev/null 2>&1 && { echo "setup error: the rebase did not conflict" >&2; exit 1; }
git -C "$work/wt" rebase --abort
echo "$a" > "$work/task"; echo "$b" > "$work/sibling"; echo "$work/wt" > "$work/worktree"; git rev-parse factory/epic > "$work/epic-sha"
