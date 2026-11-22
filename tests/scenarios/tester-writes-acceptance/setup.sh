#!/bin/bash
. "$(dirname "$0")/../../lib/todo.sh"
work="$1"; todo_repo "$work" || exit 1
mkdir -p docs/factory/done && cat > docs/factory/done/requirements.md <<'R'
---
status: approved
lane: M
---
# Mark a todo done or not done

## Requirements
### R1 — Mark done, and not done again
Acceptance:
- `PATCH /todos/<id>` with `{"done":true}` answers 200 with the todo, `done` true; with `{"done":false}` on a done todo, 200 with `done` false. The todo is `{ "id", "title", "done" }` and its title does not change.
- `GET /todos` shows each todo in the state it was last set to.

### R2 — Refuse what is not a valid request
Acceptance:
- A body that is not JSON, or has no `done`, or a `done` that is not a boolean (`"yes"`, `1`, `null`) answers 400 `{"error":"invalid_done"}` and changes nothing. The body is checked before the id is looked up.
- An id no todo has answers 404 `{"error":"not_found"}`.
- Any other method on `/todos/<id>` answers 405 `{"error":"method_not_allowed"}`.

## Prerequisites
None.

## Open questions
None.
R
git add -A && git commit -q -m "docs: requirements for marking a todo done"
epic=$(bd create "Mark a todo done or not done" -t epic -d "Serves R1-R2 in docs/factory/done/requirements.md.

## Success Criteria
- On the running server a todo can be marked done and not done again, and GET /todos shows the change
- An invalid request is refused with its error and changes nothing" --silent) || exit 1
bd create "PATCH /todos/<id> marks a todo done or not done" -t task --parent "$epic" -d "Serves R1, R2." --acceptance "- as R1 and R2 — test: API" --design "Lane: src/store.js, src/server.js, test/done.test.js" --silent >/dev/null
id=$(bd create "Acceptance tests for marking a todo done" -t task --parent "$epic" -l qa -d "The automated acceptance tests for the epic, written from docs/factory/done/requirements.md before the feature exists." --acceptance "- Every acceptance line of R1 and R2 has a named test, or a stated reason it is manual — run: the report's coverage list
- The tests run with one command and are named with this task's id — run: the acceptance command
- On the base they fail because the feature is absent, not because of the harness — run: the acceptance command" --design "Lane: test/acceptance/ (new; any .js file under test/ is run by \`npm test\`). Start the product the way test/helpers.js does and talk to it over HTTP. No change to src/ or to existing tests." --silent) || exit 1
bd update "$id" --set-metadata accept="node --test --test-name-pattern \"$id\"" >/dev/null; bd update "$id" --claim >/dev/null
git checkout -q -b factory/epic
git worktree add -q "$work/wt" -b "factory-task/$id" factory/epic
mkdir -p "$work/scratch"
echo "$id" > "$work/task"; echo "$epic" > "$work/sibling"; echo "$work/wt" > "$work/worktree"
