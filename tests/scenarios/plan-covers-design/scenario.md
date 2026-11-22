---
name: plan-covers-design
tier: module
subject: skills/factory-plan/SKILL.md
agent: orchestrator
---
The planning stage on its own: approved requirements and an approved design in, a task graph in beads out. The design's tables hold two rows that no requirement's acceptance line repeats in full (a response header on the list, and a line logged on every delete), which is how a row ends up owned by no task: on the second real project a "source of the data" line was in the design's component table, in no task's criteria, and was left out by a builder who said so. The plan is judged as data: lint, the swarm analysis, an acceptance command on every task that fails now, a check named on every criterion, a QA task, and every row of the design's tables findable in some task's criteria.

There is no control scenario: every check is on the plan itself.

## Brief

You are in {{WORK}}/todo, a small to-do API already set up for the factory (`FACTORY.md`, `AGENTS.md`, beads with prefix `td`). Use the factory under test: read {{FACTORY}}/skills/factory-plan/SKILL.md and follow it, taking its references from {{FACTORY}}/skills/factory/reference/ (not from ~/.claude), and call the CLI as `{{KOUJOU}}`.

The work order is docs/factory/tidy/: `requirements.md` and `design.md` are both approved (lane L). Plan it: write `plan.json` there, create the graph in beads, store each task's acceptance command, and verify the plan as the skill says.

The user cannot be reached during this session. Go as far as the plan gate, then stop and return, as your final message, what you would show them there. Do not start building.
