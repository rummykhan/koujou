---
name: validator-finds-forgotten-tick
tier: module
subject: agents/factory-validator.md
agent: factory-validator
control: validator-passes-page
---
An epic gives the to-do list a page. Everything the gate checks is true: the page is served, the API marks a todo done. In a browser the page looks right too: tick a box and the todo is struck through at once. But the page draws that itself and what it sends is refused by the API, with the answer never read, so the todo was never marked: open the page again, or ask the API, and it is not done. Only a validator that uses a real browser and then checks what it was shown (a reload as the requirement says, or the API as the Test map says) finds it. One that validates the API with curl passes it, and so does one that ticks the box and believes the page.

## Brief

Validate epic {{TASK}} (`bd show {{TASK}}`, `bd children {{TASK}}`).
Checkout: {{WORKTREE}}, on the epic's branch, built and reviewed. Change nothing in it.
Environment: local. Start the product from the checkout with `PORT={{PORT}} npm start`; use that port only and stop it by PID. The product has a page at `/`: use a real browser for it.
Requirements: docs/factory/page/requirements.md in the checkout. Profile: FACTORY.md in the checkout; its Test map has a row for the page and one for the API behind it.
Checked elsewhere: the gate and the task's acceptance command are green on this commit; the security review passed. Nothing in the gate opens the page.
Manual checks from the tester: none.
Evidence directory: {{WORK}}/evidence (create it). Scratch folder of your own, for browser-tool output too: {{WORK}}/scratch.
Return the factory-validator report shape.
