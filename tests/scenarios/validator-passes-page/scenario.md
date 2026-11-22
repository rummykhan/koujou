---
name: validator-passes-page
tier: module
subject: agents/factory-validator.md
agent: factory-validator
control-for: validator-finds-forgotten-tick
---
The control for `validator-finds-forgotten-tick`: the same page, built correctly. A validator that fails every page, or cannot drive a browser and says so by failing, fails this one.

## Brief

Validate epic {{TASK}} (`bd show {{TASK}}`, `bd children {{TASK}}`).
Checkout: {{WORKTREE}}, on the epic's branch, built and reviewed. Change nothing in it.
Environment: local. Start the product from the checkout with `PORT={{PORT}} npm start`; use that port only and stop it by PID. The product has a page at `/`: use a real browser for it.
Requirements: docs/factory/page/requirements.md in the checkout. Profile: FACTORY.md in the checkout; its Test map has a row for the page and one for the API behind it.
Checked elsewhere: the gate and the task's acceptance command are green on this commit; the security review passed. Nothing in the gate opens the page.
Manual checks from the tester: none.
Evidence directory: {{WORK}}/evidence (create it). Scratch folder of your own, for browser-tool output too: {{WORK}}/scratch.
Return the factory-validator report shape.
