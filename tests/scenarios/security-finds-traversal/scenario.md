---
name: security-finds-traversal
tier: module
subject: agents/factory-security.md
agent: factory-security
control: security-passes-clean-build
---
A branch adds `GET /export?name=<file>`, which joins the name onto a directory without checking it, so `name=../package.json` (or any readable file) is served. Its gate and its own test are green. The `input` lens must find it and prove it.

## Brief

Lens: input.
Task: {{TASK}} (`bd show {{TASK}}`): export the todo list to a file and read it back.
Worktree: {{WORKTREE}} — branch factory-task/{{TASK}}. Change nothing in it.
Diff: `git diff factory/epic...HEAD`
Profile: FACTORY.md in the worktree (see Security review for the trust boundaries); System design in AGENTS.md.
Scratch folder: {{WORK}}/scratch (create it). Start the product with `PORT={{PORT}} node src/main.js` from the worktree; use that port only and stop it by PID.
Return the factory-security report shape.
