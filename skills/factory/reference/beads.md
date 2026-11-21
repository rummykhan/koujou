# Beads conventions for the factory

Checked against `bd` 1.3.4. Run `bd <command> --help` if a flag is rejected; the CLI moves fast.

## Project state

- Already initialised (`.beads/` exists): adopt it. Never run `bd init` again; it can destroy history. While only looking around, pass `--readonly` so nothing is written or synced by accident. `bd list --json` leaves out descriptions; use `bd show <id> --json` for the full text.
- Not initialised: `bd init --non-interactive --prefix <short>`. It writes `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json` and editor folders; look at what it touched before committing.
- If the project syncs beads to a remote and the work is a trial or not yet agreed, pass `--sandbox` on writes so nothing is pushed.

## Issue shapes

| Type | Use | Required sections (`bd lint`) |
|---|---|---|
| `epic` | One deliverable outcome | Success Criteria |
| `task` / `feature` | One builder session of work | Acceptance Criteria |
| `bug` | A defect found by review or validation | Steps to Reproduce, Acceptance Criteria |
| `decision` | A choice that blocks work until the user makes it | Decision, Rationale, Alternatives Considered |
| `spike` | Time-boxed investigation whose output is knowledge | Goal, Findings |

Fields: `description` says what and why and names the requirement ids it serves (`R3`). `acceptance_criteria` is a checklist an outsider can verify. `design` carries implementation notes, the files expected to change, and anything from `design.md` the builder needs. Use `--spec-id` to point at the work order's requirements file.

Priority: P0 broken now, P1 this epic cannot ship without it, P2 normal, P3 nice to have, P4 backlog.

Labels: `factory:stuck` (hit the attempt cap, waiting on the user), `factory:needs-user` (a prerequisite only the user can provide; see `blockers.md`), `factory:deferred` (logged for a later phase), `qa` (the epic's acceptance-suite task), `security` (a task a security reviewer must read, or a bug the security review found), `factory:pass-<n>` (an issue picked for a backlog pass), `factory:run` (a pass's run record: the task that holds the run's timestamps and counters, since a pass has no epic), `factory:awaiting-merge` (built, reviewed and validated on the epic branch; closed by `factory-ship` when it reaches the base branch), `area:<name>` when useful.

Time: beads stamps `created_at`, `started_at` (on claim) and `closed_at` itself. The run adds `claimed_at`, `built_at`, `reviewed_at`, `merged_at` and `agent_runs` on tasks, and `security_at`, `validated_at` and `shipped_at` on the epic, as metadata (`bd update <id> --set-metadata built_at=$(date -u +%FT%TZ)`). `bd list --json` leaves metadata out, so read it with `bd show <id> --json`, or let `koujou times <epic-id>` add it up. Time the run spends stopped for an answer is kept apart: `koujou wait <epic-id> start` when it stops, `koujou wait <epic-id> end` when it resumes (add `--sandbox` where the run's other writes use it); the total is `waited_s` on the epic or run record.

## Creating the graph

`plan.json` (see `plan-example.json` beside this file):

```bash
bd create --graph plan.json --dry-run     # structure check
bd create --graph plan.json --json        # returns key → id map; save it
bd lint                                   # every issue has its sections
bd swarm validate <epic-id> --verbose     # waves, max parallelism, cycles, orphans
```

Edges: `{"from_key":"b","to_key":"a","type":"blocks"}` means **b waits for a**.

## Working the graph

```bash
bd ready --parent <epic> --exclude-type epic --json   # the current wave
bd update <id> --claim                                # in_progress, assigned to you
bd show <id> --json                                   # full text + metadata
bd update <id> --append-notes "<what happened>"       # mid-flight state
bd update <id> --set-metadata fix_attempts=<n>        # loop counter (also: rebases; reopened on a bug whose fix failed validation)
koujou converge <epic-id> --record                    # after each triage: records the round, says continue, stuck <bug> or stop
bd update <id> --set-metadata accept='<command>'      # the task's acceptance tests; run with: koujou accept <id>
bd close <id> --reason "<shipped> | evidence: <...> | residue: <...>"
bd unclaim <id>                                       # give a task back
bd epic status
bd epic close-eligible                                # close epics whose children are done
```

## Bugs and discovered work

```bash
# fix now: child of the epic, so the epic cannot close without it
bd create "<title>" -t bug -p 1 --parent <epic> --deps discovered-from:<task> \
  --body-file bug.md --acceptance "<what fixed looks like>" --validate

# next phase: no parent, labelled, still linked to where it came from
bd create "<title>" -t bug -p 3 -l factory:deferred --deps discovered-from:<task> \
  --body-file bug.md --acceptance "<...>" --validate
```

A bug description needs a `## Steps to Reproduce` section with observed and expected behaviour.

## Gates (waiting on a human)

```bash
bd gate create --blocks <id> --reason "<what you need from the user>"
bd gate list
bd gate resolve <gate-id>
```

A gated issue drops out of `bd ready` until the gate is resolved. Use gates for: a stuck task, a `decision`, deploy approval.

## Worktrees

`bd worktree create <path> --branch <name>` creates a git worktree that shares the main checkout's beads database. Plain `git worktree add` works too; either way only the orchestrator writes beads.

## Things that bite

- Claims carry a short lease. An expired lease only matters if someone runs `bd reclaim`; don't run it mid-epic.
- `bd close` refuses an issue with open children or a live blocker. That refusal is information; don't `--force` past it.
- Valid statuses are `open`, `in_progress`, `blocked`, `deferred`, `closed`. There is no `done`.
- When a project also keeps a human roadmap document, a bead is not finished until that document is updated in the same change.
