# search_bug <work> <variant>: a todo repo whose epic branch holds two landed tasks (mark done; search by text) and a
# validator's bug: searching answers 500 once a todo is marked done. <variant> decides where the cause lives.
# Writes the bug's id to <work>/task, the worktree to <work>/worktree, the store's owner task to <work>/sibling.
search_bug() {
  local work="$1" variant="$2" done_id search_id bug
  todo_repo "$work" || return 1
  done_id=$(new_task "PATCH /todos/<id> marks a todo done or not done" "Users can mark a todo done or not done." "- PATCH sets done and returns the todo — test: API" "Lane: src/store.js (setDone), src/server.js (the /todos/<id> route), test/done.test.js.") || return 1
  search_id=$(new_task "GET /todos?q=<text> searches titles" "Users can search their todos by text." "- GET /todos?q=<text> lists only todos whose title contains the text — test: API" "Lane: src/server.js (the q filter on GET /todos), test/search.test.js.") || return 1
  git checkout -q -b factory/epic
  python3 "$TESTS_DIR/fixtures/variants/make.py" done-good "$done_id" || return 1
  # the store defect arrives with the task that owns the store, so history agrees with the bug's lane note
  if [ "$variant" = search-store-bug ]; then python3 "$TESTS_DIR/fixtures/variants/make.py" store-list-bug "$done_id" || return 1; fi
  git add -A && git commit -q -m "feat(todos): mark a todo done ($done_id)" || return 1
  python3 "$TESTS_DIR/fixtures/variants/make.py" "$variant" "$search_id" && git add -A && git commit -q -m "feat(todos): search by text ($search_id)" || return 1
  npm run gate >/dev/null 2>&1 || { echo "fixture gate is not green" >&2; return 1; }
  bd close "$done_id" --reason "landed" >/dev/null; bd close "$search_id" --reason "landed" >/dev/null
  bug=$(bd create "Searching todos answers 500 once any todo is marked done" -t bug -p 1 \
    -d "Found by the validator on the assembled epic branch.

## Steps to Reproduce
1. POST /todos {\"title\":\"buy milk\"}
2. PATCH /todos/1 {\"done\":true}
3. GET /todos?q=milk

Observed: 500 {\"error\":\"internal\"}. Expected: 200 with the todo, done true." \
    --acceptance "- After a todo is marked done, GET /todos?q=<text> answers 200 and lists the matching todos, the done one included — test: API
- Existing behaviour is unchanged: existing tests are untouched and green — run: \`npm run gate\`" \
    --design "Lane: src/server.js (the q filter on GET /todos), test/search.test.js. src/store.js is not in this lane: it belongs to $done_id (mark done), which has landed. Name every new test with this bug's id." --silent) || return 1
  bd update "$bug" --set-metadata accept="node --test --test-name-pattern \"$bug\"" >/dev/null; bd update "$bug" --claim >/dev/null
  git worktree add -q "$work/wt" -b "factory-task/$bug" factory/epic
  mkdir -p "$work/scratch"
  echo "$bug" > "$work/task"; echo "$work/wt" > "$work/worktree"; echo "$done_id" > "$work/sibling"
}

# search_status <worktree>: prints the status of the bug's last step (search after marking done) on that tree.
search_status() {
  ( cd "$1" && node --input-type=module -e "
import { createServer } from './src/server.js';
const s = createServer(); await new Promise(r => s.listen(0, '127.0.0.1', r)); const u = 'http://127.0.0.1:' + s.address().port;
await fetch(u + '/todos', { method: 'POST', body: JSON.stringify({ title: 'buy milk' }) });
await fetch(u + '/todos/1', { method: 'PATCH', body: JSON.stringify({ done: true }) });
const r = await fetch(u + '/todos?q=milk'); console.log(r.status); s.close();" )
}
