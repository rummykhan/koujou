---
name: factory-security-review
description: Standalone, on-demand security review of a branch, an epic, a pass or a pull request — several factory-security agents each reading the change through one lens (access, input, exposure), findings checked and filed as beads. Not part of factory-run; use only when the user asks for a security review ("security review this", "run the security team on the epic", "check this branch for holes").
---

# Factory: security review (on demand)

The delivery loop (`factory-run`) does not run a security review. It used to, and on shukka v1 the security loop took most of an 18-hour run: untimed agents building live proofs for 12–16 hours each, then findings turned into a second, serial build loop. The user took it out on 2026-11-22. This skill is the same review, run when the user asks for it, on whatever they point it at, and its findings become beads; it does not hold up a merge unless the user says so.

## Inputs

- **The target:** an epic or pass branch (`factory/<id>`), a task branch, a pull request, or a range. Work out the diff command: `git diff origin/<base>...<branch>` (three dots).
- `FACTORY.md` (its `Security review` section: trust boundaries, what is out of bounds, project-specific lenses), the System design in `AGENTS.md`, and the requirements if there are any.
- How to start the product locally, from the profile. Agents attack the local build only, never a deployed environment, cloud account or real third-party account.

## 1. Spawn the lenses

Spawn `factory-security` agents **in one message**, one per lens:

| Lens | Looks at |
|---|---|
| `access` | sign-in, sessions, authorisation on every changed route, separation between users or tenants |
| `input` | injection, scripting, redirects, server-side requests, uploads, forgery, unbounded input |
| `exposure` | secrets, data returned or logged, headers and cookies, new dependencies, cryptography |

All three by default. For a small change that touches no route, session, input handling, dependency or config, one agent covering all lenses is enough. The profile may add project-specific lenses (payments, tenancy, a compliance rule).

Each brief has: its lens; the worktree path and the diff command; the paths to `FACTORY.md` and the requirements; what the change protects, not only its diff, with leave to read outward; a scratch folder and a port of its own (never a shared temp directory; agents have deleted each other's files there); how to start the product locally; and **a time box: 30 minutes**. After that, a finding the agent has not proven live is reported as `reasoned`, with the code-level argument. Live proofs that pull images or build environments are what made the old loop slow; a reasoned finding checked against the code is enough to decide on. Count each spawn: `koujou spawned <epic or task> --role security`, and `koujou reported` when it reports.

Watch them: an agent that has not reported well past the time box is checked (`ps`, its scratch folder) and stopped.

## 2. Check the findings

Agents working alone over-report and occasionally invent, so check before acting:

- Read each finding's proof. An `observed` proof you re-run if it is cheap. A `reasoned` one you check against the code; if you cannot tell, one second agent may confirm or refute that one finding, given the finding but not the first agent's confidence.
- **Refuted** → note it with why.

## 3. File them

- **Critical or high, confirmed** → a `bug` bead, P0 or P1, label `security`, with the attack as its steps to reproduce and "the attack no longer works, shown by a test" as a criterion. Tell the user at once with the finding's `plain` account (who does what, in order, and what the victim loses), whether it was observed or reasoned, and your recommendation: fix before merging, or merge and fix next. If it is pre-existing, it is in production now; say so.
- **Medium or low** → a `factory:deferred` bead with label `security`.
- **A fix that would change a feature** (`changes_feature: yes`, or you can see it would) → never built on the security review's word. Look for a fix that keeps the feature as specified; if there is none and the harm is serious, it is the user's decision (a `decision` bead with a gate).

Every bead gets `## Steps to Reproduce`; run `bd lint`. Fixing is ordinary work: a fix bead the user wants now goes through `factory-run` like any task (builder, reviewer, merge queue). A re-check of the fix is this skill again, on that branch, only if the user asks.

## 4. Record

Write `<work order>/security.md` (or, with no work order, report in the conversation): target and commit, lenses run, what each covered and did not, findings with their fate and bead ids. Stamp `security_at` on the epic if there is one. Report to the user in a few lines: verdict, what is critical or high with its plain account, and the bead ids of the rest.
