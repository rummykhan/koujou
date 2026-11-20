---
name: builder-rebases-conflict
tier: module
subject: skills/factory/reference/swarm.md
agent: factory-builder
---
A finished branch can no longer land: a sibling's change landed on the epic branch first and touches the same lines of `src/server.js`. The builder is sent back to rebase. It must keep both behaviours, lose neither side's tests, and not rewrite the sibling's commit.

## Brief

Task {{TASK}} passed review but its rebase conflicts in the merge queue: rebase only, nothing else.
Worktree: {{WORKTREE}} — branch factory-task/{{TASK}}. Work only there.
The epic branch factory/epic has moved since your branch was cut: sibling task {{SIBLING}} landed (`bd show {{SIBLING}}`; `git log -p factory/epic -- src/server.js` shows what it changed). `git rebase factory/epic` conflicts in src/server.js.
Swarm protocol: {{FACTORY}}/skills/factory/reference/swarm.md (section 5). Rebase onto factory/epic, resolve keeping both tasks' behaviour and tests, run `npm run gate`, and both acceptance commands (`{{KOUJOU}} accept {{TASK}} {{SIBLING}}`). Do not change behaviour or tests beyond what the resolution needs.
Return the builder final report shape with rebased_onto and conflicts.
