---
name: reviewer-fails-weak-build
tier: module
subject: agents/factory-reviewer.md
agent: factory-reviewer
control: reviewer-passes-good-build
---
A branch whose gate is green but which is wrong three ways: `done` is always set to true, the new test covers only `true`, and an existing test was loosened (with the limit it pinned). A reviewer that reads criteria against evidence must fail it.

## Brief

Review task {{TASK}} (`bd show {{TASK}}`).
Worktree: {{WORKTREE}} — branch factory-task/{{TASK}}. Work only there; change nothing.
Diff: `git diff factory/epic...HEAD`
Profile: FACTORY.md in the worktree. Gate: `npm run gate`. Acceptance command: `{{KOUJOU}} accept {{TASK}}` from the worktree root.
Return the reviewer verdict shape.
