#!/bin/bash
# An epic that is built, reviewed and security-reviewed, waiting for validation, with one planted defect:
# searching after a todo is marked done shows it as not done. The cause is in the store, not where it shows.
. "$(dirname "$0")/../../lib/todo.sh"
work="$1"; todo_repo "$work" || exit 1
V="$TESTS_DIR/fixtures/variants/make.py"; WO=docs/factory/search
mkdir -p "$WO"
cat > "$WO/requirements.md" <<'MD'
---
status: approved
lane: M
---
# Find a todo by text, and finish it

## Requirements
### R1 — Mark done or not done
Acceptance:
- `PATCH /todos/<id>` with `{"done":true}` or `{"done":false}` answers 200 with the todo in its new state, and `GET /todos` shows it.

### R2 — Search by text
Acceptance:
- `GET /todos?q=<text>` lists only the todos whose title contains the text.
- Every todo a search returns is shown as it is now: a todo that has been marked done is listed with `done` true, and with `done` false again once it is marked not done.

## Prerequisites
None.

## Open questions
None.
MD
git add -A && git commit -q -m "docs(factory): requirements for search" || exit 1
epic=$(bd create "Find a todo by text, and finish it" -t epic -p 2 -d "Serves R1-R2 in $WO/requirements.md.

## Success Criteria
- On the running server a todo can be marked done and not done again, and GET /todos shows the change
- Searching by text lists the matching todos, each in its current state: after a todo is marked done, a search that finds it shows done true" --silent) || exit 1
mk() { local id; id=$(bd create "$1" -t task -p 2 --parent "$epic" -d "$2" --acceptance "$3" --design "$4" --silent) || return 1
  bd update "$id" --set-metadata accept="node --test --test-name-pattern \"$id\"" >/dev/null; echo "$id"; }
index=$(mk "Store: search todos by text" "A text index in the store. Serves R2." "- store.search(text) returns the todos whose title contains the text — test: unit" "Lane: src/store.js (the index and search), test/search-index.test.js.") || exit 1
done_id=$(mk "PATCH /todos/<id> marks a todo done or not done" "Serves R1." "- PATCH sets done and returns the todo — test: API" "Lane: src/store.js (setDone), src/server.js (the /todos/<id> route), test/done.test.js.") || exit 1
route=$(mk "GET /todos?q=<text> searches titles" "Serves R2." "- GET /todos?q=<text> lists only todos whose title contains the text — test: API" "Lane: src/server.js (the q branch of GET /todos), test/search.test.js. Reads through store.search.") || exit 1
git checkout -q -b "factory/$epic"
bd update "$epic" --claim --set-metadata validate_rounds=0 >/dev/null
land() { git add -A && git commit -q -m "$1" && npm run gate >/dev/null 2>&1 || { echo "fixture gate is red after: $1" >&2; return 1; }; bd close "$2" --reason "landed; reviewed; gate green" >/dev/null; }
python3 "$V" search-index "$index" && land "feat(store): search index ($index)" "$index" || exit 1
python3 "$V" done-good "$done_id" && python3 "$V" setdone-replace "$done_id" && land "feat(todos): mark a todo done ($done_id)" "$done_id" || exit 1
python3 "$V" search-route "$route" && land "feat(todos): search by text ($route)" "$route" || exit 1
printf '# Security review\n\nThree lenses (access, input, exposure) passed with no introduced finding. (Fixture: recorded by setup.)\n' > "$WO/security.md"
git add -A && git commit -q -m "docs(factory): security review" || exit 1
bd update "$epic" --set-metadata security_at="$(date -u +%FT%TZ)" >/dev/null
git rev-parse HEAD > "$work/base-sha"; echo "$epic" > "$work/epic"
