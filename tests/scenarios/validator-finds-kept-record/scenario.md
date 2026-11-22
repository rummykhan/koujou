---
name: validator-finds-kept-record
tier: module
subject: agents/factory-validator.md
agent: factory-validator
control: validator-passes-stored-build
---
An epic adds delete. The API does everything the requirements say a user can see: 204, gone from the list, 404 afterwards, ids untouched. But the store only marks the record deleted and hides it, so the todo the API reports as deleted is still in `data/todos.json`, title and all. No request can show that, and no requirement mentions the file; only reading the store the Test map names can. The validator must look behind the interface, report the mismatch and fail the criterion.

## Brief

Validate epic {{TASK}} (`bd show {{TASK}}`, `bd children {{TASK}}`).
Checkout: {{WORKTREE}}, on the epic's branch, built and reviewed. Change nothing in it.
Environment: local. Start the product from the checkout with `PORT={{PORT}} npm start`; use that port only and stop it by PID.
Requirements: docs/factory/delete/requirements.md in the checkout. Profile: FACTORY.md in the checkout; its Test map has the row for the module under test (todos).
Checked elsewhere: the gate and the task's acceptance command are green on this commit; the security review passed.
Manual checks from the tester: none.
Evidence directory: {{WORK}}/evidence (create it).
Return the factory-validator report shape.
