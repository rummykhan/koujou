---
name: adopt-writes-profile
tier: module
subject: skills/factory-adopt/SKILL.md
agent: orchestrator
---
Setting the factory up in a project that already has code and its own rules: a to-do API that keeps its todos in a file (`data/todos.json`), with a short `AGENTS.md` of the owner's own and no factory files. The profile the setup writes is judged against what is true of the project, which the fixture fixes: the gate command, where the state lives (the Test map's first real use is here), the owner's rule kept, a baseline that was actually run, and nothing committed, built into the checkout or left behind.

There is no control scenario: the fixture's facts are the control.

## Brief

You are in {{WORK}}/todo, an existing project with no factory set up. Use the factory under test: read {{FACTORY}}/skills/factory-setup/SKILL.md and follow it (it leads to {{FACTORY}}/skills/factory-adopt/SKILL.md for an existing project), taking references from {{FACTORY}}/skills/factory/reference/ (not from ~/.claude), and call the CLI as `{{KOUJOU}}`.

The owner answered two things ahead of time: yes, initialise beads here with the prefix `td`; and this project has no remote and never deploys, so the factory may merge its own branches into `main` locally. They cannot be reached for anything else during this session: whatever you cannot find out goes under the profile's Open questions with your best guess, not into a question you wait on.

Scratch folder for anything temporary, including a throwaway worktree: {{WORK}}/scratch. Port, if you start the server: {{PORT}}. Return, as your final message, what you would show the owner at hand-over.
