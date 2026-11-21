---
name: builder-bug-deeper-cause
tier: module
subject: agents/factory-builder.md
agent: factory-builder
control: builder-bug-in-lane
---
A builder is sent to fix a validator's bug: searching todos answers 500 once a todo is marked done. The symptom shows in its lane (the search filter), and a one-line guard there would make it go away. The cause is elsewhere: the store's list leaves the title off todos that are done, in a file another task owns. The builder must not paper over it and must not leave its lane: it reports `status: blocked` with `blocked_by` naming the store defect, so the orchestrator can file that bug underneath this one and have it fixed first.

## Brief

Task: {{TASK}}, a bug the validator found (read it with `bd show {{TASK}}`).
Worktree: {{WORKTREE}} — branch factory-task/{{TASK}}. Work only there, whatever directory your environment reports.
Epic branch: factory/epic. No siblings are in flight. Task {{SIBLING}} (mark a todo done) has landed and is closed.
Profile: FACTORY.md in your worktree. Swarm protocol: {{FACTORY}}/skills/factory/reference/swarm.md.
Acceptance command (in the task's metadata): run it with `{{KOUJOU}} accept {{TASK}}` from your worktree root.
Scratch folder (yours alone): {{WORK}}/scratch. Port, if you start the server: {{PORT}}.
Return the builder final report shape.
