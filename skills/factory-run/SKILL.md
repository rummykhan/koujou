---
name: factory-run
description: Factory stage 4 — the delivery loop. Orchestrates a swarm of builder agents in parallel git worktrees to build an epic's tasks, with independent review, a merge queue, a security review, black-box validation, bug triage and a capped fix loop, then hands over to factory-ship. Use when an epic (or single bead) is planned in beads and the user wants it built and shipped.
---

# Factory: delivery loop

You are the orchestrator. You do not write product code; you brief agents, check their reports against evidence, merge, record state in beads, and decide what happens next. You are the only writer of bead state and the only one who talks to the user.

```
        ┌──────────────────────────── per wave of ready tasks ─────────────────────────────┐
epic ──►│ claim → worktree → BUILD (parallel) → REVIEW → merge queue (one at a time) → close │──► more ready? ─┐
        └───────────▲──────────────────┬──────────────▲───────────┬──────────────────────────┘                │
                    └── fail, attempts < max ──┘      └─ rebase ──┘ (others rebase after each landing)        │
   ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   └─► SECURITY REVIEW (several agents) → START LOCALLY → VALIDATE → findings? → TRIAGE ─► fix now → back to waves
                                                                        │                  └► defer → later phase
                                                                        └─► none → report → SHIP (factory-ship)
```

Read first: `FACTORY.md`, and in `~/.claude/skills/factory/reference/`: `beads.md`, `swarm.md`, `blockers.md`. Limits (`max_fix_attempts`, `max_parallel_builders`, `max_rebases`, `max_fix_depth`, default 3 each; `max_agent_runs`) come from the profile.

Agents: use subagent types `factory-builder`, `factory-reviewer`, `factory-security`, `factory-tester`, `factory-validator`. If they are not available in this session, use a general-purpose agent and start its prompt with "Read `~/.claude/agents/factory/factory-<role>.md` and take that role." (Newly installed agent types only register when a session starts.)

## What a run works on

Usually one epic. When the work is picked from an existing backlog and spans several epics, it is a **pass**: label the chosen issues `factory:pass-<n>` (after `factory-plan` has given each its criteria, lane and dependencies), use `--label factory:pass-<n>` wherever this skill says `--parent <epic>`, and name the branch `factory/pass-<n>`. Leave the issues in the epics they belong to. A pass has no epic to carry the run's own state, so create a run record for it: one task labelled `factory:pass-<n>` and `factory:run` ("Factory pass <n> (run record)"), claimed at the start; wherever this skill stores something on the epic (`validate_rounds`, `security_at`, `validated_at`, `shipped_at`), store it there, and close it when the pass ships. A pass has had no requirements stage, so nobody has asked the user anything yet: it must come with an approved `intake.md` (written by `factory-plan`, "A pass from the backlog") before preflight.

## 0. Preflight

Stop and tell the user if any of these fails; a run started on a bad footing wastes every agent after it.

