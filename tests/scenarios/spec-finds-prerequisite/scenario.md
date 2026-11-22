---
name: spec-finds-prerequisite
tier: module
subject: skills/factory-spec/SKILL.md
agent: orchestrator
---
The first stage on its own: a raw request that sounds small and needs two things only the user can provide (a way to send email, and a way to receive replies), plus a choice nobody stated (whose morning, in which time zone). The session cannot reach the user. A spec stage that does its job writes testable requirements, finds the prerequisites before anyone builds, asks, and stops at its gate. One that does not either approves its own work or leaves the missing mail service for a builder to discover.

There is no control scenario: the checks are about what must be in the artifact and what must not have happened (no approval, no code, no tasks).

## Brief

You are in {{WORK}}/todo, a small to-do API already set up for the factory (`FACTORY.md`, `AGENTS.md`, beads with prefix `td`). Use the factory under test: read {{FACTORY}}/skills/factory-spec/SKILL.md and follow it, taking its references from {{FACTORY}}/skills/factory/reference/ (not from ~/.claude, which may hold an older install).

The request, from the user:

> Email me my open todos every morning at 8, and let me mark a todo done by replying to that email.

The user cannot be reached during this session. Do not answer for them and do not approve anything on their behalf: go as far as the stage's gate, then stop and return, as your final message, exactly what you would show them there.
