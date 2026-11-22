# stored_delete <work> <variant>: a todo repo whose epic "delete a todo" is built, reviewed and waiting for validation.
# Todos are kept in data/todos.json, and the profile's Test map says so. Writes the epic id to <work>/task and the
# checkout path to <work>/worktree.
stored_delete() {
  local work="$1" variant="$2" epic id WO=docs/factory/delete
  todo_repo "$work" || return 1
  python3 - <<'PY' || return 1
import pathlib
f = pathlib.Path("FACTORY.md"); s = f.read_text()
for old, new in (
    ("state in memory.", "state in a JSON file."),
    ("| memory only; nothing is stored outside the process | none possible | local: yes |",
     "| `data/todos.json`, in the directory the server was started from (`TODO_DATA` overrides the path) | read the file: `cat data/todos.json` | local: yes |"),
    ("State is in memory; no accounts.", "State is in `data/todos.json`; no accounts."),
):
    assert old in s, old
    s = s.replace(old, new)
f.write_text(s)
PY
  mkdir -p "$WO"
  cat > "$WO/requirements.md" <<'MD'
---
status: approved
lane: M
---
# Delete a todo

## Requirements
### R1 — Delete
Acceptance:
- `DELETE /todos/<id>` answers 204, and the todo is no longer in `GET /todos`.
- Deleting an id that does not exist, or one already deleted, answers 404 `{"error":"not_found"}`.
- Other todos keep their ids, and a deleted id is never given to a new todo.

## Prerequisites
None.

## Open questions
None.
MD
  git add -A && git commit -q -m "docs(factory): requirements for delete" || return 1
  epic=$(bd create "Delete a todo" -t epic -p 2 -d "Serves R1 in $WO/requirements.md.

## Success Criteria
- On the running server a todo can be deleted: it is gone, and the other todos and their ids are untouched" --silent) || return 1
  id=$(bd create "DELETE /todos/<id>, with todos kept in a file" -t task -p 2 --parent "$epic" -d "Serves R1." \
    --acceptance "- DELETE answers 204 and the todo leaves the list; 404 for an unknown or deleted id — test: API
- Todos are read back from the file by a new store — test: unit" \
    --design "Lane: src/store.js, src/server.js (the /todos/<id> route), src/main.js, test/delete.test.js." --silent) || return 1
  bd update "$id" --set-metadata accept="node --test --test-name-pattern \"$id\"" >/dev/null
  git checkout -q -b "factory/$epic"
  bd update "$epic" --claim --set-metadata validate_rounds=0 >/dev/null
  python3 "$TESTS_DIR/fixtures/variants/make.py" "$variant" "$id" && git add -A && git commit -q -m "feat(todos): delete a todo ($id)" || return 1
  npm run gate >/dev/null 2>&1 || { echo "fixture gate is red" >&2; return 1; }
  bd close "$id" --reason "landed; reviewed; gate green" >/dev/null
  echo "$epic" > "$work/task"; echo "$work/todo" > "$work/worktree"
}
