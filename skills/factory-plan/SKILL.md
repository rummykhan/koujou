---
name: factory-plan
description: Factory stage 3 — turn approved requirements (and design, for lane L) into epics and a dependency graph of tasks in beads. Use when requirements.md is approved and the work needs breaking into tasks that agents can build in parallel.
---

# Factory: design → epics → tasks

Output: `plan.json` in the work order folder, then the same graph created in beads. The plan decides how well the swarm runs. Tasks that are too big stall a builder; tasks with hidden overlap collide at merge; tasks with soft acceptance criteria pass review while being wrong.

Read `~/.claude/skills/factory/reference/beads.md` for the conventions and `plan-example.json` beside it for the format.

## Epics

An epic is one outcome a user could notice, deliverable and validatable on its own. Most lane-M work is a single epic. Split lane-L work into epics by outcome, ordered so each leaves the product working. Epic `description` names the requirements it serves and ends with a `## Success Criteria` section: the user-visible checks the validator will run against the assembled result.

## Tasks

Each task is one builder session: a coherent change with its tests, roughly a few hundred changed lines at most. Smaller is better than larger. A task that needs "and" in its title is usually two.

Every task has:

- **description** — what and why, and the requirement ids it serves.
- **acceptance_criteria** — a checklist in which every line names how it will be checked, written before the code exists:

  ```
  - <what must be true> — test: <the behaviour the automated test exercises, at which level: unit, API, browser>
  - <what must be true> — run: `<command>` → <what it shows>
  - <what must be true> — manual: <what the validator does and sees>   (only when it cannot be automated; say why)
  ```

  Derive the lines from the requirement's acceptance lines and the design's contracts, narrowed to this task; for a small task that explains itself, from the issue's own steps to reproduce (the fix is accepted when the reproduction no longer reproduces, and a test pins that). A line nobody can check by running something is a wish, not a criterion: rewrite it or drop it. Each `test:` line becomes at least one automated test the task must add, **named with the task id** (`ll-abc: a double click creates one link`), so the task's acceptance tests can be run on their own.
