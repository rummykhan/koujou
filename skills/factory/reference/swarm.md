# Swarm protocol: how parallel agents stay out of each other's way

The delivery loop runs several builders at once, each in its own git worktree. Worktrees stop them overwriting each other's files on disk; they do not stop two agents making incompatible changes that collide at merge. These rules do. The orchestrator includes this file's path in every builder brief.

## 1. Lanes are decided before the wave starts

- Every task's `design` field lists the files or directories it owns. The planner adds a dependency between any two tasks that would change the same function, block or contract. Tasks that are ready together may still share a file where each adds its own separate piece; the design field names the task it shares with, and section 5 is how that is kept safe.
- Shared contracts (a type, a route shape, a table schema, a function signature that two tasks meet at) are fixed in `design.md` or the epic's design field **before** the wave. A builder implements its side of a contract exactly as written.
- Before spawning a wave the orchestrator re-checks the lanes of the tasks in it. Two tasks set to change the same function or contract without a dependency means the plan is wrong: run them one after the other.

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

## 5. The merge queue: one lands, the others rebase

Lanes make conflicts rare, not impossible: two tasks meet in a route table, a shared type, a lockfile. So every builder works as if the epic branch will move under it, because it will.

- **One branch lands at a time.** The orchestrator lands accepted branches on the epic branch in the order their reviews passed, each rebased onto the current epic branch and gated before it goes in. Builders never merge, never push, and never rebase onto a sibling's branch.
- **You are told when the epic branch moves.** After each landing the orchestrator posts to the mailbox of every task still in flight: which task landed, at which commit, touching which files.
- **Rebase your own branch onto the epic branch** (`git rebase factory/<epic>`, the one rebase a builder may do) when a landing touched files you also changed or code you call, and always once more before you report done. Then run the gate again: a rebase that applies cleanly can still break behaviour.
- **Resolving a conflict.** Read the other side before choosing: `git log -p factory/<epic> -- <file>` shows what landed and its commit names the task; `bd show <that-task>` says what it was meant to do. Keep both behaviours. Never resolve by taking your side wholesale, deleting the other task's code or loosening its tests. If the two changes cannot both hold (they implement the shared contract differently), stop: post to the other task's mailbox and to your own for the orchestrator, and report it under `needs`. That is a contract question, and the orchestrator decides it.
- **Say what you resolved.** List conflicted files and how you resolved each under `conflicts` in your report; the reviewer checks exactly those.
- A branch sent back from the queue because it conflicted is counted in `rebases`, not as a failed review.

## 6. Shared machine resources

Parallel builders share one machine. A builder that needs a port, a local database or a container uses the per-worktree values the brief gives it (the orchestrator assigns a distinct port offset and, where tests write to a persistent store, a distinct database name or table prefix per task, since two test runs sharing one store fail each other at random) and never stops or resets a service it did not start. A process you start, you stop by its process id; a pattern kill (`pkill -f`, `killall`) also takes down the same program running in a sibling's worktree.
