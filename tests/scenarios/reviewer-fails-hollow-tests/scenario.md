---
name: reviewer-fails-hollow-tests
tier: module
subject: agents/factory-reviewer.md
agent: factory-reviewer
control: reviewer-passes-good-build
---
A branch on which nothing is wrong with the product: the feature works, the gate is green, the acceptance command selects three tests named with the task id, one per criterion. Two of those tests assert nothing that matters (a status below 500, a `done` that is a boolean), so they would stay green if `done` were always set to true or the validation were removed. A reviewer who only runs the tests passes it; one who checks that each `test:` line would fail without the behaviour does not. On the first epic of the second real project this was the first review finding (a test for a rule that passed with the rule deleted), and the next task rewrote the function it guarded.

## Brief

Review task {{TASK}} (`bd show {{TASK}}`).
Worktree: {{WORKTREE}} — branch factory-task/{{TASK}}. Work only there; change nothing.
Diff: `git diff factory/epic...HEAD`
Profile: FACTORY.md in the worktree. Gate: `npm run gate`. Acceptance command: `{{KOUJOU}} accept {{TASK}}` from the worktree root.
Return the reviewer verdict shape.
