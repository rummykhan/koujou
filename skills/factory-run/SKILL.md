---
name: factory-run
description: Factory stage 4 — the delivery loop. Orchestrates a swarm of builder agents in parallel git worktrees to build an epic's tasks, with independent review, serial merge, deploy, black-box validation, bug triage and a capped fix loop. Use when an epic (or single bead) is planned in beads and the user wants it built and shipped.
---

# Factory: delivery loop

You are the orchestrator. You do not write product code; you brief agents, check their reports against evidence, merge, record state in beads, and decide what happens next. You are the only writer of bead state and the only one who talks to the user.

```
        ┌────────────────────────── per wave of ready tasks ──────────────────────────┐
epic ──►│ claim → worktree → BUILD (parallel) → REVIEW → merge (serial) → gate → close │──► more ready? ─┐
        └───────────▲──────────────────┬───────────────────────────────────────────────┘                │
                    └── fail, attempts < max ──┘   (attempts = max → stuck, gate for user)              │
   ┌────────────────────────────────────────────────────────────────────────────────────────────────────┘
   └─► DEPLOY (per policy) → VALIDATE → bugs? → TRIAGE ─► fix now → back to waves (rounds < max)
                                          │                └► defer → logged for a later phase
                                          └─► none → close epic → report
```

Read first: `FACTORY.md`, and in `~/.claude/skills/factory/reference/`: `beads.md`, `swarm.md`, `blockers.md`. Limits (`max_fix_attempts`, `max_validate_rounds`, `max_parallel_builders`) come from the profile; default 3 each.

Agents: use subagent types `factory-builder`, `factory-reviewer`, `factory-tester`, `factory-validator`. If they are not available in this session, use a general-purpose agent and start its prompt with "Read `~/.claude/agents/factory/factory-<role>.md` and take that role." (Newly installed agent types only register when a session starts.)

## 0. Preflight

Stop and tell the user if any of these fails; a run started on a bad footing wastes every agent after it.

