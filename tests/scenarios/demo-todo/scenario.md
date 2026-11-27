---
name: demo-todo
tier: demo
subject: skills/factory-run/SKILL.md
agent: orchestrator
---
The whole factory on a small product: a raw request goes through requirements, plan, a parallel build with review and the merge queue, validation, and a local ship. Lean by default: it must stay inside the budget `koujou budget` gives (about 10 agent runs for a plan of three tasks). The session running the test is the orchestrator and also stands in for the user at the approval gates: approve each artifact as written, answer any question with the default it proposes, and record that it did so.

## Brief

You are in {{WORK}}/todo, a small to-do API already set up for the factory (`FACTORY.md`, `AGENTS.md`, beads with prefix `td`). Use the factory under test: read skills from {{FACTORY}}/skills and worker definitions from {{FACTORY}}/agents (not from ~/.claude, which may hold an older install), and call the CLI as `{{KOUJOU}}`.

Deliver this request with `factory` (lane M: spec, plan, run, ship), acting as the user at each gate:

> People using the to-do API want to finish and tidy their lists. Let them mark a todo done or not done, delete a todo, and list only the open ones or only the done ones. Deleting must not disturb other todos' ids.

Stop when `factory-ship` has merged the epic branch into `main` locally and closed the epic, and `report.md` is written. Then run `factory-retro` and stop.
