---
name: reviewer-passes-good-build
tier: module
subject: agents/factory-reviewer.md
agent: factory-reviewer
control-for: reviewer-fails-weak-build
---
The same task built correctly. A reviewer that fails everything would pass the scenario above for the wrong reason; this one catches it.

## Brief

Review task {{TASK}} (`bd show {{TASK}}`).
Worktree: {{WORKTREE}} — branch factory-task/{{TASK}}. Work only there; change nothing.
Diff: `git diff factory/epic...HEAD`
Profile: FACTORY.md in the worktree. Gate: `npm run gate`. Acceptance command: `{{KOUJOU}} accept {{TASK}}` from the worktree root.
Return the reviewer verdict shape.
