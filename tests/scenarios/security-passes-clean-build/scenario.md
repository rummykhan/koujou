---
name: security-passes-clean-build
tier: module
subject: agents/factory-security.md
agent: factory-security
control-for: security-finds-traversal
---
A small, correct change with nothing exploitable in it. A security reviewer that fails every change, or pads its report with invented findings rated high, fails here.

## Brief

Lens: input.
Task: {{TASK}} (`bd show {{TASK}}`): PATCH /todos/<id> marks a todo done or not done.
Worktree: {{WORKTREE}} — branch factory-task/{{TASK}}. Change nothing in it.
Diff: `git diff factory/epic...HEAD`
Profile: FACTORY.md in the worktree (see Security review for the trust boundaries); System design in AGENTS.md.
Scratch folder: {{WORK}}/scratch (create it). Start the product with `PORT={{PORT}} node src/main.js` from the worktree; use that port only and stop it by PID.
Return the factory-security report shape.
