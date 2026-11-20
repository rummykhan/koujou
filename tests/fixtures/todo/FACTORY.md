# Factory profile

## Project

A to-do list API used as the fixture for the factory's own tests: Node 22, standard library only, state in memory. `src/store.js` holds the data, `src/server.js` the routes, `src/main.js` starts it.

## Commands

Run from the repo root.

| Purpose | Command |
|---|---|
| Install | none (no dependencies) |
| Local services | none |
| Gate | `npm run gate` (syntax check, then all unit tests) |
| Run locally | `PORT=<port> npm start` → `http://127.0.0.1:<port>` |
| Worktree setup | none |
| Deploy | none — local only |
| Post-deploy smoke | `curl -s 127.0.0.1:<port>/health` returns `{"ok":true}` |

Known gaps in the gate: no linter beyond a syntax check; no browser tests (there is no page).

## Baseline

Fixture: the gate is green by construction (6 tests).

## Git policy

- Base branch: `main`
- Epic branch: `factory/<epic-id>`; task branches: `factory-task/<task-id>`
- Commits: conventional commits ending with the bead id. Factory builders commit on their own task branch.
- Push: never (no remote). Task branches are never pushed.
- Integration: local merge of the epic branch into `main`.
- Merge: factory, standing permission (this is a test fixture); method: merge (`--no-ff`).
- Required human review: none.

## Deploy policy

- Environments: local only.
- Validation target: local; the epic branch started on a free port.
- Deployed validation: none.
- Rollback: not applicable.

## Validation

Start with `PORT=<port> npm start` and use `curl`. State is in memory; no accounts.

## QA

- Acceptance suite: none separate; acceptance tests are unit and API tests under `test/`.
- One task's tests: `node --test --test-name-pattern "<id>"` (tests are named `<id>: <behaviour>`).
- Evidence: `docs/factory/<slug>/evidence/`

## Security review

- Lenses: `access`, `input`, `exposure`.
- Trust boundaries: no accounts; everyone who can reach the server is anonymous and may create and list todos. The server listens on 127.0.0.1 only.
- Out of bounds: nothing beyond the local instance exists.

## Prerequisites and secrets

- Where secrets go: `.env` (git-ignored). None are needed.

## Docs map

| Artifact | Location |
|---|---|
| Work orders | `docs/factory/<slug>/` |

## Beads

- Prefix: `td`; local only, no remote.

## Limits

- `max_fix_attempts`: 3
- `max_validate_rounds`: 2
- `max_rebases`: 3
- `max_parallel_builders`: 3
- Worktree root: `../.factory-worktrees/<repo-name>`

## Lessons

## Project rules

- Standard library only; no dependencies.
- ES modules, named exports.
- Modules take their collaborators as arguments (`createServer({ store })`).
- Errors are JSON `{ "error": "<code>" }` through `send()`.
