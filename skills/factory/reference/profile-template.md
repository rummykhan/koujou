# Factory profile

<!-- The contract between this project and the software factory. Every factory stage reads it first.
     Keep it factual and short. Where a rule already lives in CLAUDE.md / AGENTS.md, point to it; don't copy it. -->

## Project

<One paragraph: what the product is, who uses it, the stack, where the code lives if not the repo root.>

## Commands

Run from `<dir>` unless noted. "Gate" is the full set that must pass before any task is accepted. A repo with several packages has one gate row per package, and a task runs the gates of the packages it touches.

| Purpose | Command |
|---|---|
| Install | `<...>` |
| Local services | `<... or none>` |
| Gate | `<lint && typecheck && test && build>` |
| Run locally | `<...>` → `<url>` |
| Worktree setup | `<what a fresh worktree needs before the gate can run: install, env files to copy, and what must differ per worktree so parallel runs do not collide: port, database name or table prefix>` |
| Deploy | `<... or "merge PR to main">` |
| Post-deploy smoke | `<...>` |

Known gaps in the gate: <areas with no tests, flaky tests, things only checkable by hand>.

## Baseline

<Date, commit, and the result of each gate command on a clean, up-to-date base branch, run twice. Anything red or flaky here is fixed or explicitly accepted before the delivery loop runs, because the loop blames every later failure on the task in flight.>

## Git policy

- Base branch: `<main>`
- Epic branch: `factory/<epic-id>`; task branches: `factory-task/<task-id>`
- Commits: <style, e.g. conventional commits ending with the bead id>. Factory builders commit on their own task branch; say so here explicitly if CLAUDE.md / AGENTS.md carries a general "do not commit unless asked" rule (the block `bd init` generates does), so builders are not caught between the two.
- Push: <never without asking | epic branch only | ...>
- Integration: <PR to base, opened by the factory, merged by the user | ...>

## Deploy policy

- Environments: <local, staging, prod — with URLs>
- Who triggers each: <e.g. "local: factory. prod: user only, by merging the PR">
- Validation target for the delivery loop: <which environment the validator exercises>
- Rollback: <the procedure, or "none exists" — say so plainly, the orchestrator treats deploys with no rollback as needing the user every time>
- Missing environments: <e.g. "no staging: the only target beyond local is production">

## Validation

How to exercise the product as a user: <URL, how to sign in with a test account, seed data, CLI entry points, Playwright availability>.
Never use: <real customer accounts, billable actions, production data>.

## QA

- Acceptance suite: `<directory, runner, the one command that runs it, and whether the gate includes it>`
- Browser testing: <Playwright available? how it is installed here; base URL and port the suite expects; how the suite starts the product>
- Test accounts and seed data: <how to get a signed-in session without real credentials; where test secrets live, by variable name>
- Evidence: `<work order>/evidence/`

## Prerequisites and secrets

- Where secrets go: <git-ignored env file / secret manager>. Never in beads, commits, logs or briefs.
- Already available: <variable names and what they unlock>
- Sandbox vs. real: <which external services have a sandbox or fake the factory should use>

## Docs map

| Artifact | Location |
|---|---|
| Work orders | `docs/factory/<slug>/` |
| Requirements | `<work order>/requirements.md` |
| Design | `<work order>/design.md` |
| Decision log | `<path or none>` |
| Pitfalls / lessons | `<path or none>` |
| Human roadmap (if kept alongside beads) | `<path or none>` |

## Beads

- Prefix: `<xx>`; sync: <local only | pushes to remote — use `--sandbox` for trials>
- Project conventions that differ from the factory defaults: <...>

## Limits

- `max_fix_attempts`: 3   <!-- review bounces per task before it is marked stuck -->
- `max_validate_rounds`: 3   <!-- validate → fix cycles per epic before stopping for the user -->
- `max_parallel_builders`: 3   <!-- worktrees building at once -->
- Worktree root: `../.factory-worktrees/<repo-name>`   <!-- outside the repo so project tooling does not scan it -->

## Lessons

<!-- One line each, dated, with the bead id that taught it. Written by factory-retro; read by every worker before starting. -->

## Open questions

<What adoption could not determine and the user needs to confirm: inferred push and merge policy, who reviews, anything guessed. Empty once the profile is approved.>

## Project rules

Read before touching code: <CLAUDE.md, AGENTS.md, specific skills>. Hard rules worth repeating here: <...>.
