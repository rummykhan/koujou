---
name: validator-passes-stored-build
tier: module
subject: agents/factory-validator.md
agent: factory-validator
control-for: validator-finds-kept-record
---
The same epic built correctly: a deleted todo's record leaves the file. A validator that fails everything, or that reports a mismatch without reading the file, would pass the scenario above for the wrong reason.

## Brief

Validate epic {{TASK}} (`bd show {{TASK}}`, `bd children {{TASK}}`).
Checkout: {{WORKTREE}}, on the epic's branch, built and reviewed. Change nothing in it.
Environment: local. Start the product from the checkout with `PORT={{PORT}} npm start`; use that port only and stop it by PID.
Requirements: docs/factory/delete/requirements.md in the checkout. Profile: FACTORY.md in the checkout; its Test map has the row for the module under test (todos).
Checked elsewhere: the gate and the task's acceptance command are green on this commit; the security review passed.
Manual checks from the tester: none.
Evidence directory: {{WORK}}/evidence (create it).
Return the factory-validator report shape.
