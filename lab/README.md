# Lab

Throwaway projects for testing the factory end to end live in `lab/workspace/` (git-ignored; each is its own git repo with its own beads database). This file is the record of what each run exercised and what it changed in the factory.

## Run 1 — linklab (2026-11-19)

A dependency-free Node link-shortener API. Seeded with a walking skeleton (`/health`, one test, `npm run gate`), then one lane-M epic of six tasks taken through plan → delivery loop.

**Result:** epic closed after 2 validation rounds. 7 builder runs, 7 reviews, 2 validations. 60 tests on the epic branch.

| Stage | Exercised | Outcome |
|---|---|---|
| Plan | `bd create --graph`, `bd lint`, `bd swarm validate` | 4 waves, max parallelism 3 |
| Parallel build | 3 builders in 3 worktrees at once | No lane overlap, 3 clean merges |
| Rolling waves | Next task started as soon as its blockers closed | Worked; skill updated to say so |
| Review | Independent reviewer per task | 7/7 passed first time; reviewers ran their own probes and mutation checks |
| Reviewer follow-ups | Carried into a later task's acceptance criteria; deferred bugs filed | Worked |
| Validate | Black-box against the running process | Round 1 found a real crash (EPIPE on closed stdout) that tests and reviews missed |
| Triage | 1 fix-now, 2 deferred, 1 rejected, 1 question for the user | Worked |
| Fix loop | Bug bead → builder → reviewer → merge → re-validate | Passed in round 2 |
| Stuck path | `factory:stuck` label + human gate + unclaim | Commands verified in a scratch repo only |
| Mailbox | `bd comment` from a worktree, read from the main checkout | Verified in a scratch repo only |

### Changes the run forced

1. Task branches cannot be named `factory/<epic>/<task>` while `factory/<epic>` exists (git ref conflict). Now `factory-task/<task-id>`.
2. `bd init` writes a "do not commit unless asked" rule into CLAUDE.md. The profile's git policy must say builders commit on task branches.
3. Custom agent types register only at session start. The run skill documents the fallback (general-purpose agent reading the role file).
4. Subagents inherit the orchestrator's working directory. Briefs now pin the builder to its worktree explicitly.
5. Reviewers need a three-dot diff (`git diff <epic>...HEAD`) once the epic branch has moved on.
6. A builder stopped its test server with `pkill -f`, which would have killed a sibling's server. Swarm protocol now requires stopping by PID.
7. Later validation rounds re-check fixed bugs and requirement-level criteria, not every task-level criterion.

### Not yet exercised with real agents

- A review failure bouncing back to a builder (every task passed first time), and so the `fix_attempts` cap.
- A merge conflict between task branches.
- Builders actually messaging each other mid-task; the lab's lanes were clean enough that nobody needed to.
- `factory-spec`, `factory-design` and `factory-new` as skills run by a fresh session (the lab's requirements and plan were written by the factory's author).
- Any deploy beyond a local process.


## Run 2 — linklab web UI (2026-11-19)

One lane-M epic: a web page, a list endpoint and link titles from an external API whose key was deliberately unavailable. Five tasks plus a QA task and a prerequisite.

**Result:** epic closed after 1 validation round. 4 builder runs, 1 tester run, 5 reviews, 1 validation in a real browser. 112 unit tests and a 37-test Playwright suite.

| Stage | Exercised | Outcome |
|---|---|---|
| Prerequisites | Key asked for up front, marked pending, gated bead, thin real-API task behind it | Everything else shipped; the key and its task are listed under "Waiting on you" |
| QA tester | Acceptance suite written from requirements in parallel with builders | 37 tests, red by design until wiring, then green with no edits; reviewer caught 11 of 11 injected defects with it |
| Parallel build | 4 worktrees at once (3 builders + tester) | Clean merges |
| Mailbox | Builder → tester on page handles; builder → orchestrator on a contract ripple; orchestrator ruling relayed | First real use; worked |
| Blocker bubbling | Wiring builder reported the key under `needs_user` and built on the fake | Worked |
| Validator | Chromium via Playwright browser tools, screenshots saved as evidence | All criteria pass; 3 minor bugs deferred |
| Living design | `koujou init` + as-built System design in AGENTS.md | `koujou doctor` clean |
| Retro | Earlier changelog entries checked; four new changes | See CHANGELOG.md |

### Still not exercised with real agents

