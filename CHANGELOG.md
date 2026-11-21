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
