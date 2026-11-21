---
name: builder-bug-in-lane
tier: module
subject: agents/factory-builder.md
agent: factory-builder
control-for: builder-bug-deeper-cause
---
The control: the same bug with the same symptom, but its cause is in the search filter itself, inside the builder's lane. The builder must simply fix it: status done, a test carrying the bug's id, the gate green, the store untouched. A builder that reports every bug as blocked would pass the other scenario and fail this one.

## Brief

Task: {{TASK}}, a bug the validator found (read it with `bd show {{TASK}}`).
Worktree: {{WORKTREE}} — branch factory-task/{{TASK}}. Work only there, whatever directory your environment reports.
Epic branch: factory/epic. No siblings are in flight. Task {{SIBLING}} (mark a todo done) has landed and is closed.
Profile: FACTORY.md in your worktree. Swarm protocol: {{FACTORY}}/skills/factory/reference/swarm.md.
Acceptance command (in the task's metadata): run it with `{{KOUJOU}} accept {{TASK}}` from your worktree root.
Scratch folder (yours alone): {{WORK}}/scratch. Port, if you start the server: {{PORT}}.
Return the builder final report shape.
