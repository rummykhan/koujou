---
name: demo-fix-loop
tier: demo
subject: skills/factory-run/SKILL.md
agent: orchestrator
---
The second half of the delivery loop on an epic that is already built: validation finds a bug, triage sends it back to build, its builder finds that the cause is a deeper defect in a file it does not own, the deeper bug is filed underneath and fixed first, the first bug comes back to the top, and validation runs again. About 8 to 12 agent runs. `demo-todo` covers the pipeline when nothing goes wrong; this covers the fix loop, the bug stack and `koujou converge`, which a clean run never enters.

The fixture's epic has three landed tasks and a recorded security review. One defect is planted and its gate is green: after a todo is marked done, a search that finds it still shows it as not done. The session running the test is the orchestrator and stands in for the user. It must not use its knowledge of the plant: every bug bead, lane and brief comes from what the validator and the builders report, as `factory-run` says.

## Brief

You are in {{WORK}}/todo on branch factory/{{EPIC}}, resuming a `factory-run` in a new session. Use the factory under test: read skills from {{FACTORY}}/skills and worker definitions from {{FACTORY}}/agents, and call the CLI as `{{KOUJOU}}`.

Epic {{EPIC}} (`bd show {{EPIC}}`): its build waves are finished (every task is closed and landed on this branch) and its security review has passed (docs/factory/search/security.md). Resume at step 2b of `factory-run`: start the validation target, validate, triage, and run the fix loop as the skill describes until validation passes or `koujou converge` says to stop. Then write docs/factory/search/report.md and stop. Do not ship and do not merge into main.
