---
name: tester-writes-acceptance
tier: module
subject: agents/factory-tester.md
agent: factory-tester
---
The QA task of an epic whose feature does not exist yet: the tester gets the requirements and writes the acceptance tests before any builder has landed. It is judged by what its tests do afterwards, not by how they read: the same feature is then built twice in a copy of its branch, once correctly and once with a planted defect (`done` is always set to true and the body is not validated), and the tester's tests must pass on the first and fail on the second. A suite that passes both was written to be green, and one that fails both asserted something the requirements never said.

There is no separate control scenario: the correct build is the control, inside `expect.sh`.

## Brief

QA task: {{TASK}} (`bd show {{TASK}}`), the acceptance tests for epic {{SIBLING}} (`bd show {{SIBLING}}`).
Worktree: {{WORKTREE}} — branch factory-task/{{TASK}}. Work only there, whatever directory your environment reports.
Requirements: docs/factory/done/requirements.md in your worktree. Profile: FACTORY.md in your worktree (QA section). Swarm protocol: {{FACTORY}}/skills/factory/reference/swarm.md.
The feature is not built yet; one builder task is in flight and its branch is not yours to read.
Run your tests with `{{KOUJOU}} accept {{TASK}}` from your worktree root (the command is in the task's metadata).
Scratch folder (yours alone): {{WORK}}/scratch. Port, if you start the server: {{PORT}}.
Return the factory-tester final report shape.
