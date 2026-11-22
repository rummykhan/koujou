#!/bin/bash
. "$(dirname "$0")/../../lib/todo.sh"
work="$1"; todo_repo "$work" || exit 1
mkdir -p docs/factory/tidy && cat > docs/factory/tidy/requirements.md <<'R'
---
status: approved
lane: L
---
# Finish and tidy a to-do list

## Requirements
### R1 — Mark a todo done or not done
Acceptance:
- `PATCH /todos/<id>` with `{"done":true}` or `{"done":false}` answers 200 with the todo in its new state; `GET /todos` shows it.
- A body without a boolean `done` answers 400; an id no todo has answers 404.

### R2 — Delete a todo
Acceptance:
- `DELETE /todos/<id>` answers 204 and the todo is gone from `GET /todos`; an unknown or already deleted id answers 404.
- Other todos keep their ids, and a deleted id is never given to a new todo.

### R3 — List only open or only done todos
Acceptance:
- `GET /todos?done=true` lists only done todos, `?done=false` only open ones; without the parameter, all.

### R4 — Know how long the list is
Acceptance:
- A client can tell how many todos exist in all without counting a filtered answer.

## Prerequisites
None.

## Open questions
None.
R
cat > docs/factory/tidy/design.md <<'R'
---
status: approved
---
# Design — finish and tidy a to-do list

## Components
| Component | Change | Where |
|---|---|---|
| Store | `setDone(id, done)`, `remove(id)`; ids never reused | `src/store.js` |
| Item route | new `/todos/<id>` block: PATCH and DELETE, 405 for other methods | `src/server.js` |
| List route | `done` filter on GET `/todos`; total-count header | `src/server.js` |
| Delete log | one line per successful delete, for the operator | `src/server.js` |

## Contracts
| Interface | Contract |
|---|---|
| `PATCH /todos/<id>` | `{done: boolean}` → 200 todo; 400 `{"error":"invalid_done"}` when `done` is missing or not a boolean (checked before the id); 404 `{"error":"not_found"}` |
| `DELETE /todos/<id>` | 204, no body; 404 `{"error":"not_found"}` for an unknown or already deleted id |
| other methods on `/todos/<id>` | 405 `{"error":"method_not_allowed"}` |
| `GET /todos?done=` | `true` or `false` filters; any other value → 400 `{"error":"invalid_done_filter"}` |
| `GET /todos` response header | `X-Total-Count: <n>`, the number of todos that exist, whatever the filter |
| delete log | on each 204, one line on stderr: `deleted <id>`; nothing on a 404 |

## Test strategy
Unit tests on the store; API tests through `test/helpers.js` for every route and error; the acceptance suite is a QA task under `test/acceptance/`.

## Decisions
- D1: the filter is applied in the route over `store.list()`; the store does not learn about filters.
- D2: PATCH and DELETE live in one route block, so they are built one after the other, not in parallel.
R
git add -A && git commit -q -m "docs: requirements and design for tidy"
git rev-parse HEAD > "$work/base-sha"
