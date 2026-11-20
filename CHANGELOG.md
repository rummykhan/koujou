# Factory changelog

Changes the factory made to itself, each tied to the run that taught it. `factory-retro` appends here and checks earlier entries' expected effects against later runs.

## 2026-11-19 — linklab / ll-mms (lab run 1) and an existing Next.js project (factory-adopt trial)

Applied during the run:
- **skills/factory-run, profile-template**: task branches are `factory-task/<task-id>` — because `factory/<epic>/<task>` cannot coexist with the epic branch `factory/<epic>` (git ref conflict, first worktree creation failed). Expected effect: worktree creation never fails on naming.
- **skills/factory-run**: waves roll; reviewers get a three-dot diff; briefs pin the worker to its worktree — because ll-n1a became ready while ll-2ji was still in review, the epic branch had moved before two reviews, and subagents inherited the orchestrator's working directory. Expected effect: no idle slots while work is ready; no reviewer confused by unrelated changes; no agent working in the wrong checkout.
- **reference/swarm.md**: stop processes by PID — because the ll-6jl builder used `pkill -f "node src/main.js"`. Expected effect: no pattern kills in worker reports.
- **skills/factory-run**: later validation rounds re-check fixed bugs and requirement-level criteria only — because round 2 for ll-mms.1 did not need 40 task-level criteria repeated. Expected effect: round 2+ validations cost roughly half of round 1.

Applied by the retro:
- **agents/factory-reviewer**: run the real entry point when a change touches start-up or wiring — because ll-mms.1 (EPIPE crash on closed stdout) passed six reviews and 58 in-process tests and was only caught by the validator. Expected effect: wiring-level defects are caught at review, before validation.
- **skills/factory-plan**: the wiring task must carry a criterion that runs the real process or page; an existing backlog issue is brought up to standard when picked up — same incident, and that project's backlog (108 of 126 open issues without acceptance criteria). Expected effect: no epic reaches validation without something having started the real program.
- **agents/factory-validator**: exercise the real process under an imperfect environment (missing config, busy port, closed output); keep evidence files — because that probing is what found ll-mms.1. Kept on purpose.
- **skills/factory-adopt**: check the base is current with the remote; one gate per package; run the gate twice and look for state shared between runs; prove the worktree recipe in a throwaway worktree; check existing worktrees; list operating prerequisites — because on the existing project the local base was two PRs behind, `npm test` failed 2/113 on the first run and passed on rerun (shared DynamoDB Local tables), the repo has three gates, and the worktree recipe could not be proven. Expected effect: a profile whose baseline can be trusted, and no surprise flake blamed on a task.
- **reference/profile-template**: added Baseline, Open questions, per-worktree isolation, multi-package gates, "no rollback / no staging" slots, QA, Prerequisites and secrets, Lessons — the trial agent had to invent the first two; the rest follow from the items above.
- **reference/beads.md**: `decision` needs Decision/Rationale/Alternatives Considered and `spike` needs Goal/Findings (verified against bd 1.3.4; the reference said none); `--readonly` for discovery; `bd list --json` omits descriptions.
- **reference/swarm.md**: per-worktree database name or table prefix — because that project's tests share persistent tables.

New in this pass (requested by the user, not yet exercised when written):
- **agents/factory-tester**, **skills/factory-plan (QA task)**: a QA test engineer writes the acceptance suite from the requirements, in parallel with the builders.
- **reference/blockers.md** and the prerequisite sweep in spec/design/plan/run: ask for everything only the user can provide once, up front; gate or defer what is unavailable; bubble up what surfaces mid-run.
- **skills/factory-retro**: this stage.

## 2026-11-19 — linklab / ll-rzg (lab run 2: web UI, QA, a missing API key)

Earlier entries checked against this run:
- Reviewer runs the real entry point for wiring changes — **confirmed** (the ll-bkl and ll-rej reviewers both started the real process).
- Wiring task carries a real-process criterion — **confirmed** (ll-rej added a spawned-process test; validation passed in round 1, down from 2).
- Stop processes by PID — **confirmed** (every worker reported PID-based cleanup).
- Rolling waves, three-dot diff, worktree pinning, branch naming — **confirmed**, no incidents.
- `fix_attempts` cap and the stuck path — **no evidence yet**: 12 of 12 reviews across both runs passed first time.