- **acceptance command** — the one command that runs exactly this task's acceptance tests, by that id: `node --test --test-name-pattern "<id>"`, `npx playwright test -g "<id>"`, `pytest -k <id>`, whatever the project's runners offer (the profile's QA section gives the form). Store it once the id exists: `bd update <id> --set-metadata accept='<command>'`. The command must print the names of the tests it runs (most runners do by default; `pytest` needs `-v`): `koujou accept` fails a run whose output never mentions the task id, because a filter that matches nothing exits 0 in most runners. Run it once when you store it: it must fail now, and for the reason the task exists (no test carries the id yet; the bug still reproduces), not because a file is missing in a fresh worktree or a service is down. It is run by the builder (red before the change, green after), by the reviewer, by the orchestrator when the branch lands, and again on the finished branch before shipping: `koujou accept <id>`. A task is closed on this command passing plus the review, not on anyone's say-so.
- **design** — the lane: the files or directories this task owns, the contract it implements (quoted from `design.md`), and pointers to the code to follow as a pattern.

### The QA task

Every epic with user-visible behaviour gets one QA task (label `qa`), built by a `factory-tester`: the automated acceptance suite for the epic, written from the requirements and contracts. Its lane is the e2e test directory and config from the profile's QA section. It depends on nothing inside the epic, so it starts in the first wave alongside the builders, and its acceptance criteria are: every requirement acceptance line and epic success criterion has a named test or a stated reason it is manual; the suite runs with one command; the suite is wired into the gate. For the tester to write against a UI before it exists, the handles it will use (routes, labels, button names, error texts) must be in the contracts.

### Prerequisites

For every row in the requirements' `## Prerequisites` table that is not `provided`, follow `~/.claude/skills/factory/reference/blockers.md`: a `factory:needs-user` bead with a human gate for `pending` items, with only a thin real-integration task depending on it and the bulk of the work planned against a fake; `next pass` items get their thin tasks created as `factory:deferred` outside the epic, and the epic's success criteria must be satisfiable without them. Check the result with `bd ready`: if most of the epic sits behind a gate, the plan needs a better seam, or the user needs to hear that now.

### Other tasks

The task that wires the pieces into the runnable product (the entry point, the composition root, the route table) needs an acceptance criterion that runs the real thing: start the actual process or load the actual page, not only call functions in a test. Unit-level tasks can each be correct while the assembled program fails on start-up, on its real configuration, or on its real I/O.

When the work is an existing backlog issue with no criteria, planning it means bringing that one issue up to standard: add acceptance criteria, a lane and dependencies to it (`bd update`), leaving the rest of the backlog alone.

A task whose lane touches sign-in, sessions, permissions, redirects, file handling, outbound requests, payments, secrets or dependencies gets the label `security`: it will be read by a security reviewer as well as the ordinary one.

Kinds of task to remember: a `spike` for each unknown the design flagged; migration and rollout tasks; documentation the project requires in the same change; a `decision` bead with a gate for anything the user still has to choose.

## A pass from the backlog

When the user asks the factory to work through existing issues instead of a new request, there is no requirements stage, and so nothing has swept for what only the user can provide. The first real pass showed the cost: missing sign-in credentials turned up as "not verified" in the final report, and three product decisions reached the user as questions after the code was written. The intake does that sweep before any builder starts.

1. **Pick** the issues with the user, or propose a set: ready, no open dependency outside the set, lanes that do not overlap. Label them `factory:pass-<n>`.
2. **Scout each issue.** Spawn one read-only agent per issue, in parallel (an `Explore` agent, or `factory-reviewer` told it is scouting, not reviewing). Its brief: read the issue and the code in and around its likely lane, and report (a) every external thing the work or its verification touches (a service, a credential, an account, a paid action) and whether the profile says it is available locally, and anything the change would need created outside the code before it works in production (a table, an index, an environment variable, a secret, a migration) together with how such things reach production in this project; (b) every choice a builder would have to guess, with the options and the one the code already leans towards; (c) what cannot be verified on a local build and why; (d) the files it would change, as a proposed lane; (e) whether the issue is what it says, or hides a larger problem.
3. **Bring each issue up to standard** from the scout's report: acceptance criteria, lane, the `security` label where it applies, dependencies between issues whose lanes meet.
4. **Write `intake.md`** in the work order (`docs/factory/pass-<n>/`), `status: draft`:
   - the issues, one line each, with the lane and wave;
   - `## Prerequisites`, the same table `factory-spec` writes (see `blockers.md`), from the scouts' (a) and (c);
   - `## Decisions`, from (b): each with the options, the default the factory will take if the user says nothing, and what it would cost to change later. Take the default only for choices that are cheap to reverse. A choice that touches security, money, data that cannot be recovered, or what users are promised has no default: it is a question, and the task that needs it waits behind a `decision` bead with a gate;
   - `## Cannot be verified locally`, with what would make each verifiable.
5. **Ask once.** Show the user the intake in one message: what you need, where to put it, the decisions with their defaults, and what happens to each issue if they cannot answer now. Record the answers, create the `factory:needs-user` beads and gates as `blockers.md` describes, drop or defer the issues that cannot proceed, and mark the intake `approved`.

Scouting costs one short agent per issue and replaces questions asked after the work is done, when changing the answer means rebuilding.

## Dependencies

- Add an edge only where one task truly cannot start until another is finished: it calls code the other creates, or builds on its schema.
- When a task changes a shape other code already asserts on (a field added to a response, a route that changes status), its lane includes the existing tests that pin the old shape, and its criteria say those tests are updated to the new contract and nothing else in them is loosened. Otherwise the builder has to step outside its lane to get the gate green.
- Add an edge between two tasks that would change the same function, the same block or the same contract, even if neither logically needs the other: those cannot both be right without one seeing the other. Two tasks that only share a file, each adding its own route, case or test block, may run in parallel: the merge queue lands one and the other rebases (on the lab's pass, builders resolved six such conflicts themselves, the slowest in 34 seconds). Say so in both tasks' design fields ("shares `<file>` with `<task>`: keep the change local, expect to rebase"), and keep at most three tasks sharing one file in a wave.
- To widen the swarm, look for a contract that would let two dependent tasks proceed at once (agree the interface up front, build both sides against it). Put that contract in the design field of both.
- Don't chain tasks just because you would naturally do them in that order. Every unnecessary edge removes a parallel slot.

## Create and verify

```bash
bd create --graph <work-order>/plan.json --dry-run
bd create --graph <work-order>/plan.json --json    # save the key → id map into the work order
bd lint
bd swarm validate <epic-id> --verbose
```

Use `--sandbox` on writes if the profile says beads syncs to a remote and the plan is not yet approved.

Read the swarm analysis critically: are the waves what you expect; is the parallelism plausible; are there orphans or a task that depends on nothing but obviously should? Then check coverage: every requirement is served by at least one task, and every task serves a requirement. Fix the graph before showing it.

## Gate

Show the user the epics, the task list by wave, what runs in parallel, what is waiting on them (the open prerequisites, with what each one blocks), and anything deliberately left out or moved to the next pass. On approval, the plan is the contract for `factory-run`. If the project also keeps a human roadmap, add the epic to it now.

## Next

`factory-run <epic-id>`.
