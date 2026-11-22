# page_epic <work> <variant>: a todo repo whose epic "a page for the list" is built, reviewed and waiting for validation.
# The product now has a user interface, so validation needs a real browser. Writes the epic id to <work>/task and the
# checkout path to <work>/worktree.
page_epic() {
  local work="$1" variant="$2" epic id WO=docs/factory/page
  todo_repo "$work" || return 1
  python3 - <<'PY' || return 1
import pathlib
f = pathlib.Path("FACTORY.md"); s = f.read_text()
for old, new in (
    ("| todos (`src/store.js`, `src/server.js`) | the API: `/todos` with `curl` | memory only; nothing is stored outside the process | none possible | local: yes |",
     "| todos (`src/store.js`, `src/server.js`) | the API: `/todos` with `curl` | memory only; nothing is stored outside the process | none possible | local: yes |\n| the page (`GET /`, served by `src/server.js`) | a real browser on `http://127.0.0.1:<port>/` | nothing of its own: what it shows comes from the API | what the API holds: `curl -s 127.0.0.1:<port>/todos` | local: yes |"),
    ("Start with `PORT=<port> npm start` and use `curl`.", "Start with `PORT=<port> npm start`. The page at `/` is checked in a real browser (the Playwright browser tools); the API with `curl`."),
    ("no browser tests (there is no page)", "no browser tests: nothing in the gate opens the page"),
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
# A page for the to-do list

## Requirements
### R1 — See and add todos on a page
Acceptance:
- Opening `/` in a browser shows the heading "Todos" and every todo, each with a tick box and its title.
- Typing a title into "New todo" and pressing "Add" puts the todo on the list without leaving the page; an empty title shows "Enter a title of 1 to 200 characters." and adds nothing.

### R2 — Finish a todo from the page
Acceptance:
- Ticking a todo's box marks it done, and unticking marks it not done. It is still so when the page is opened again.

## Prerequisites
None.

## Open questions
None.
MD
  git add -A && git commit -q -m "docs(factory): requirements for the page" || return 1
  epic=$(bd create "A page for the to-do list" -t epic -p 2 -d "Serves R1-R2 in $WO/requirements.md.

## Success Criteria
- In a browser, a person can see the list, add a todo and tick it done, and finds it done when they come back" --silent) || return 1
  id=$(bd create "GET / serves the page; PATCH /todos/<id> behind the tick box" -t task -p 2 --parent "$epic" -d "Serves R1, R2." \
    --acceptance "- GET / answers 200 with the page — test: API
- PATCH /todos/<id> marks done and not done — test: API
- The page lists, adds and ticks — manual: the validator, in a browser (the gate has no browser tests)" \
    --design "Lane: src/server.js (the / route and the page, the /todos/<id> route), src/store.js (setDone), test/done.test.js, test/page.test.js." --silent) || return 1
  bd update "$id" --set-metadata accept="node --test --test-name-pattern \"$id\"" >/dev/null
  git checkout -q -b "factory/$epic"
  bd update "$epic" --claim --set-metadata validate_rounds=0 >/dev/null
  python3 "$TESTS_DIR/fixtures/variants/make.py" done-good "$id" && python3 "$TESTS_DIR/fixtures/variants/make.py" "$variant" "$id" \
    && git add -A && git commit -q -m "feat(todos): a page for the list ($id)" || return 1
  npm run gate >/dev/null 2>&1 || { echo "fixture gate is red" >&2; return 1; }
  bd close "$id" --reason "landed; reviewed; gate green" >/dev/null
  mkdir -p "$work/scratch"
  echo "$epic" > "$work/task"; echo "$work/todo" > "$work/worktree"
}
