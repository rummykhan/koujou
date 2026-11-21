---
name: factory-test
description: Test the software factory itself before a change is pushed. Runs the deterministic checks, then scenarios that exercise one worker or one stage against a fixture with a planted defect, or the full demo that takes a small to-do app through the whole pipeline. Use when working in the koujou repository and the user says "test the factory", "run the factory tests", "test the reviewer" (or any single module), "run the demo", or before committing a change to any skill, worker or the CLI.
---

# Testing the factory

The factory is instructions that agents follow, so it is tested the way any agent behaviour is: put the agent in a prepared situation and check what is true afterwards. `tests/README.md` explains the design and how to add a test; read it before writing one.

## What to run

| Asked for | Run |
|---|---|
| "test the factory", or before any push | Tier 0 and 1, then the module scenarios whose subject changed (below). All module scenarios if a shared file changed (`skills/factory/reference/*`, `bin/*`) or if asked for everything. |
| "test the reviewer", "test security", a file path | Tier 0 and 1, then every scenario whose `subject` is that file, and their controls |
| "run the demo", or a change to `factory-run`, `factory-plan`, `factory-ship` or the swarm protocol | Everything above, then `demo-todo` |

Say which tiers you are running and roughly what they cost before starting anything with agents: a module scenario is one agent for under a minute; the demo is 15 to 25 agent runs and tens of minutes.

## Tier 0 and 1: deterministic

```bash
tests/run.sh
```

Static checks, the CLI against real beads, and every scenario's setup. Seconds, no model. If this fails, fix it before spending agents; do not run scenarios on a factory whose references are broken.

## Module scenarios

To find what changed: `git diff --name-only origin/main...HEAD` plus uncommitted files, matched against each scenario's `subject:` line (`grep -l "^subject: <path>" tests/scenarios/*/scenario.md`). A scenario with a `control:` or `control-for:` line always runs with its partner.

For each selected scenario, with a fresh work directory under your scratchpad:

1. `bash tests/scenarios/<name>/setup.sh <work>/<name>`. It prints nothing on success and writes `task`, `worktree` and sometimes `sibling` into the work directory. Give each scenario its own port, checked to be free, and write it into `<work>/<name>/port`: `tests/lib/freeport.sh <start>`, with a start ten apart for each scenario. Never guess one.
2. Fill the `## Brief` section of `scenario.md`: `{{TASK}}`, `{{SIBLING}}`, `{{WORKTREE}}`, `{{PORT}}` and `{{WORK}}` from those files, `{{FACTORY}}` with this repository's absolute path, `{{KOUJOU}}` with `<this repo>/bin/koujou`. Send the brief as written. Do not add hints, and never tell the agent it is being tested or what the planted defect is: the scenario measures what the instructions produce on their own.
3. Spawn the agent named in `agent:`. To test the worker file as it is in this checkout rather than as installed, use a general-purpose agent whose prompt starts "Read `<this repo>/agents/<agent>.md` and take that role." followed by the brief. Do this whenever a worker file was edited in this session: an installed agent type may still be running the file as it was when the session started, and a type added in this session is not registered at all. (On 2026-11-21 an installed `factory-security` run minutes after an edit lacked a new report field, while an installed `factory-builder` run later the same session had its new field; do not rely on either.) To show that a scenario fails without your change, give a general-purpose agent the previous version of the file (`git show <commit>:agents/<agent>.md`). Spawn all selected scenarios in one message so they run in parallel.
4. Save each agent's final message, verbatim, to `<work>/<name>/report.txt`.
5. `bash tests/scenarios/<name>/expect.sh <work>/<name> <work>/<name>/report.txt`. Exit 0 is a pass; every line it prints is one check.

A scenario that fails once is run once more from a fresh setup before you call it a failure; agents are not deterministic, and the distinction matters. Report it as `fail` (twice) or `flaky` (once), and for either, read the agent's report and say what it did. A flaky result is still a finding: it usually means the instruction is too weak to hold every time.

## The demo

`tests/scenarios/demo-todo`. You are the orchestrator, and you stand in for the user at the gates as its `scenario.md` describes. Run its setup, follow its brief with the factory's skills read from this checkout, then run its `expect.sh` (the report argument can be the delivery report). Keep `koujou times <epic>` from the run: comparing it with the last demo's numbers in `tests/README.md` shows whether a change made the factory slower or more wasteful, which no assertion catches.

## Reporting

One table: tier or scenario, result (`pass`, `fail`, `flaky`, `not run`), and for anything not `pass`, the check that failed and what the agent actually did. Then the verdict in one line: safe to push, or not and why. Never report a tier you did not run as passed; say `not run` and why.

A failure is a fact about the factory, not about the test, until shown otherwise. Do not weaken an `expect.sh` to get green. If the expectation is wrong, say so and change it in its own commit with the reason.

## After a change to the factory

A new rule in a skill or worker file comes with a scenario that fails without it, the same way a code change comes with a test. If you cannot write one, say so in the changelog entry.
