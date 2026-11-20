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
- **acceptance_criteria** — a checklist a reviewer can verify by running something. Derive it from the requirement's acceptance lines, narrowed to this task. Include the tests the task must add.
- **design** — the lane: the files or directories this task owns, the contract it implements (quoted from `design.md`), and pointers to the code to follow as a pattern.

### The QA task

Every epic with user-visible behaviour gets one QA task (label `qa`), built by a `factory-tester`: the automated acceptance suite for the epic, written from the requirements and contracts. Its lane is the e2e test directory and config from the profile's QA section. It depends on nothing inside the epic, so it starts in the first wave alongside the builders, and its acceptance criteria are: every requirement acceptance line and epic success criterion has a named test or a stated reason it is manual; the suite runs with one command; the suite is wired into the gate. For the tester to write against a UI before it exists, the handles it will use (routes, labels, button names, error texts) must be in the contracts.

### Prerequisites

For every row in the requirements' `## Prerequisites` table that is not `provided`, follow `~/.claude/skills/factory/reference/blockers.md`: a `factory:needs-user` bead with a human gate for `pending` items, with only a thin real-integration task depending on it and the bulk of the work planned against a fake; `next pass` items get their thin tasks created as `factory:deferred` outside the epic, and the epic's success criteria must be satisfiable without them. Check the result with `bd ready`: if most of the epic sits behind a gate, the plan needs a better seam, or the user needs to hear that now.

### Other tasks

The task that wires the pieces into the runnable product (the entry point, the composition root, the route table) needs an acceptance criterion that runs the real thing: start the actual process or load the actual page, not only call functions in a test. Unit-level tasks can each be correct while the assembled program fails on start-up, on its real configuration, or on its real I/O.

When the work is an existing backlog issue with no criteria, planning it means bringing that one issue up to standard: add acceptance criteria, a lane and dependencies to it (`bd update`), leaving the rest of the backlog alone.

Kinds of task to remember: a `spike` for each unknown the design flagged; migration and rollout tasks; documentation the project requires in the same change; a `decision` bead with a gate for anything the user still has to choose.

## Dependencies

- Add an edge only where one task truly cannot start until another is finished: it calls code the other creates, or builds on its schema.
- Add an edge between any two tasks whose lanes overlap, even if neither logically needs the other. This is what makes "ready at the same time" mean "safe to build in parallel".
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
