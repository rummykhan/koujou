# Swarm protocol: how parallel agents stay out of each other's way

The delivery loop runs several builders at once, each in its own git worktree. Worktrees stop them overwriting each other's files on disk; they do not stop two agents making incompatible changes that collide at merge. These rules do. The orchestrator includes this file's path in every builder brief.

## 1. Lanes are decided before the wave starts

- Every task's `design` field lists the files or directories it owns. The planner adds a dependency between any two tasks whose lanes overlap, so tasks that are ready together never share a file.
- Shared contracts (a type, a route shape, a table schema, a function signature that two tasks meet at) are fixed in `design.md` or the epic's design field **before** the wave. A builder implements its side of a contract exactly as written.
- Before spawning a wave the orchestrator re-checks the lanes of the tasks in it. Overlap means the plan is wrong: run the overlapping tasks one after the other.

## 2. Stay in your lane

A builder edits only the files its task owns, plus new files inside its own directories. When the work turns out to need a change elsewhere:

- **Inside a sibling's lane, or a shared contract** → do not edit. Post a message to that sibling's task (below), carry on with everything that does not depend on the answer, and list it under `needs` in the final report.
- **In files nobody owns** (a shared config, a lockfile, a barrel export, a migration index) → make the smallest additive change, never reformat or reorder, and call it out under `shared_files` in the report so the orchestrator merges that branch with care.
- **A discovery that is not this task's job** (an unrelated bug, a missing requirement) → report it under `discovered`; don't fix it.

## 3. The mailbox: bead comments

Agents talk through comments on beads. Comments are append-only, visible to every worktree (they share one beads database), and remain as a record afterwards.

```bash
bd comments <task-id>                                   # read a task's mailbox
bd comment <task-id> "[from <my-task-id>] <message>"    # post to a task's mailbox
```

- Post to **the task whose owner needs to know**: a sibling's task for a request or a heads-up, your own for notes to the orchestrator.
- Read **your own task's** mailbox at three points: before starting, before each commit, and before writing the final report. Act on what is there or say why not.
- A good message is self-contained: what you need or what you changed, the exact name or signature involved, and whether you are blocked on it.
- Comments are the only bead write a builder makes. Status, notes, metadata, closing and creating issues belong to the orchestrator.

Typical messages: "I need `parseSchedule()` to accept a timezone argument — are you adding it or should I wrap it?", "Heads-up: the `Post` type gains an optional `exportedAt` field in my branch", "Blocked: the contract says the route returns `items`, the existing client reads `data`."

## 4. The orchestrator is the hub

- It reads the mailboxes of all in-flight tasks whenever a builder reports, and relays anything urgent to a running builder directly.
- A request that changes a shared contract is the orchestrator's call: it updates the design, tells every affected builder, and adds a dependency if the tasks can no longer run side by side.
- Two builders that disagree do not negotiate in a loop. One round of messages, then the orchestrator decides.

## 5. Merging is serial

Builders never merge, rebase onto each other, or push. The orchestrator merges accepted task branches into the epic branch one at a time and runs the gate on the result. A branch that conflicts goes back to its builder with the conflict and the current epic branch to rebase onto; that counts as a fix attempt.

## 6. Shared machine resources

Parallel builders share one machine. A builder that needs a port, a local database or a container uses the per-worktree values the brief gives it (the orchestrator assigns a distinct port offset and, where tests write to a persistent store, a distinct database name or table prefix per task, since two test runs sharing one store fail each other at random) and never stops or resets a service it did not start. A process you start, you stop by its process id; a pattern kill (`pkill -f`, `killall`) also takes down the same program running in a sibling's worktree.