- A review failure and the `fix_attempts` cap (12 of 12 reviews have passed first time).
- A merge conflict.
- `factory-spec`, `factory-design`, `factory-new` and `factory-setup` run by a fresh session, and a full `factory-adopt` followed by delivery on a real existing project.
- A deploy beyond a local process.

## Run 3: a real project (2026-11-19)

Not a lab project: four independent issues from the backlog of a live Next.js product, run as a pass on an unpushed branch. Details are in CHANGELOG.md. What it added to the record: the review-bounce path ran twice on real code (once on a reviewer `fail`, once when the orchestrator promoted a suggestion to blocking), `factory-setup` and the worktree recipe held on an existing codebase, and QA validation in a browser found no defects after review. Still unexercised: a merge conflict, the attempt cap, a factory-performed deploy, and the spec and design stages on real work.

## Run 4: a backlog pass with overlapping lanes, shipped by pull request (2026-11-20)

Six linklab backlog issues as a pass, with the dependencies between overlapping lanes left out on purpose so branches would collide. Pushed to a private GitHub repository to exercise `factory-ship`.

**Result:** five issues plus one bug found in validation shipped through PR, CI and merge; one issue held back behind a decision gate. 40 m 54 s from first claim to merged, 33 agent runs (6 scouts, 7 builder runs, 9 reviews, 6 security reviews, 2 validations, 3 rebase or re-check runs). 131 unit tests and 65 browser tests.

| Stage | Exercised | Outcome |
|---|---|---|
| Pass intake | One scout per issue, `intake.md`, decisions with defaults, questions with none | Two security decisions surfaced before any code; one issue gated, none asked late |
| Merge queue | Three branches editing `public/app.js`, two editing `src/server.js` | One conflict in the queue, sent back and resolved by its builder in 34 s; one builder rebased itself twice from mailbox notices and resolved five conflicts before review; no conflict resolved by the orchestrator |
| Conflict-resolution review | Reviewer given only the conflicted files and the sibling task | Confirmed nothing dropped, 32 s |
| Security review | One agent on each `security` task; three lenses on the assembled change | High finding (clickjacking on the new Delete button, with a working exploit) on a branch the ordinary reviewer had passed; fixed and re-verified. Four lesser findings logged |
| Review bounce | Security `fail` counted as a failed review | Fixed on attempt 1 of 3 |
| Validation and fix loop | Round 1 found a data-loss bug; fix-now through the wave; round 2 targeted | Fixed and confirmed in 20 of 20 runs; five minor bugs deferred |
| Acceptance commands | Added mid-run; used on the fix-now bug | Red ("No tests found") before the fix, 7 tests green after; reviewer confirmed 3 fail with the fix reverted |
| Time | `koujou times` | Per-task build, review and queue times; run totals |
| Ship | Push, pull request, GitHub Actions, merge, close issues, clean up | Worked first time |

### Still not exercised with real agents

- The stuck path at the attempt cap, and a conflict whose two sides cannot both hold.
- `factory-spec`, `factory-design` and `factory-new` on real work.
- A deploy performed by the factory, and validation of a deployed environment.
- Acceptance commands from the plan stage onward (here they were added part-way; three of six tasks have none).

## Run 5: setup on a second real project (2026-11-21)

`factory-setup` on a live product of a different shape from the first: a workspace repository holding the tracking (beads, roadmap, specs, decision log) with the product checked out inside it as its own repository; six apps over DynamoDB; no tests, no CI, no staging, and local runs that read the production tables. Setup only: the profile, the Test map and the system design. No work has been delivered there yet.

| Stage | Exercised | Outcome |
|---|---|---|
| Discovery | Two repositories, existing roadmap, specs, decision log and pitfalls | Mapped in the profile's Docs map; the design stage will write the project's own spec |
| Baseline gate | Build and typecheck twice in the main checkout | Green both times |
| Worktree recipe | Throwaway worktree: install, build, typecheck, two app builds | Green, after one false alarm: the app builds failed in a network-sandboxed shell and passed with network access |
| Test map | Inferred from the code and infrastructure; read access tried once (AWS identity, table list, GitHub) | Ten rows; five marked interface only because their only target is production |
| Hand-over | Open questions | Five, among them where write paths may be tested |

### Still not exercised with real agents

- `factory-spec` and `factory-design` on real work (the next step on this project), and `factory-new` on an empty directory.
- A task marked stuck; validation of a deployed test environment.
- The validator's cross-check against a real database or cloud account (the scenarios use a file).
