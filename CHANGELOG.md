# Factory changelog

Changes the factory made to itself, each tied to the run that taught it. `factory-retro` appends here and checks earlier entries' expected effects against later runs.

## 2026-11-27 — one gate, merge when mergeable, a live board, never idle

The owner: the factory should take the work once and ship it. "Plan mean initial plan: vision/requirements, design, plan and go"; "it should PR and once PR is mergable merge it, it shouldn't care where it's going"; and a board instead of "continue / where are we / resume".

- **skills/factory, factory-spec, factory-design, factory-plan**: one human gate, the plan: spec, design and plan run back to back and the user approves the three together. No gate for Direct, lane S, or small work an existing pattern settles. Expected effect: one approval per epic.
- **skills/factory-ship, profile template, the three projects' FACTORY.md**: merge as soon as the pull request is mergeable, wherever it deploys; the plan gate is the approval. Stamps `pr_merged_at` and `deployed_at` on each issue. Expected effect: no merge waits on the user.
- **koujou-ui** (new repo, github.com/rummykhan/koujou-ui): a live kanban of every project (Backlog, Active, In progress, Code review, Merged, Deployed, Closed) with live agents, budget and asks; projects added from the workspace in the page; always running as a login service; a terminal view. `koujou board` delegates to it; `koujou init` puts the project on it. Expected effect: the user never asks where things stand.
- **skills/factory-run**: never end a turn with work pending unless a background watcher or timed check-back will wake the session; push-notify the user when the run needs them or ships. Expected effect: no "continue" or "resume" from the user.

## 2026-11-27 — speed, accuracy and automation from the shukka/Orbitary session