- The epic's plan was approved, `bd lint` is clean for its issues, and `bd swarm validate <epic>` reports it swarmable.
- The working tree is clean and you are on the base branch from the profile.
- Create the epic branch `factory/<epic-id>` from base (task branches are `factory-task/<task-id>`; git cannot hold a branch named inside another branch's name, so they must not nest) and run the gate on it. It must be green: this is the baseline that lets you attribute later failures.
- You know the deploy policy and the validation target.
- Prerequisites are settled: every row in the requirements' `## Prerequisites` table is `provided` (and verified), or sits behind a `factory:needs-user` gate, or is marked for the next pass. If you can see a need the table missed (the tasks mention a service nobody has credentials for), ask the user now, in one batch, before any agent starts.

Record the start: `bd update <epic> --claim --set-metadata validate_rounds=0`.

## 1. Build waves

Repeat until `bd ready --parent <epic> --exclude-type epic --json` returns nothing.

**a. Pick the wave.** Take the ready tasks, up to `max_parallel_builders`. Compare their lanes (the files each owns, in the `design` field), including against tasks still in flight. If two overlap, keep one and leave the other for later.

Waves roll: you do not wait for a whole wave to finish. Each time a task closes, check `bd ready` again and start whatever has become unblocked while there is a free builder slot.

**b. Prepare each task.**

```bash
bd update <task> --claim
git worktree add <worktree-root>/<task> -b factory-task/<task> factory/<epic>
```

`<worktree-root>` comes from the profile; default `../.factory-worktrees/<repo-name>`, outside the repo so the project's own tooling does not scan it.

The epic's QA task (label `qa`) is part of the first wave: it goes to a `factory-tester`, not a builder, with the requirements file and the profile's QA section in its brief. Its branch is reviewed and merged like any other; from then on the acceptance suite is part of the gate you run on the epic branch, and a suite test that still fails once all tasks are merged is a bug to triage (step 4) before validation even starts.

**c. Spawn the builders, all in one message** so they run in parallel. Each brief contains: the task id; the absolute worktree path and branch, with an instruction to work only there whatever directory its environment reports; the path to `FACTORY.md`; the path to the swarm protocol; one line per sibling in this wave (id, title, lane) so the builder knows who is nearby; a distinct port or database suffix if the project runs local services; and on a retry, the reviewer's findings verbatim. Do not paste the task text; the builder reads it from beads.

**d. As each builder reports**, read the mailboxes of the tasks in flight (`bd comments <id>`) and act on anything addressed to you: relay an urgent message to a running builder, settle a contract question, or add a dependency.

- `blocked` → see *Stuck* below.
- `needs_user` is not empty → see *Waiting on the user* below. This can accompany `done`: the builder finished against a stand-in.
- `done` → spawn a `factory-reviewer` for that task with: task id, worktree path, branch, the diff command `git diff factory/<epic>...HEAD` (three dots, so it compares from where the branch was cut even after the epic branch has moved on), path to `FACTORY.md` and the requirements file. Give it the code, not the builder's report; it should form its own view.

**e. On the reviewer's verdict.**

- **fail** → read `fix_attempts` from `bd show <task> --json`, add one, `bd update <task> --set-metadata fix_attempts=<n> --append-notes "review <n>: <one-line summary>"`. If `n` is below the cap, continue the same builder with the blocking findings (its context is still useful) or spawn a fresh one in the same worktree if it has gone in circles. Then review again. At the cap → *Stuck*.
- **pass** → merge. File the reviewer's `follow_ups` and the builder's `discovered` items as beads (see *Triage*).

**f. Merge, one branch at a time.**

```bash
git checkout factory/<epic> && git merge --no-ff factory-task/<task>
```

A conflict means the branch goes back to its builder to rebase onto the current epic branch, counted as a fix attempt; abort the merge first. After a clean merge, when the wave's merges are in, run the gate on the epic branch. If it fails, the last merges interacted badly: find which, and send that task back with the failure.

**g. Close** each merged task once the epic-branch gate is green:

```bash
bd close <task> --reason "<what shipped> | evidence: reviewer verified N/N criteria, gate green at <sha> | residue: <follow-up ids or none>"
git worktree remove <worktree-root>/<task> && git branch -d factory-task/<task>
```

Closing unblocks dependents, which form the next wave.

### Stuck

A task is stuck when it hits `max_fix_attempts` or its builder reports a blocker it cannot pass. Don't spend a fourth attempt hoping; the pattern has shown it is not converging.

```bash
bd update <task> --add-label factory:stuck --append-notes "<what was tried, what fails, your read of why>"
bd gate create --blocks <task> --reason "<the decision or help needed>"
bd unclaim <task>
```

Leave its worktree in place for inspection. Carry on with every task that does not depend on it. Tell the user about stuck tasks when the waves run dry, or at once if nothing else can proceed.

### Waiting on the user

When a worker reports something only the user can provide, follow `blockers.md`: record it as a `factory:needs-user` bead with a gate that blocks exactly the work needing it, add it to the requirements' prerequisite table, and keep the factory running on everything else. If the worker built against a stand-in, its task can still be reviewed and merged; create a thin follow-up task for the real integration and put that behind the gate.

Interrupt the user at once only when the need is on the critical path. Otherwise collect needs and raise them together at the next natural stop: when the waves run dry, before deploy, or in the report. When the user provides something, verify it with the cheapest real call, `bd gate resolve <gate>`, close the prerequisite bead, and the blocked work returns to `bd ready`. Whatever is still gated when the epic is otherwise finished moves out as `factory:deferred` and is listed in the report under "Waiting on you".

## 2. Deploy

When no ready tasks remain and nothing is in flight, the epic branch holds everything that passed. Follow the profile's deploy policy to the letter.

- Validation target is local → build and start the product from the epic branch as the profile describes.
- Deploying to a shared or production environment → this needs the user's go-ahead each time unless the profile records standing permission for that environment. Present what will ship (tasks closed, gate result, anything stuck) and wait.
- Integration is by PR → push the epic branch and open the PR only if the git policy lets the factory push; otherwise hand the user the branch.

After a deploy, run the profile's smoke command and check the result yourself.

## 3. Validate

First run the gate on the epic branch, acceptance suite included, against the build you are about to validate. Then spawn one `factory-validator` with: the epic id, the environment and how to reach it, sign-in or seed instructions from the profile, the path to the requirements file, the path to `FACTORY.md`, the tester's `manual_checks` list, the evidence directory (`<work order>/evidence/`), and the profile's known gaps in the gate so it concentrates there.

From the second round on, tell the validator which bugs were fixed since the last round: it re-runs their reproduction steps, re-checks the epic's success criteria and the requirement-level acceptance lines for regressions, and need not repeat task-level criteria that passed before and whose code has not changed.

Verdict `pass` → go to *Close the epic*. Otherwise triage.

## 4. Triage

For each bug the validator reported, and each discovered item from builders and reviewers, decide one of:

| Decision | When | Action |
|---|---|---|
| **Fix now** | It breaks a success or acceptance criterion, is a regression, or loses data | `bug` bead as a child of the epic, P0/P1, with the validator's steps and an acceptance line. It joins the next wave; brief its builder to reproduce the bug before changing anything. |
| **Defer** | Real, but outside this epic's criteria; cosmetic; rare | `bug` or `task` bead with label `factory:deferred`, no parent, `discovered-from` link. Listed in the report for a later phase. |
| **Reject** | Not reproducible, or the product is right and the expectation was wrong | Note why in the report. If the requirement itself was ambiguous, that is a question for the user. |

Commands are in the beads reference. A `not verified` criterion is not a bug: either find a way to verify it or name it in the report as unverified.

If anything is fix-now: read the epic's `validate_rounds`, add one, store it. Below `max_validate_rounds` → return to step 1 (the bugs are ready tasks now), then deploy and validate again. At the cap → stop. The loop is not converging, which usually means a requirement or design problem that more fixing will not solve. Gate the epic (`bd gate create --blocks <epic> --reason ...`) and bring the user the pattern you see in the failures.

## 5. Close the epic

Only when every child is closed and the last validation passed:

- Update the System design in `AGENTS.md` to match what is now built (`~/.claude/skills/factory/reference/agents-template.md`): the sections this epic changed, the commit stamp, and the epic removed from "In progress". Commit it on the epic branch so the design and the code land together.
- Update the other docs the profile requires in the same change (roadmap, decision log, pitfalls learned during the run).
- Write `report.md` in the work order: what shipped by requirement; evidence (gate result, validator verdict, commit, evidence files); **waiting on you** (open `factory:needs-user` items: what is needed, where to put it, what it unblocks); deferred items with ids; stuck items; rounds used; anything built against a fake; anything not verified.
- `bd epic close-eligible` or `bd close <epic> --reason "<summary> | evidence: validator pass at <sha> | residue: <deferred ids>"`.
- Hand over per the git policy: PR, or the branch name for the user to merge.

If stuck tasks remain, the epic stays open. Report it as partially delivered with exactly what is and is not in the branch.

## 6. Retro

Run `factory-retro` for the epic, whether it shipped or stopped. A stopped run usually has more to teach.

## Reporting to the user

Lead with the outcome: shipped, partially shipped, or stopped, and what you need from them (every open ask in one list). Then what was verified and how, what was deferred, and what is stuck. State failures as plainly as successes; a validation that could not run is reported as not run.

## Resuming

All state is in beads and git, so a run can be picked up in a new session: `bd show <epic> --json` for the round counter, `bd list --parent <epic> --status in_progress` for tasks that were in flight (check their worktrees and mailboxes, then re-review or re-brief), `bd gate list` for what is waiting on the user.