- The epic's plan was approved, `bd lint` is clean for its issues, and `bd swarm validate <epic>` reports it swarmable.
- Every task has acceptance criteria that each name a check, and an acceptance command in its metadata (`accept`). `koujou accept --parent <epic>` lists any task without one; fix the plan before starting, because that command is what closes the task.
- You have a checkout of your own to merge in. If the user is working in the main checkout, or the base branch deploys, leave theirs alone: `git fetch`, then add a worktree for the epic branch cut from the remote base (`git worktree add <worktree-root>/_epic -b factory/<epic-id> origin/<base>`), and orchestrate from there.
- The working tree is clean.
- Create the epic branch `factory/<epic-id>` from the up-to-date base (task branches are `factory-task/<task-id>`; git cannot hold a branch named inside another branch's name, so they must not nest) and run the gate on it. It must be green: this is the baseline that lets you attribute later failures.
- You know the deploy policy and the validation target.
- Prerequisites are settled: every row in the `## Prerequisites` table (in the requirements, or in a pass's `intake.md`) is `provided` (and verified), or sits behind a `factory:needs-user` gate, or is marked for the next pass. If you can see a need the table missed (the tasks mention a service nobody has credentials for), ask the user now, in one batch, before any agent starts.

Record the start: `bd update <epic> --claim --set-metadata validate_rounds=0`.

## Keeping time

Beads stamps `started_at` when an issue is first claimed and `closed_at` when it closes. The run adds the points in between as metadata, so the report and the retro can say where the time went. Stamp each as it happens, in UTC:

```bash
now() { date -u +%FT%TZ; }
bd update <task> --claim --set-metadata claimed_at=$(now)   # when this run takes the task (beads' own started_at may be an older claim)
bd update <task> --set-metadata built_at=$(now)        # the builder reported done (overwrite on a retry)
bd update <task> --set-metadata reviewed_at=$(now)     # the review passed
bd update <task> --set-metadata merged_at=$(now)       # it landed on the epic branch
bd update <task> --set-metadata agent_runs=<n>         # every agent spawned for it so far: builders, reviewers, re-runs
bd update <epic> --set-metadata validated_at=$(now)    # the last validation passed
```

`koujou times <epic-id>` (or `koujou times --label factory:pass-<n>`) prints the result per task and in total. Put its output in the report.

## 1. Build waves

Repeat until `bd ready --parent <epic> --exclude-type epic --json` returns nothing.

**a. Pick the wave.** Take the ready tasks, up to `max_parallel_builders`. Compare their lanes (the files each owns, in the `design` field), including against tasks still in flight. If two would change the same function or contract, keep one and leave the other for later; tasks that merely share a file run together and meet in the merge queue.

Waves roll: you do not wait for a whole wave to finish. Each time a task closes, check `bd ready` again and start whatever has become unblocked while there is a free builder slot.

**b. Prepare each task.**

```bash
bd update <task> --claim
git worktree add <worktree-root>/<task> -b factory-task/<task> factory/<epic>
```

`<worktree-root>` comes from the profile; default `../.factory-worktrees/<repo-name>`, outside the repo so the project's own tooling does not scan it.

The epic's QA task (label `qa`) is part of the first wave: it goes to a `factory-tester`, not a builder, with the requirements file and the profile's QA section in its brief. Its branch is reviewed and merged like any other. The suite describes the finished epic, so it stays red on the epic branch until the tasks it covers, usually ending with the wiring task, are merged: run the unit gate after each merge, and the full gate including the suite once they are all in. A suite test that still fails then is a bug to triage (step 4) before validation even starts. Where the project runs every test with one command, so the suite cannot be kept out of the gate, hold the QA branch in the merge queue after its review passes and land it last, after the tasks it covers: landed earlier, it turns the epic gate red for every branch behind it.

**c. Spawn the builders, all in one message** so they run in parallel. Each brief contains: the task id; the absolute worktree path and branch, with an instruction to work only there whatever directory its environment reports; the path to `FACTORY.md`; the path to the swarm protocol; one line per sibling in this wave (id, title, lane) so the builder knows who is nearby; a distinct port or database suffix if the project runs local services; a scratch folder of its own for throwaway scripts (workers share the machine's temp space, and one worker's `seed.ts` has overwritten another's); and on a retry, the reviewer's findings verbatim. Do not paste the task text; the builder reads it from beads. Count the spawn in the task's `agent_runs`.

**d. As each builder reports**, read the mailboxes of the tasks in flight (`bd comments <id>`) and act on anything addressed to you: relay an urgent message to a running builder, settle a contract question, or add a dependency.

- `blocked` → see *Stuck* below.
- `needs_user` is not empty → see *Waiting on the user* below. This can accompany `done`: the builder finished against a stand-in.
- `done` → stamp `built_at`, then spawn a `factory-reviewer` for that task with: task id, worktree path, branch, the diff command `git diff factory/<epic>...HEAD` (three dots, so it compares from where the branch was cut even after the epic branch has moved on), path to `FACTORY.md` and the requirements file. Give it the code, not the builder's report; it should form its own view. Every reviewer and security agent gets a scratch folder of its own in the brief, as builders do, and is told not to use any shared temp directory (two reviewers sharing the session's scratch directory overwrote each other's copy of the app mid-review). Add one line per sibling task in the same epic or pass (id and title): a defect one task is fixing in one place is often being introduced afresh by another (on the lab's pass 1, one task fixed a double-click that created two links while another added a Delete button with the same flaw, which only the validator caught). One exception to giving it only the code: if the builder rebased over landed siblings and resolved conflicts, name the conflicted files and the sibling tasks, so the reviewer also checks that the siblings' behaviour and tests survived there.

**e. On the reviewer's verdict.**

- **A second or later review is bounded.** Its brief lists what was sent back and asks whether each item is closed and whether the fix broke anything already verified. A new finding that breaks an acceptance criterion or harms users is still blocking; any other new finding goes under `follow_ups` and becomes its own bead. Never brief a builder or a reviewer to "sweep the whole class": that has no end, and on the first real pass it drove one task to its attempt cap over findings that were not in its criteria.
- **fail** → read `fix_attempts` from `bd show <task> --json`, add one, `bd update <task> --set-metadata fix_attempts=<n> --append-notes "review <n>: <one-line summary>"`. If `n` is below the cap, continue the same builder with the blocking findings (its context is still useful) or spawn a fresh one in the same worktree if it has gone in circles. Then review again. At the cap → *Stuck*, unless the only findings left are ones that break no acceptance criterion and harm no user (low-severity, or already present before the task): then file them as their own beads, land the task, and record in its notes and in the report that you set the reviewer's verdict aside and why. That is a judgement to use rarely and always in the open.
- **pass** → read the reviewer's suggestions before merging. A reviewer sometimes files a real defect as a suggestion because it could not reproduce it locally (behaviour that differs in production: consistency, limits, concurrency, scale). If a suggestion describes wrong behaviour for real users, send the task back as if it had failed; otherwise stamp `reviewed_at` and put the branch in the merge queue. If the reviewer answered `security_sensitive: yes` and no `factory-security` agent has seen this task, spawn one now (all lenses, this task's diff) and treat an introduced critical or high finding as a failed review. File the reviewer's `follow_ups` and the builder's `discovered` items as beads (see *Triage*).

**f. The merge queue: one branch lands at a time, the rest rebase.** Parallel branches are cut at different moments, so by the time a branch is ready the epic branch has usually moved. Land branches in the order their reviews passed:

```bash
cd <worktree-root>/<task> && git rebase factory/<epic>      # bring the branch onto the current epic branch
<gate>                                                      # in the task worktree, on the rebased branch
cd <epic worktree> && git merge --no-ff factory-task/<task> # now a fast, conflict-free merge
```

- **The rebase is clean** → run the gate on the rebased branch, then the task's own acceptance tests (`koujou accept <task>`, in its worktree). Both green → merge, stamp `merged_at`. Red → the branch and something that landed before it disagree without touching the same lines; send it back to its builder with the failing output and the commits that landed since it was cut. That is a fix attempt.
- **The rebase conflicts** → `git rebase --abort` and send the branch back to its builder: "rebase onto `factory/<epic>` (now at `<sha>`), resolve the conflicts keeping both changes' behaviour, run the gate". List the commits that landed and their tasks, so the builder can read what the other side intended and ask its author through the mailbox. When it reports back, a reviewer checks the resolution only (`git range-diff`, or the diff of the conflicted files against both parents) and that both tasks' criteria still hold in those files. Then it re-enters the queue at the front. Count it in `rebases` (metadata), not `fix_attempts`: a conflict is the plan's fault, not the builder's. At `max_rebases` → *Stuck*.
- **After every landing, tell the builders still in flight**: post to each one's mailbox `[from orchestrator] factory/<epic> is now at <sha>: <task> landed, touching <files>`. A builder rebases its own branch onto the epic branch before it reports done (the builder role allows exactly this rebase), so most conflicts are resolved by the agent that understands the change, before review, and the queue stays short.
- Never resolve a product-code conflict yourself. You may resolve mechanical ones in files nobody owns (a lockfile regenerated by the install command, two lines appended to the same list), and you say so in the task's notes.
- A conflict is evidence that two lanes overlapped. Note which files for the retro, and before starting the next wave check the lanes of what is still in flight against what just landed.

After a clean landing the epic branch has been gated with that task in it, so a red gate later points at the next landing, not at an unknown mix.

**g. Close** each merged task once the epic-branch gate is green:

```bash
bd close <task> --reason "<what shipped> | evidence: acceptance tests pass (`<accept command>`), reviewer verified N/N criteria, gate green at <sha> | residue: <follow-up ids or none>"
git worktree remove --force <worktree-root>/<task> && git branch -d factory-task/<task>   # --force: untracked build output is expected; the branch is already merged
```

Closing unblocks dependents, which form the next wave. If the project pushes the epic branch during the run (the profile's push policy says so), push after each landing so the remote always holds a gated branch; task branches are never pushed.

When the tracker is shared with people and the work only becomes real for them once the user merges the branch (the profile's integration is a pull request the user merges), don't close issues that are not on the base branch yet. Leave each in progress with the label `factory:awaiting-merge` and notes saying what was built and reviewed; tell the user to close them on merge. Make beads writes with `--sandbox` so nothing reaches the team's tracker until the user pushes it. Within the run, treat `factory:awaiting-merge` as done when deciding what is ready.

### Stuck

A task is stuck when it hits `max_fix_attempts` or `max_rebases`, when `koujou converge` names it, or when its builder reports a blocker it cannot pass (a deeper defect is not that: it is filed underneath and built first, see *The fix loop*). Don't spend a fourth attempt hoping; the pattern has shown it is not converging.

```bash
bd update <task> --add-label factory:stuck --append-notes "<what was tried, what fails, your read of why>"
bd gate create --blocks <task> --reason "<the decision or help needed>"
bd unclaim <task>
```

Leave its worktree in place for inspection. Carry on with every task that does not depend on it. Tell the user about stuck tasks when the waves run dry, or at once if nothing else can proceed.

### Waiting on the user

When a worker reports something only the user can provide, follow `blockers.md`: record it as a `factory:needs-user` bead with a gate that blocks exactly the work needing it, add it to the requirements' prerequisite table, and keep the factory running on everything else. If the worker built against a stand-in, its task can still be reviewed and merged; create a thin follow-up task for the real integration and put that behind the gate.

Interrupt the user at once only when the need is on the critical path. A need that will block the merge is raised at the next wave boundary, while building continues, never saved for the report. Otherwise collect needs and raise them together at the next natural stop: when the waves run dry, before deploy, or in the report. Where the factory can produce the thing and the user only has to approve it, bring the draft, already on the branch, instead of the question (`blockers.md`, "Bring a draft, not a question"). When the user provides something, verify it with the cheapest real call, `bd gate resolve <gate>`, close the prerequisite bead, and the blocked work returns to `bd ready`. Whatever is still gated when the epic is otherwise finished moves out as `factory:deferred` and is listed in the report under "Waiting on you".

## 2. Security review

When no ready tasks remain and nothing is in flight, the epic branch holds everything that passed review. Before anyone validates it, a security team reads the whole change. Task reviewers look at one task at a time against its criteria; nobody has yet asked how the assembled change could be misused, and on the first real project the one security defect found was found by accident.

Spawn `factory-security` agents **in one message**, one per lens, each with: its lens, the epic worktree path, the diff command `git diff origin/<base>...factory/<epic>`, the paths to `FACTORY.md` and the requirements, a scratch folder and a port of its own, and how to start the product locally.

| Lens | Looks at |
|---|---|
| `access` | sign-in, sessions, authorisation on every changed route, separation between users or tenants |
| `input` | injection, scripting, redirects, server-side requests, uploads, forgery, unbounded input |
| `exposure` | secrets, data returned or logged, headers and cookies, new dependencies, cryptography |

All three run by default. The profile's `Security review` line may narrow this (`off` for a project with nothing to protect; one agent covering all lenses for a change that is small and touches no route, session, input handling, dependency or config) or add project-specific lenses (payments, tenancy, a compliance rule). During the build waves, a task labelled `security` also gets one `factory-security` agent (all lenses, that task's diff) alongside its ordinary reviewer, so a hole in sensitive code is caught while its builder is still there.

Then handle the findings. Agents working alone over-report and occasionally invent, so check before acting:

- Read each finding's proof. An `observed` proof you re-run. A `reasoned` one you check against the code; if you cannot tell, ask a second `factory-security` agent to confirm or refute that one finding, giving it the finding but not the first agent's confidence.
- **Introduced, critical or high, confirmed** → fix now: a `bug` bead, child of the epic, P0 or P1, label `security`, with the attack as its steps to reproduce and "the attack no longer works, shown by a test" as a criterion. It goes through the build wave like any task, and the lens that found it re-checks the fix.
- **Introduced, medium or low**, and **anything pre-existing** → a `factory:deferred` bead with label `security`, listed in the report. A pre-existing critical or high finding is also told to the user at once: it is in production now. Tell it with the finding's `plain` account (who does what, in order, and what the victim loses), whether it was observed or reasoned, the options and your recommendation; the `attack` line is written for reviewers and a user cannot decide from it.
- **Refuted** → note it in the report with why.
- **A fix that would change a feature** (`changes_feature: yes`, or you can see it would: something removed, restricted, or a new step for legitimate users) → never built on the security review's word. Security closes holes; it does not redesign the product. First look for a fix that keeps the feature as specified. If there is none and the harm is serious (customer or company data, account takeover, money, integrity, customers' trust), it is the user's decision: a `decision` bead with a gate, told to them at once in plain words with what users would lose under each option. If the harm is less than that, the feature stays and the finding is deferred.

Write the result to `<work order>/security.md`: lenses run, what each covered and did not, findings with their fate. Stamp `security_at` on the epic. If fixes were needed, the security review counts as passed when the re-checks pass; it does not need a full second round unless the fixes were large.

## 2b. Start the validation target

The default target is **local**: build the product from the epic branch as the profile describes and start it, in production mode where the project has one, with its local services. Local validation needs no cloud account, costs nothing and can be as destructive as the validator likes, which is why it is the default even when the project has deployed environments.

If the profile names a deployed test environment as an additional target, it is exercised after the merge, by `factory-ship`. Nothing is pushed, merged or deployed in this skill.

## 3. Validate

First run the gate on the epic branch, acceptance suite included, against the build you are about to validate, and every task's acceptance command together (`koujou accept --parent <epic>`, or `--label factory:pass-<n>`): each passed alone when its branch landed, and this shows they all still pass on the assembled branch. Put the output in the report. Then spawn one `factory-validator` with: the epic id, the environment and how to reach it, sign-in or seed instructions from the profile, the path to the requirements file, the path to `FACTORY.md`, the tester's `manual_checks` list, the evidence directory (`<work order>/evidence/`), the profile's known gaps in the gate so it concentrates there, the gate result you just ran and the security review's result (so both count as checked elsewhere), and any open prerequisite whose absence makes a criterion uncheckable for now.

From the second round on, tell the validator which bugs were fixed since the last round: it re-runs their reproduction steps, re-checks the epic's success criteria and the requirement-level acceptance lines for regressions, and need not repeat task-level criteria that passed before and whose code has not changed.

Verdict `pass` → stamp `validated_at` and go to *Close the epic*. Otherwise triage.

## 4. Triage

For each bug the validator reported, and each discovered item from builders and reviewers, decide one of:

| Decision | When | Action |
|---|---|---|
| **Fix now** | It breaks a success or acceptance criterion, is a regression, or loses data | `bug` bead as a child of the epic, P0/P1, with the validator's steps and an acceptance line. It joins the next wave; brief its builder to reproduce the bug before changing anything. If the validator shows that a bug already fixed in this run still reproduces, do not file a second bead: reopen the first (`bd reopen <bug>`) and add one to its `reopened` metadata. |
| **Defer** | Real, but outside this epic's criteria; cosmetic; rare | `bug` or `task` bead with label `factory:deferred`, no parent, `discovered-from` link. Listed in the report for a later phase. |
| **Reject** | Not reproducible, or the product is right and the expectation was wrong | Note why in the report. If the requirement itself was ambiguous, that is a question for the user. |

Commands are in the beads reference. A `not verified` criterion is not a bug: either find a way to verify it or name it in the report as unverified.

### The fix loop

Fix-now bugs go back to step 1 as ready tasks; then rebuild, restart and validate again. A fix that touches what a security lens covers goes back to that lens first. From the second round on the validator re-runs the fixed bugs' steps, whatever those fixes touched, and the epic's success criteria, not everything.

**Bugs stack.** A builder sent to fix a bug sometimes finds that it cannot be fixed where it shows: the cause is a deeper defect, in another lane or larger than the bug. It reports `status: blocked` with `blocked_by`. File that defect as its own `bug` bead, child of the epic, and put it underneath the first: `bd dep add <bug> <deeper bug>`. The first bug leaves `bd ready`; the deeper one is built, reviewed and landed; closing it brings the first back to the top, and its builder continues. The same holds one level further down. Nothing here needs a counter: the dependency graph is the stack, and `bd ready` is its top.

**How long the loop may run** is decided by whether it is getting anywhere, not by a number of rounds. An epic with twelve tasks may need five rounds and be healthy throughout; an epic that fixes one bug and gets one back is in trouble at round two. After each triage:

```bash
koujou converge <epic> --record      # or: --label factory:pass-<n>; add --sandbox where the run's writes use it
```

It reads the run from beads and prints what to do:

| It says | Because | You do |
|---|---|---|
| `continue` | Bugs are closing: fewer are open than a round ago, or this is an early round | Next wave. |
| `stuck <bug>` | That bug's fix has failed validation twice (`reopened`), or fixing it has uncovered a chain of bugs deeper than `max_fix_depth` | Mark that bug stuck (*Stuck*, above) with the chain in its notes. Everything else carries on. |
| `stop: no progress` | Two rounds running have not brought the number of open fix-now bugs down | Stop the loop. |
| `stop: budget` | The run has used more agents than `max_agent_runs` (default: twelve per planned task, at least thirty) | Stop the loop. |
| `stop: every open bug is stuck` | Nothing is left that can be built | Report as partially delivered. |

On a `stop`, the loop is not converging, which usually means a requirement or design problem that more fixing will not solve. Gate the epic (`bd gate create --blocks <epic> --reason ...`) and bring the user the pattern you see in the failures: which criterion keeps failing, what each fix changed, and what you think is actually wrong. The budget is a backstop against a loop the other signs missed; if the run is plainly converging when it trips, say so and ask for more rather than treating it as a failure.

## 5. Report and ship

Only when every child is closed (or `factory:awaiting-merge`), the security review passed and the last validation passed:

- Update the System design in `AGENTS.md` to match what is now built (`~/.claude/skills/factory/reference/agents-template.md`): the sections this epic changed, the commit stamp, and the epic removed from "In progress". Commit it on the epic branch so the design and the code land together.
- Update the other docs the profile requires in the same change (roadmap, decision log, pitfalls learned during the run).
- Write `report.md` in the work order: what shipped by requirement; evidence (gate result, security review result, validator verdict, commit, evidence files); time (the output of `koujou times`: per task, build, review and queue time, attempts, agents; and the run's total); **waiting on you** (open `factory:needs-user` items: what is needed, where to put it, what it unblocks); deferred items with ids; stuck items; rounds used; anything built against a fake; anything not verified.
- Clean up what the run created on the machine: task worktrees and branches, servers you started, and test databases or tables made for the run. Leave the epic branch and its worktree: shipping needs them.
- Run `factory-ship`: it pushes the branch, opens the pull request, waits for CI, merges with the user's approval, checks the deploy, and closes the issues and the epic. How far it goes without asking is the profile's git policy. Where there is no remote and the profile lets the factory merge locally, it does that and closes the epic: `bd close <epic> --reason "<summary> | evidence: validator pass at <sha> | residue: <deferred ids>"`.

If stuck tasks remain, the epic stays open. Report it as partially delivered with exactly what is and is not in the branch.

## 6. Retro

Run `factory-retro` for the epic, whether it shipped or stopped; it need not wait for the user to approve the merge. A stopped run usually has more to teach.

## Reporting to the user

Lead with the outcome in one sentence: shipped, partially shipped, or stopped. Then every open ask, one numbered list, each written so it can be answered in a line and each with your recommendation. Then, briefly, what was not verified and any decision you took that they might reverse. Everything else (what was built, evidence, times, deferred items) is in `report.md`; link it rather than repeat it. A report that needs scrolling to find the asks has buried them. State failures as plainly as successes; a validation that could not run is reported as not run.

If the run now stops for those answers, `koujou wait <epic or run record> start`.

## Resuming

All state is in beads and git, so a run can be picked up in a new session: `bd show <epic> --json` for the round counter, `bd list --parent <epic> --status in_progress` for tasks that were in flight (check their worktrees and mailboxes, then re-review or re-brief), `bd gate list` for what is waiting on the user, and `bd list --label factory:awaiting-merge` for work that is built and waiting to ship (`factory-ship`).
