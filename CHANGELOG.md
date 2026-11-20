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
