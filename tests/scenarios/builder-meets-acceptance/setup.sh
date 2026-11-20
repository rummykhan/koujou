#!/bin/bash
. "$(dirname "$0")/../../lib/todo.sh"
work="$1"; todo_repo "$work" || exit 1
id=$(new_task "DELETE /todos/<id> removes a todo" \
  "Users can remove a todo they no longer need." \
  "- DELETE /todos/<id> answers 204 with no body and the todo is gone from GET /todos — test: API
- DELETE of an unknown id answers 404 {\"error\":\"not_found\"} — test: API
- Ids are not reused: a todo added after a delete gets a new id — test: unit, on the store
- Existing behaviour is unchanged: existing tests are untouched and green — run: \`npm run gate\`" \
  "Lane: src/store.js (remove), src/server.js (the /todos/<id> route), test/delete.test.js (new). Name every test with the task id." ) || exit 1
bd update "$id" --set-metadata accept="node --test --test-name-pattern \"$id\"" >/dev/null; bd update "$id" --claim >/dev/null
git checkout -q -b factory/epic
git worktree add -q "$work/wt" -b "factory-task/$id" factory/epic
mkdir -p "$work/scratch"
echo "$id" > "$work/task"; echo "$work/wt" > "$work/worktree"
