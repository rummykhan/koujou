---
name: builder-meets-acceptance
tier: module
subject: agents/factory-builder.md
agent: factory-builder
---
A builder is given one task with an acceptance command that currently selects no tests. It must end with that command passing on tests named with the task id, the gate green, its commit on its own branch, nothing changed outside its lane, and no bead state written.

## Brief

Task: {{TASK}} (read it with `bd show {{TASK}}`).
Worktree: {{WORKTREE}} — branch factory-task/{{TASK}}. Work only there, whatever directory your environment reports.
Epic branch: factory/epic. No siblings are in flight.
Profile: FACTORY.md in your worktree. Swarm protocol: {{FACTORY}}/skills/factory/reference/swarm.md.
Acceptance command (in the task's metadata): run it with `{{KOUJOU}} accept {{TASK}}` from your worktree root. It fails now because no test carries the task id.
Scratch folder (yours alone): {{WORK}}/scratch. Port, if you start the server: {{PORT}}.
Return the builder final report shape.
