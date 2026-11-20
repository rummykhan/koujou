# done_branch <work> <variant>: a todo repo with one task and its branch built as <variant>, ready for review.
# Writes the task id to <work>/task and the worktree path to <work>/worktree.
done_branch() {
  local work="$1" variant="$2" id
  todo_repo "$work" || return 1
  id=$(new_task "PATCH /todos/<id> marks a todo done or not done" 'Users can mark a todo done or not done. PATCH /todos/<id> with {"done": boolean} sets it and returns the todo.' '- PATCH /todos/<id> with {"done":true} answers 200 with the todo, done true — test: API
- PATCH /todos/<id> with {"done":false} on a done todo sets it back to not done, and GET /todos shows it — test: API
- A body without a boolean done answers 400 {"error":"invalid_done"}; an unknown id answers 404; other methods on /todos/<id> answer 405 — test: API
- Existing behaviour is unchanged: existing tests are untouched and green — run: `npm run gate`' 'Lane: src/store.js (setDone), src/server.js (the /todos/<id> route), test/done.test.js (new). Tests are named with the task id.') || return 1
  bd update "$id" --set-metadata accept="node --test --test-name-pattern \"$id\"" >/dev/null
  bd update "$id" --claim >/dev/null
  git checkout -q -b factory/epic
  git worktree add -q "$work/wt" -b "factory-task/$id" factory/epic
  ( cd "$work/wt" && python3 "$TESTS_DIR/fixtures/variants/make.py" "$variant" "$id" && git add -A && git commit -q -m "feat(todos): mark a todo done ($id)" ) || return 1
  echo "$id" > "$work/task"; echo "$work/wt" > "$work/worktree"
}