Changed:
- **reference/blockers.md**: a prerequisite bead is not a child of the epic — because ll-rzg.1 (the API key) had to be detached before the epic could close. Expected effect: an epic with an open prerequisite closes without manual surgery.
- **agents/factory-validator**, **skills/factory-run**: the validator's verdict rests on user-observable criteria; how-it-was-built criteria and the orchestrator's gate run count as checked elsewhere — because the ll-rzg validator returned `fail` although every criterion it could exercise passed. Expected effect: no technical fails; a `fail` always names a broken criterion.
- **skills/factory-run**: the acceptance suite is expected red on the epic branch until the wiring task merges; worktrees are removed with `--force` — because the suite failed 37/37 by design between ll-41o and ll-rej, and e2e build output blocked a plain worktree removal.
- **skills/factory-plan**: a task that changes an asserted shape owns the tests pinning the old shape — because ll-bkl and ll-rej each had to edit test files outside their lanes (declared, and judged correct by review). Expected effect: fewer `shared_files` entries.

Worked as designed, kept:
- The mailbox: the page builder told the QA tester how it implemented each handle before the tester's selectors were final; an ambiguous requirement (console errors) was raised by a builder, ruled on by the orchestrator, and relayed.
- Prerequisite flow: the key was asked for at the requirements gate, marked pending, gated in beads, built around with a fake, reported by the wiring builder under `needs_user`, and listed in the report under "Waiting on you".
- QA independence: the suite was written without reading the implementation and went 37/37 green when the wiring landed, with no edits to `e2e/`.

Cost note (one run, not acted on): the QA tester and the reviewer of its suite each built a throwaway reference implementation, about 12 minutes each. Worth it here; revisit if it recurs on larger epics.

Also in this pass: `koujou init` / `doctor` CLI, one-line installer, `/factory-setup`, and the living system design in `AGENTS.md`.

## 2026-11-19 — first run on a real project (a Next.js product with DynamoDB; four backlog issues as a pass)

Result: four issues built in parallel worktrees, 6 reviews, 2 bounces, validation passed in round 1; 111 → 144 tests; one real security bug found and fixed as a side effect of writing route tests. Nothing pushed; the user merges.

Earlier entries checked against this run:
- Review bounce and `fix_attempts` — **first evidence**: two tasks went back to their builders (one failed review, one sent back by the orchestrator) and both passed on the second review. The cap itself was not reached.
- Validator verdict rests on user-observable criteria — **confirmed** (a clean `pass`, with how-it-was-built criteria listed as checked elsewhere).
- A task that changes an asserted shape owns the tests pinning it — **confirmed** (the paging task's lane included the existing store test; no `shared_files`).
- Reviewer runs the real entry point — **confirmed** (two reviewers started a production build).
- `factory-adopt` improvements (prove the worktree recipe, run the gate twice) — **confirmed** by doing them: a fresh worktree passed the gate twice with its own table prefix before any builder started.

Changed:
- **skills/factory-run**: a run can be a *pass* (a labelled set of backlog issues across epics) — because the four issues belonged to three different epics and the skill only knew `--parent`.
- **skills/factory-run**: the orchestrator works in its own worktree cut from the remote base — because the user's checkout was 14 commits behind and a push to its base branch deploys. Expected effect: the user's checkout is never switched or dirtied by a run.
- **skills/factory-run**: on a shared tracker where the user merges, issues stay in progress with `factory:awaiting-merge` and writes use `--sandbox` — because closing them would have told a second person the work was live.
- **skills/factory-run**, **agents/factory-reviewer**: a production-only defect is blocking even if it cannot be reproduced locally, and the orchestrator reads suggestions before merging — because the first review of the session task passed with the real defect (a stale read after a write on real DynamoDB) filed as a suggestion. Expected effect: such findings arrive as `fail`.
- **agents/factory-reviewer**: when a test or helper changes, check what it used to prove — because a retrying test helper would have let a publisher that skips ticks pass; the reviewer caught it by mutation. Kept and made explicit.
- **skills/factory-run**: each worker gets its own scratch folder; the run cleans up worktrees, servers and test tables at the end — because two workers overwrote each other's `seed.ts`, and the run left 204 test tables in the local database.

Still no evidence: a merge conflict between task branches; the stuck path at the attempt cap; a deploy performed by the factory; `factory-spec` and `factory-design` on real work (this pass started from existing issues).
