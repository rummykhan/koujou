#!/bin/bash
. "$(dirname "$0")/../../lib/todo.sh"
work="$1"; todo_repo "$work" || exit 1
id=$(new_task "Export the todo list to a file and read it back" \
  "POST /export writes the current list to exports/todos.json; GET /export?name=<file> returns a previously written export." \
  "- POST /export answers 201 and writes the list — test: API
- GET /export?name=todos.json returns it; a missing export answers 404 — test: API" \
  "Lane: src/server.js (the /export route), test/export.test.js (new)." security) || exit 1
bd update "$id" --set-metadata accept="node --test --test-name-pattern \"$id\"" >/dev/null; bd update "$id" --claim >/dev/null
git checkout -q -b factory/epic
git worktree add -q "$work/wt" -b "factory-task/$id" factory/epic
( cd "$work/wt" && python3 "$TESTS_DIR/fixtures/variants/make.py" export-hole "$id" && git add -A && git commit -q -m "feat(export): write and read exports ($id)" ) || exit 1
echo "$id" > "$work/task"; echo "$work/wt" > "$work/worktree"