- **skills/factory (Sizing)**: a **Direct** lane for work whose time goes to live cycles (deploys, migrations, recoveries, few-line fixes): the session does it itself, no factory stages. Because every switch-over defect was a one-line fix behind a 10–20 min deploy, and routing each through a builder cost an agent per cycle. Expected effect: ops work is never planned as an epic.
- **bin/koujou-accept.py, factory-run, factory-builder**: `koujou accept --red <task> --base <ref>` takes the task's code back to the base, keeps its tests, and requires them to fail (and to have run). It replaces the per-task reviewer's hollow-test catch that the lean loop dropped, without an agent. Expected effect: no task lands with tests that pass without its change.
- **bin/koujou-spawned.py, koujou-ready.py, koujou reported**: `--role` tracks each live agent against its time box (builder 60, reviewer 30, epic review 45, validator 60, scout 20, security 30); `ready` and `status` flag any agent OVER BOX, not only builders. Because reviewers sat 12 h unwatched on shukka v1. Expected effect: no agent runs past twice its box unnoticed.
- **bin/koujou-status.py**: `koujou status`, one screen: runs, budget, live agents, asks, stuck, processes left in task worktrees, keep-awake. Because the owner asked "where are we" about ten times in one session. Expected effect: status answered with one command.
- **factory-run**: cleanup kills processes left in task worktrees (a builder's `cat` held its agent 63 h); every git command of the run stays out of the user's checkout (the orchestrator ran `git checkout -B` in the owner's Orbitary checkout).
- **factory-ship**: the post-deploy check must prove this change is what serves, not only 200 (Orbitary's deploy reported success while Caddy served the old config).
- **Projects**: lessons added to Trendigle, Orbitary and shukka `FACTORY.md` (hook subshell, reload on a serving box, smoke marker, lightweight tags, migration recovery).

## 2026-11-27 — a builder's stray shell

- **agents/factory-builder**: no command that waits on stdin or outlives the builder; probes get a `timeout`. Because shu-ph3's builder ran `cat > probe.sh` with no input, and the shell held the agent open for 63 hours after it reported done. Expected effect: no builder shell left running after its report.

## 2026-11-26 — lean by default, inside an enforced budget

The owner: the factory solved "the agent waits on me after every step" but not "faster than I would by hand". The numbers agree: shukka v1 took 61 h and 135 agents; shu-cio, run lean by the orchestrator's judgement, took 3.5 h and 10. The earlier lessons were prose nobody had to follow, and nothing measured whether a run beat working by hand.

- **skills/factory-run**: lean is the rule: at most three builders; the orchestrator checks each task (acceptance command, gate, diff) instead of a per-task reviewer, which only `security`/`review`-labelled tasks get; one independent review of the assembled epic, its findings fixed in one batch; a round's fix-now bugs built together; small fixes made by the orchestrator without an agent. Expected effect: agents per task near 2, not 4–5.
- **bin/koujou-budget.py, koujou spawned, koujou converge**: every run has a budget of agents (three per planned task, at least ten) and working hours (one per task, at least four, less time waiting on the user), from FACTORY.md or the epic's `agent_budget`/`time_budget_h`; `koujou spawned` checks it after every count and exits 3 when over, and the orchestrator must ask the user before the next agent. The old backstop was twelve agents per task. Expected effect: no run passes its budget without the user deciding it should.
- **skills/factory-plan**: few, larger tasks (lane M: two to five); no QA task unless lane L flows cross slices; the walking skeleton is the first task, not a suggestion; passes of three issues or fewer get no scouts. Expected effect: fewer tasks and agents per epic, the first live run in the first hour.
- **skills/factory-retro**: `retro.md` opens with a Speed table (agents and hours against budget, an estimate by hand, which won) carried across runs; changes that remove an agent are preferred to ones that add a check. Expected effect: every retro states whether the factory beat working by hand, and the trend is visible.
- **agents/factory-builder, skills/factory, README, profile template**: say who checks the work now, and the budget.

## 2026-11-25 — shukka v1 and the Trendigle switch-over: lessons on time

shukka v1 took 42 h from first claim to last landing and 135 agents, then the production switch-over needed three more shukka releases (v1.0.1–v1.0.3). The owner: "it took way long". Where the time went, beyond the security loop already removed: nine live acceptance candidates at 1.5–2 h each, found one or a few defects at a time, about half in the acceptance suite itself (never run live until the end); a release path the OIDC spike never exercised (annotated tags); four migration defects only the real consumer could show; one-line fixes routed through full review rounds; and a laptop that slept through two runs.

- **skills/factory-plan**: a walking skeleton run live in the first wave when proof needs an outside system; the QA suite runs live early; spikes exercise the exact production path; adoption by an existing system gets a rehearsal on its real shape. Expected effect: the first live run happens in the first hours, and the last live runs find nothing new.
- **skills/factory-run**: small fixes go small (orchestrator reads the diff, runs the gate, says so); a slow validation run is fully triaged and all its failures fixed in parallel before the next run. Expected effect: no more than two or three slow validation runs per epic.

## 2026-11-24 — shukka v1 (shu-9bj): keep the machine awake

The shukka v1 acceptance run on rc.8 lost two cases, and the rc.9 attempt never started, because the laptop slept: a closed lid for four hours, then an overnight sleep that left GitHub unreachable and turned four gate tests into timeouts. The suite's own `caffeinate` fixed it for that project; the owner asked for it in the factory.

- **bin/koujou, skills/factory-run, README**: `koujou awake start|stop|status` keeps the machine awake (macOS `caffeinate -dimsu`, Linux `systemd-inhibit`, capped at 12 h) and warns when on battery, where a closed lid still sleeps the machine; factory-run starts it at preflight and stops it after the report. Expected effect: no run fails or stalls because the machine slept.

## 2026-11-22 — shukka v1 (shu-9bj): security review out of the loop

The run took 18 h from first claim to last landing for 24 tasks, most of which built and reviewed in 5–50 minutes. Almost all the overrun was the security loop: epic-level lens agents ran 13–16 h each building live Docker and tar proofs; the end-of-epic review found 8 problems after everything had landed, each became a task with builder, reviewer and security re-check, and one of them (shu-9bj.8) spent 13 h across three re-checks. The orchestrator waited on silent reviewers and re-checks because the quiet check only watched builders. 120 agents in all. The owner: "I can do much faster without this loop".

Applied at the owner's request:
- **skills/factory-run, skills/factory, factory-ship, factory-retro, factory-plan, agents/factory-reviewer, README, flow diagram**: no security review in the delivery loop: no per-task security read, no epic security stage, no security condition on report or ship. The `security` label only marks where an on-demand review should look. Expected effect: an epic of shukka's size finishes in the time its build waves take (a few hours), with agent counts near 4 per task.
- **skills/factory-security-review (new)**: the same three-lens review, run only when the user asks, on any branch or pull request; each agent time-boxed to 30 minutes, after which unproven findings are reported as reasoned; findings become beads (critical/high told to the user at once) and fixes go through factory-run as ordinary tasks. Expected effect: a security review costs under an hour of wall clock and never blocks a merge unless the user says so.
- **skills/factory-run**: every agent brief carries a time box (reviewer 30 min, builder and validator 60); reviewers and the validator are checked against it at each landing, since `koujou ready` sees builders only. Expected effect: no agent runs hours past its box unnoticed.
- **tests/static/check.py, demo-todo**: the roster check allows factory-security to live only in the on-demand skill; the demo expects no security.md.

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

## 2026-11-20 — changes asked for after the first real run, then lab run 4 (linklab, a six-issue backlog pass with lanes overlapped on purpose)

Changed before the run, at the user's request or from gaps the first real run left:
- **skills/factory-ship (new)**, **profile-template**: the factory ships. Push the branch, open the pull request, wait for CI, merge with the user's approval (or standing permission), watch the deploy, close the `factory:awaiting-merge` issues, sync the tracker, clean up — because the first real run ended with an unpushed branch in a hidden worktree and three chores for the user. Validation stays on a local build by default; a deployed test environment is optional and exercised after the merge.
- **agents/factory-security (new)**, **skills/factory-run §2**: a security team reads the assembled change before validation, one agent per lens (access, input, exposure), in parallel; a task labelled `security` also gets one during the build — because the only security defect on the first real run was found by accident, by a task that happened to write tests for the route.
- **skills/factory-run §1f**, **reference/swarm.md §5**, **agents/factory-builder**: a merge queue. One branch lands at a time, rebased and gated first; the orchestrator tells in-flight builders when the epic branch moves; a builder rebases its own branch before reporting done and resolves its own conflicts; a conflict sent back from the queue is counted in `rebases`, not `fix_attempts`, and its resolution is reviewed on its own — the user asked for agents that expect conflicts and settle them one by one.
- **skills/factory-plan ("A pass from the backlog")**, **reference/blockers.md**: a backlog pass gets an intake: one read-only scout per issue, then `intake.md` with prerequisites, decisions with defaults, questions with no default (security, money, promises to users), and what cannot be verified locally — because the first pass skipped the "ask once, up front" sweep, and three decisions reached the user after the code was written.
- **skills/factory-run ("Keeping time")**, **bin/koujou times**: build, review and landing times and the number of agents are stamped in beads metadata; `koujou times` adds them up for the report and the retro.

Lab run 4, what the evidence said:
- **Intake scouts — worked.** Six scouts (15 to 28 s each) turned up two security decisions with no safe default (who may delete; URLs carrying credentials), one of which kept an issue out of the pass behind a gate, plus six choices that were taken as stated defaults. No question reached the user after the build.
- **Merge queue — worked, three ways.** One branch conflicted in the queue and went back to its builder, who resolved it in 34 s; a 32 s resolution-only review confirmed nothing was dropped. A second builder read the "branch moved" messages in its mailbox, rebased itself twice and resolved five conflicts before review ever saw it. Three branches rebased clean. No conflict needed the orchestrator's hands.
- **Security review — earned its place.** The task-level security agent found that the new Delete button could be clicked through an invisible frame, with a working exploit, on a branch the ordinary reviewer had just passed. It was fixed and re-verified (the exploit and six variants fail). Four lesser findings were logged. The three-lens review of the assembled change then found nothing new.
- **Validation and the fix loop.** Every criterion passed; the validator still found a data-loss bug (a human-speed double click on Delete removed two links). It went through the loop as a fix-now bug and round 2 re-checked it.
- **Times.** `koujou times` showed the pass's build waves took 10 m 25 s for five tasks with 19 agent runs, and where the time went (the security bounce and two rebases on the largest task).

Changed because of the run:
- **bin/koujou accept (new)**, **skills/factory-plan**, **agents/factory-builder**, **agents/factory-reviewer**, **skills/factory-run**: acceptance tests close tasks (the user's idea, during the run). Every acceptance line names its check (`test:`, `run:`, `manual:`); the task's tests carry the task id; the task stores one acceptance command (`accept` metadata) that the builder, the reviewer, the landing step and the pre-ship check all run with `koujou accept`. The runner fails a command whose output never mentions the task id — because the first version reported `pass` for a name filter that matched no tests. Tried on the fix-now bug: red with "No tests found" before the fix, 7 tests green after, and the reviewer confirmed 3 of them fail with the fix reverted.
- **skills/factory-run**: a pass has no epic to hold run-level state, so it gets a run record (a task labelled `factory:run`) — found when there was nowhere to stamp `security_at`.
- **skills/factory-run**, **agents/factory-reviewer**: the reviewer is told its sibling tasks and asked whether this change adds a fresh instance of a defect a sibling is fixing — because one task fixed "double click creates two links" while another shipped a Delete button with the same flaw, and only the validator caught it.
- **skills/factory-run**: a reviewer of a branch its builder rebased over conflicts is told which files and siblings, so it checks that the siblings' work survived.
- **agents/factory-validator**: test a double click as two clicks 80 to 300 ms apart, not only the tool's instant double click (the instant one missed the bug); never bind a port outside the ones assigned (the validator put a server on port 80 as an experiment).

Still no evidence: the stuck path at the attempt cap (`fix_attempts` or `rebases`); a conflict the two builders could not both satisfy; `factory-spec` and `factory-design` on real work; a deploy and deployed validation.
- **skills/factory-ship**: exercised end to end on the lab project against a private GitHub repository: push, pull request, a CI run, merge under the profile's standing permission, issues closed with the merge commit, worktrees and branches removed. No change needed.

Added after the run, at the user's request:
- **tests/** and **.claude/skills/factory-test**: the factory is tested before it is pushed. Tier 0 checks the prose against itself (names, files, labels, limits and commands that one file uses and another must define); tier 1 runs the CLI against real beads; tier 2 puts one worker in a prepared situation with a planted defect and judges the outcome (six scenarios, each detector paired with a control); tier 3 is a full demo on a to-do app. `tests/README.md` is the contributor guide. First results: all six module scenarios passed on their first run; tier 0 found two inconsistencies (an undocumented label, a worker missing from the roster check's view) and tier 1 found that the README's "`koujou init` commits nothing" was untrue (beads commits its own files), all fixed. CI then found that the installer's npm route can report success and leave no working `bd` on Linux; `install.sh` now tries each method until `bd` runs, and CI installs with the real installer.
- **Demo run (tests/scenarios/demo-todo)**: one run, 20 of 20 assertions passed. Requirements, a four-task plan with acceptance commands (all red before the build), three builders and a tester in parallel, 5 reviews, one conflict in the merge queue resolved by its builder, 4 security reviews, one validation, local ship. 17 agent runs; 7 m 54 s from first claim to validated. Nothing bounced, so the demo does not exercise the fix loop.
- **skills/factory-plan**, **reference/swarm.md**, **skills/factory-run**: tasks that only share a file, each adding its own piece, may run in parallel and meet in the merge queue; a dependency is needed only when two tasks would change the same function, block or contract — because builders resolved seven such conflicts across the lab pass and the demo without help, and the old rule would have serialised both runs. Expected effect: wider waves with no rise in stuck tasks; watch `rebases` in `koujou times`.

## 2026-11-20 — second run on the real project (a six-issue backlog pass through the full new pipeline)

Result: six issues, a flaky-test fix and one security fix found on the way; 243 tests (144 before); pull request opened with CI. 58 agent runs; build waves 1 h 19 m, about 1 h 30 m from first claim to validated. Review verdicts: 5 of 8 tasks bounced at least once. Not merged by the factory: three items needed the owner first.

Earlier entries checked against this run:
- Pass intake with a scout per issue — **confirmed on real work**: four questions with no safe default were asked before any code; the owner's answers (IP-only rate limit, pause on disconnect) differed from the recommendation twice, which is the point of asking.
- Security agent per `security` task, three lenses on the assembled change — **confirmed, strongly**: task-level agents found a limiter that a burst defeated, a stale read that could publish old content, a stolen-cookie race already in production and a token that survived a disconnect; the assembled-change lenses found a pre-existing way to stop the production server with one request (fixed in the pass) and nothing introduced at critical or high. A second pre-existing high finding was reported to the owner at once, as the skill says.
- Merge queue with builders rebasing themselves — **confirmed**: eight landings, three tasks sharing one store file, no conflict reached the queue and none was resolved by the orchestrator.
- Acceptance commands from the plan — **confirmed**: all eight red before the build and green at landing and on the assembled branch. One was wrong as written (it passed for the wrong reason in a worktree with no env file); the builder said so.
- Production-only defects are blocking — **confirmed**: two reviewers failed a task for a defect DynamoDB Local cannot show.
- The attempt cap — **first evidence**: one task reached its third failed review. See the first change below.

Changed:
- **skills/factory-run**: a second or later review is bounded to what was sent back; "sweep the whole class" is ruled out; at the cap, findings that break no criterion and harm no user may be filed separately and the task landed, on the record — because the orchestrator's own instruction to sweep a class of input checks drove a task to its cap on findings outside its criteria. Expected effect: no task reaches the cap for reasons its criteria do not contain.
- **skills/factory-run**, **agents/factory-reviewer**, **agents/factory-security**: every reviewer and security agent gets its own scratch folder — because two reviewers shared the session's scratch directory and one overwrote files in the other's copy of the app mid-review.
- **agents/factory-reviewer**: run new or changed tests several times, alone and in the full suite — because a landed test passed its review and its landing gate and then failed one run in four on other branches.
- **skills/factory-plan**, **reference/blockers.md**: scouts and the prerequisite sweep ask what the change needs created in production that the normal deploy does not create — because a new table reached the pull request before anyone noticed that merging would not create it and the code would fail open.
- **skills/factory-plan**: run an acceptance command once when storing it, and check it fails for the right reason.
- **skills/factory-run**, **bin/koujou times**: the run stamps its own `claimed_at`; `times` prefers it — because beads keeps an issue's first claim, and one issue claimed days earlier made a 17-minute task read as 66 hours.
- **bin/koujou doctor**: flags a project profile that predates the current factory and names what is missing — because the project's `FACTORY.md` had no security, QA or merge sections and doctor said "All good".

Not changed, noted:
- The orchestrator wrote a landing script by hand again (rebase, gate, acceptance, merge, stamp, notify). It is the same every run; a `koujou land` command would remove a source of slips.
- The orchestrator promoted reviewer suggestions to blocking three times and set one verdict aside once. Both directions were recorded on the tasks. The pattern to watch: reviewers file real defects as suggestions when they are "not in the criteria".
- A security agent was not spawned for one small `security` task (cursor validation); its reviewer was asked for an attacker pass instead.

Still no evidence: a task marked stuck; a deploy watched by the factory; the spec and design stages on real work.

## 2026-11-21 — the second real-project run, from the report to the deploy

What happened after the retro above: the run ended on a long report with three asks. The user answered two in a line each ("yes, go ahead and deploy"; "use boilerplate for the legal pages") and could not answer the third until it was explained again in plain words. The factory then deployed one infrastructure stack, edited two legal pages, merged and watched the deploy.

- **reference/blockers.md, skills/factory-plan**: permission is a prerequisite, asked at intake ("may the factory create this table, or will you?") — because the need for a production table was known when the task was planned and reached the user as a merge blocker at the end. Expected effect: no finished branch waiting on a yes.
- **reference/blockers.md, skills/factory-run**: a need that will block the merge is raised at the next wave boundary, not in the report — all three asks had been known for hours. Expected effect: the final report carries no ask the user is hearing for the first time.
- **reference/blockers.md**: bring a draft, not a question; quote public wording in full, and no sentence may promise what nothing implements — "two pages need your wording" was answered with "you draft it", and the draft then promised removal on request by email, which nothing tracks. Expected effect: wording asks arrive as a diff to approve.
- **reference/blockers.md, agents/factory-security (`plain:`), skills/factory-run**: asks are written for someone who has not read the code; an unanswered ask is rewritten, not repeated — the connect-flow finding was put to the user three times in reviewer language and answered at once when told as four numbered steps. Scenario: `security-finds-traversal` now expects the plain account. Expected effect: no ask needs a second explanation.
- **skills/factory-run (Reporting to the user)**: outcome in a sentence, then the asks, then the link to `report.md` — the final message ran to six sections. No scenario: it is the orchestrator's own message; the demo's stand-in user would not notice.
- **skills/factory-ship §1**: commits added after validation get a reviewer on that diff and their behaviour validated again, copy included; `report.md` and `pr.md` are brought up to date before the merge — the legal-page commit reached production seen only by the gate. Expected effect: nothing ships unreviewed because it arrived late.
- **skills/factory-ship §1b, profile-template (Deploy policy)**: a procedure for production changes the deploy does not make (base is current, diff first, exactly the expected change, one unit, verify, record), and a one-off yes does not rewrite the profile — the orchestrator did this well by hand while the profile said "the factory never deploys". Expected effect: the next such change follows the same steps without improvising, and the profile and the practice agree.
- **skills/factory-ship §4, §5**: merge with `--match-head-commit`; a post-deploy check for each production prerequisite, by reads and ordinary use only; confirm no `factory:awaiting-merge` issue is left before closing the run record; look at `git worktree list` after cleanup — the limiter fails open and nothing checked it was live, a shell loop closed the run record over eight open issues, and a task worktree reported as removed was still there.
- **bin/koujou (`wait`), koujou-times**: time stopped waiting on the user is recorded and reported apart — the run sat for hours on its asks and `koujou times` would count that as work. Tested in `tests/cli`.
- **agents/factory-security (`changes_feature`), skills/factory-run §2**: security fixes leave features as specified; a fix that removes, restricts or adds a step to a feature is allowed only where the feature itself causes serious harm (customer or company data, accounts, money, integrity, trust), and then it is the owner's decision — stated by the user on 2026-11-21, after the connect-flow finding proposed a confirmation page for API users. That one was put to the user, as it should be; the rule makes it the only path. No scenario yet: it needs a fixture whose easy fix is to delete the feature.

Not covered by a test: the ship-stage rules (§1, §1b, §5). The demo has no remote and no production; they need a scenario with a fake deploy tool, which does not exist yet.

## 2026-11-21 — the validate-and-fix loop stops on evidence, not on a count (asked for by the user)

The loop from triage back to build was capped at three rounds. The user called that unfair and misleading, and it was: a round that closes five bugs and finds one small new one is converging, yet used a third of the budget; a twelve-task epic got the same three rounds as a two-task one; and on the second real pass the equivalent per-task cap forced the orchestrator to set a review verdict aside. The user proposed treating bugs as a stack: fix what is underneath, and the bug on top comes back.

- **skills/factory-run §4 (The fix loop), agents/factory-builder (`blocked_by`)**: a builder fixing a bug whose cause is a deeper defect, outside its lane or larger than the bug, reports it instead of guarding the symptom; the orchestrator files it underneath (`bd dep add <bug> <deeper bug>`), and beads' ready list is the top of the stack. Scenarios: `builder-bug-deeper-cause` and its control `builder-bug-in-lane`. Expected effect: no symptom patched over at the place it shows.
- **bin/koujou (`converge`), profile-template (`max_fix_depth`, `max_agent_runs` replace `max_validate_rounds`)**: after each triage `koujou converge` reads the run and says continue, which bug is stuck, or stop. A bug is stuck when its fix has failed validation twice or the chain under it is deeper than `max_fix_depth`; the loop stops when two rounds running have not reduced the open fix-now bugs, or at the agent budget. Tested in `tests/cli`. Expected effect: no run stopped while it was converging, and none left running while it was not.
- **bin/koujou-times, koujou-converge**: one beads call for all of a run's issues instead of one per issue.
- **install.sh**: beads built into `~/go/bin` by its own installer is linked into `~/.local/bin` — CI failed on a runner where that happened and `bd` was on nobody's PATH.

A profile written before this still has `max_validate_rounds`; it is ignored, and the defaults apply for the two new limits.
- **agents/factory-security**: a proof reads only a file the agent planted — because in a scenario run on 2026-11-21 the agent proved a path traversal by fetching `/etc/passwd` and a file from the home folder, whose contents would have landed in a report. `security-finds-traversal` now fails on a proof that names real system or personal files. Expected effect: no real file read to make a point.

Evidence for the new builder scenario: with the previous builder file the agent worked around the store defect inside its own lane and reported `done`; with the new one it reported `blocked` and `blocked_by`.

## 2026-11-21 — demo-todo run on the changes above (td-9t7 in the fixture)

- **skills/factory-run §1b**: where the acceptance suite runs inside the gate, the QA branch lands last — because in the demo `node --test` picks up every test file, and landing the reviewed suite first would have left the epic gate red until the last feature. Expected effect: no red epic gate caused by the suite arriving early.
- **agents/factory-reviewer**: stop a server by process id, never by pattern — because a demo reviewer ran `pkill -f "node src/main.js"`; builders had this rule through the swarm protocol, reviewers did not. Expected effect: no pattern kill in a reviewer's report.
- **bin/koujou-times**: "validation rounds", not "rounds that found bugs" — the demo's single passing round was counted as one that found bugs.

Not exercised by the demo: the fix loop itself. Validation passed first time, so `koujou converge` recorded a zero round and nothing more. It is covered by the CLI tests and the two builder scenarios only; a demo variant with a planted bug that hides a second one would close that.

## 2026-11-21 — demo-fix-loop: the fix loop run with real agents (td-yu2 in the fixture)

A second demo scenario, `tests/scenarios/demo-fix-loop`: an epic already built, with one planted defect whose cause is a level below where it shows. Run once: 16 of 16 checks, 8 agents, 7 m 36 s from the first validation to the passing one.

What the run showed, in order: the validator failed the criterion; the bug was filed with the lane of the task whose criterion it broke; its builder reproduced it, found the cause in the store, did not work around it and reported `blocked_by`; the deeper bug was filed underneath (`bd dep add`), built, reviewed and landed; the first bug's own builder was resumed, rebased and finished with a regression test; round two passed; `koujou converge` recorded 1, 0.

- **skills/factory-run §4**: a fix-now bug gets criteria, an acceptance command and a lane, and its lane is that of the task whose criterion it breaks — the skill did not say how a bug's lane is chosen, and choosing it by guessing at the cause would defeat the stack. Expected effect: the orchestrator never widens a bug's lane on a hunch.
- Confirmed from the entry above: bugs stack through dependencies; `blocked_by` instead of a symptom patch; the loop ends on evidence.

Known and left alone: `koujou times` counts the time a bug spends waiting on the bug underneath it as build time (td-yu2.4 shows 4 m, of which about 2 m was waiting).


## 2026-11-21 — the factory works out how to test a project, and looks behind the interface (asked for by the user); setup on a second real project

The user asked that the factory infer how each module is tested from the project itself, ask only where it is unsure and before work starts, and check results behind the web UI: the database, the cloud account, GitHub.

- **profile-template (`## Test map`), skills/factory-adopt, factory-new, factory-plan, factory-run (preflight)**: one row per module: how it is exercised, where its state lives, the read-only command that reads it back, and the access this machine has. Setup infers the rows and tries each cross-check once; a row it could not infer goes to Open questions. Plan and preflight check that every module a run touches has a usable row, and ask the user then, not when validation starts. `koujou doctor` flags a profile without the section.
- **agents/factory-validator**: step 5, look behind the interface. For a criterion that creates, changes or removes something, read it back where it lives; a disagreement is a bug and the criterion fails; read only, with the access the Test map names; no access is "interface only", not a failure. Report gains `behind:` on each criterion and `cross_checks`.
- **skills/factory (Sizing)**: a Check lane: one module examined as it stands by a validator, nothing built.
- Scenarios: `validator-finds-kept-record` (a delete the API reports as done leaves the record in the store) and its control `validator-passes-stored-build`. Both pass, 9 of 9 and 8 of 8 checks.

What the scenario does and does not show. The planted bug was also caught by the validator file as it was before this change, three times out of three, including once against a profile with no Test map: the fixture's profile says in a sentence where the state is, and that was enough. So on this fixture the new step is not what finds the bug. What the previous file fails is the report: no `behind:` line, no `cross_checks`. The claim that holds is narrower than hoped: the change makes the cross-check a recorded, required part of every validation and makes sure the profile says where state lives for every module; it is not shown to find anything the old validator would have missed. A fixture whose profile is silent about storage, or a store that needs a query to read, would test that.

From `factory-setup` on a second real project (lab run 5):

- **skills/factory-adopt §2**: a red gate may be your own shell — the app builds failed in a network-sandboxed shell with an error naming the font loader, and passed with network access. Expected effect: no baseline recorded red for a reason that is not the project's.
- **skills/factory-adopt §2**: prove app builds in the throwaway worktree, never in the user's checkout, where a build overwrites the output under whatever they are running.
- **skills/factory-adopt §1, §3, profile-template**: find out what a local run touches. The project has no local database; an app started on a laptop reads, and some apps write, production. The profile now says so, lists every writing path under "Never use", and asks the user where writes may be tested.
- **skills/factory-adopt §1, profile-template (Project)**: the tracking and the code can be two repositories; the profile says which one each command, branch and worktree belongs to.
- **README, tests/README, factory-run description**: status brought up to date (two passes on the live product, a deploy the factory watched); "capped fix loop" removed; the fast tests take minutes, not seconds.

Not run for this change: `demo-todo`, which the test skill asks for when `factory-run` or `factory-plan` change. The edits there are a preflight line and a planning section. No scenario covers `factory-adopt`.

## 2026-11-21 — first epic on the second real project, in progress (visibility passes, 14 tasks): lessons taken while it runs

- **`koujou accept` counted the worktree's own path as a test name.** A worktree is named after its task, and Vitest prints the directory it runs in, so `npx vitest run -t "<id>"` "mentioned" the id while printing no test names. It passed for the builder and the reviewer in the task worktree and failed for the orchestrator in the epic worktree, which is how it was seen. `koujou accept` now ignores the id where it is a path segment and where it is the echoed command; a CLI test pins it. The plan skill says Vitest needs `--reporter=verbose`.
- To write up when the run ends (`factory-retro`): a placeholder test in one task pinned a shape the next task existed to change; a component in the spec's table that no task's criteria named (the source line); how the tester's requests for handles reached the builders; a pre-existing security hole found only because the epic gave the origin something worth stealing.

## 2026-11-21 — first epic on the second real project, finished (visibility passes: 15 tasks, 44 agents, 2 h to validated, pull request open)

Result: 12 planned tasks, 3 added during the run (one from a builder's remark, two security fixes), all landed; 3 bounces in review, no rebase conflict; security review passed with two fixes built inside the epic; validation passed in one round, with a validator that compared 219 live results against its own independent calculation and read the stored records behind the pages. What the run taught, and what changed:

- **`koujou converge` counted landed bugs as open.** Where issues stay open until the user merges (`factory:awaiting-merge`), a finished run reported "2 open fix-now bugs". It now treats the label as done; a CLI test pins it. `factory-run` says that `bd ready` cannot see the label either, how to work out the next wave, and that `git branch -d` refuses a branch merged only into the epic branch.
- **A builder went quiet for 45 minutes** on one long shell script and nobody looked. `factory-run` has a section on a worker gone quiet: when to look, what to check, and to replace it in the same worktree.
- **Which security findings are fixed now.** The table deferred everything pre-existing and everything medium. Two exceptions are written in: a pre-existing hole whose harm the epic creates (stored text breaking out of a script element mattered once the origin held a visitor's location), and an introduced medium finding with a small fix that changes no feature. The per-task security agent is briefed with what the task protects and told to read outward; that is how the one high finding was found.
- **A row in the design that no task owned.** The plan's coverage check now includes the design's tables, not only the requirements. Also in the plan skill: an earlier task must not pin its placeholder with a test; the contracts must give the handles a test reads values through, not only the ones it finds controls by.
- **Scratch copies.** Reviewers and security agents copy the worktree to mutate it. Two things went wrong: a copy carried the worktree's `.git` file (pointing at the real branch), and fourteen tasks left six gigabytes. Both worker files say: copy without `.git`, delete when done; the run skill says to clean scratch during the run.
- **A command moved to the background lost its network** and a green suite failed with a DNS error. Written into validation: start long network commands in the background yourself.

What worked and is worth keeping: reviewers proving acceptance tests honest by mutating the code in a scratch copy (it caught a test that passed with the rule deleted, on the first task); the QA suite's reviewer building wrong stand-in products and finding four the suite let through; the Test map's cross-check, which had the validator recompute results from the stored elements instead of trusting the page.

Not done at the time of writing; see the next entry for what was then built and run.

## 2026-11-22 — the test system catches up with the second real project (asked for by the user: "a realistic and great build system, and a good test system"); every tier run on the result

What the second project showed about the tests, more than about the factory: the fixture was tidier than any real repository, one worker had no scenario at all, and reviewers' most useful habit (breaking the code to see whether the tests notice) was pinned by nothing.

- **`koujou ready <epic>`** (new). `bd ready` shows nothing after the first wave in a project that leaves landed tasks open until the user merges, and the orchestrator tracked waves by hand for fifteen tasks. `koujou ready` counts a task as finished when it is closed or labelled `factory:awaiting-merge`, lists what can start, and says what each waiting task waits on. Used throughout this entry's demo run. Documented in the README, the beads reference and `factory-run`.
- **Tier 1 takes the real project's shape.** New CLI tests: `koujou accept` from a second git repository with `BEADS_DIR` (code and tracker apart), and without it failing; `koujou ready` through a chain of three tasks with one landed-and-open; `koujou converge` ignoring a landed bug; the worktree-path false positive. The test guide now says it as a rule: when a real run trips on a project's shape, the shape goes into tier 1 before the fix is called done.
- **`tester-writes-acceptance`** (new scenario; the tester had none). The tester writes acceptance tests for a feature that does not exist. `expect.sh` then builds the feature twice under those tests, correctly and with a planted defect, and requires pass on the first and fail on the second, for both planted defects. First run: 14 tests, pass on good, fail on wrong. The guide's new principle: judge a worker by what its output does when run, where it produces anything runnable; reports judge only workers whose product is a judgement.
- **`reviewer-fails-hollow-tests`** (new scenario). A correct product whose acceptance tests would stay green on a broken one (`status < 500`, `typeof done === 'boolean'`). The reviewer failed it for that reason and reported no defect in the product. The rule was already in the reviewer file (step 6); this pins it, so there is no "fails without the change" run to show.
- **Triage and `bd lint`.** On this entry's `demo-todo` run the orchestrator filed deferred bugs as one-line summaries and the demo's `bd lint` check failed. The reference already said a bug needs `## Steps to Reproduce`; `factory-run` now says so where the bugs are filed, for deferred ones too, and to run `bd lint` after triage. `demo-fix-loop` gained the same check.
- **Fixture.** `npm run lint` covers nested test folders (two testers and a reviewer reported the syntax check skipped `test/acceptance/`); the profile's baseline explains why the runner prints 7 for 6 tests (three workers stopped on it).

Results, all on this working tree:

| Tier | Result |
|---|---|
| 0 static | 0 failed, 0 warnings (the "no scenario for the tester" warning is gone) |
| 1 CLI and scenario setups | pass |
| 2 module scenarios, all 12 | 12 pass, none flaky: builder ×4, reviewer ×3, security ×2, validator ×2, tester ×1 |
| 3 `demo-fix-loop` | 17 of 17; 6 agents, 2 rounds, the deeper bug filed underneath and fixed first |
| 3 `demo-todo` | 20 of 20 after the triage fix above; 5 tasks, 15 agents, no bounce, no conflict, one validation round |

The demo exercised two things from the previous entry without being steered to: the security review found a pre-existing gap whose harm the epic raised (the server answers under any Host name; the new routes delete) from two lenses independently, and it was fixed in the epic under the new rule; and the tester's questions were answered through the mailboxes while the builders were still building, after which its suite passed on the assembled branch at the first run.

Still open: `agent_runs` is kept per task, so `koujou times` does not count epic-level agents (security lenses, the validator): it said 11 where 15 ran. No scenario reaches a worker gone quiet, the design-coverage check in planning, or a browser. `factory-adopt`, `factory-spec` and `factory-plan` have no scenario of their own; the demo covers the last two only as part of the whole.

## 2026-11-22 — the open items from the entry above: agents counted, a quiet worker flagged, and a scenario for every stage and for the browser

- **`koujou spawned <id>`** (new) adds one to an issue's `agent_runs`: a task, or the epic for agents no single task owns (security lenses, re-checks, the validator). `factory-run` now says to count with it and never by setting the number. `koujou times` prints the split ("15 (11 on tasks, 4 for the run)") and says when a run that has a security review or a validation has counted nothing at run level. The budget in `koujou converge` already read both numbers; it was the orchestrator that never wrote the second.
- **`koujou ready` shows what is in flight and for how long**, and marks `QUIET` a task building for more than three times the slowest build so far (and at least ten minutes). The rule "look when a worker has gone quiet" was prose the orchestrator had to remember at the one moment it was busy; it is now a line in the command it runs at every landing. Nothing is stopped automatically.
- **Five scenarios, all passing on their first run:**
  - `spec-finds-prerequisite` — "email me my open todos every morning, and let me reply to mark one done". 12 of 12: both prerequisites found (a mail account to send from, a way to receive replies), the draft left unapproved, no code touched, no task created.
  - `plan-covers-design` — 18 of 18: lint and swarm clean, an acceptance command on every task that fails now, a check named on every criterion, one QA task, both easy-to-miss design rows owned, the design's "not in parallel" decision kept. **Run against the plan skill as it was before this session, it also passed 18 of 18**, so it pins the behaviour and does not show that the sentence added yesterday (cover the design's tables) is what produces it. The sentence stays, on the evidence of the real run.
  - `adopt-writes-profile` — 18 of 18 on a project with its own rules and a file-backed store: gate found and run, Test map names the file and how to read it back, the owner's rules kept, nothing committed, no worktree, data file or server left.
  - `validator-finds-forgotten-tick` and its control `validator-passes-page` — the fixture gains a page (`page-good`, `page-forgets` in `make.py`). In the planted one a tick draws the todo as done and sends a request the API refuses, unread. The validator drove a real browser, saw it done on screen, read the API as the Test map's row says, reloaded, and reported the blocker with the malformed request body. On the correct page it reported nothing above minor.
- **From what those agents reported:** `factory-adopt` says what `bd init` really does (a commit of its own, `core.hooksPath`, agent-instruction files that may contradict the profile); `factory-validator` says to move the browser tool's files into the evidence directory, since the tool writes them where the session started whatever path it is given.

Run on this tree: static 0 failed, 0 warnings; CLI and all 19 scenario setups pass; the five new scenarios pass (the 12 older ones were run on the previous entry's tree and their subjects have not changed since, except `factory-validator.md`, which gained one sentence about where evidence goes and was run again by the two browser scenarios); `demo-fix-loop` 17 of 17 with the new commands in use: `koujou times` reported 7 agents, 5 on tasks and 2 for the run, which is what was spawned; `koujou ready` showed the one task in flight with its age and did not flag it. `demo-todo` was not run again for this entry: the changes to `factory-run` since its last run are how agents are counted and the quiet flag.

Not done: `factory-design`, `factory-ship` against a remote and `factory-retro` still have no scenario. Replacing a quiet worker and the security exception for a pre-existing finding are exercised only when a run happens to meet them.
