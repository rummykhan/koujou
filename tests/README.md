# Testing the factory

Koujou is mostly prose: skills and worker definitions that agents follow. A typo in a script fails loudly; a weak sentence in a worker file fails quietly, weeks later, as a bug a reviewer waved through. These tests exist to make the second kind fail loudly too, before a change is pushed.

```bash
tests/run.sh          # tiers 0 and 1: seconds, no model. CI runs this on every pull request.
```

```text
/factory-test                 # the above, then the scenarios for whatever you changed
/factory-test the reviewer    # one module
/factory-test demo            # the whole pipeline on a small to-do app
```

`/factory-test` is a Claude Code skill that lives in this repository (`.claude/skills/factory-test`), so it is available when you open Claude Code here.

## Three tiers

| Tier | What it checks | Needs | Cost |
|---|---|---|---|
| **0. Static** (`tests/static/check.py`) | The prose is consistent with itself: every skill, worker, file, label, limit and `koujou` command that one file names exists in another; frontmatter is valid; scripts parse; scenarios are well formed | python3 | under a second |
| **1. CLI** (`tests/cli/test_koujou.sh`) and scenario setups | `koujou init`, `doctor`, `accept` and `times` against real beads in a temp directory; every scenario's fixture still builds | beads | seconds |
| **2. Module scenarios** (`tests/scenarios/*`, `tier: module`) | One worker or one rule, in a prepared situation, judged by what is true afterwards | Claude Code | one agent, under a minute each |
| **3. Demo** (`tests/scenarios/demo-todo`) | The whole pipeline, from a raw request to a merged branch | Claude Code | 15 to 25 agent runs |

Run the cheapest tier that can fail for your change first. Most mistakes in a skill edit are broken references, and tier 0 finds those for free.

## How a scenario is built

```
tests/scenarios/<name>/
  scenario.md   what it tests and why, and the exact brief the agent receives
  setup.sh      builds the situation in a temp directory, deterministically
  expect.sh     checks the outcome; one line per check, exit code 0 or 1
```

The pattern is the one behind agent evaluations generally, kept as small as it will go:

1. **A fixture with one planted thing.** `setup.sh` builds a small real repository (the to-do app in `tests/fixtures/todo`, with git history and a beads database) and puts it in a state that calls for one specific behaviour: a branch with a defect the gate does not catch, a rebase that conflicts, a task whose acceptance command selects no tests yet. Variants of a change come from `tests/fixtures/variants/make.py`, so a scenario and its control differ in exactly one thing.
2. **The real brief, nothing more.** The agent gets the brief the orchestrator would send, as written in `scenario.md`. It is never told it is being tested or where the defect is. If the scenario only passes with a hint, the instruction under test is not doing its job.
3. **Judge outcomes, not transcripts.** `expect.sh` looks at the repository, the tracker and the structured fields of the agent's final report (`verdict: fail`, `severity: high`). It does not care which commands the agent ran or what it said along the way. This is what keeps tests alive when a worker's wording changes: only its results are pinned.
4. **Every detector has a control.** A reviewer that fails everything would pass "reviewer fails a weak build". So that scenario is paired with "reviewer passes a good build", and the two always run together (`control:` and `control-for:` in the frontmatter). Add the pair, never the half.
5. **Check the negative space.** What the agent must not have done is half of most worker rules: a reviewer that edited the worktree, a builder that closed its own bead or merged its branch, a security agent that left a server running. These are cheap `check` lines and they catch the worst failures.
6. **Twice before it is a failure.** Agents are not deterministic. `/factory-test` re-runs a failing scenario once from a fresh setup and reports `flaky` or `fail`. Flaky is a real result: the instruction is not strong enough to hold every time.

`expect.sh` uses three helpers from `tests/lib/expect.sh`: `check "<what>" <command>`, `report_has "<what>" <regex>` and `report_lacks`. Keep each check to one thing, and word it so that the failing line alone tells the reader what went wrong.

## Adding a test with your change

A new rule in a skill or worker file should arrive with a scenario that fails without it, the same way a code change arrives with a test.

1. Decide what an agent following the new rule does differently, and what you could observe afterwards.
2. Copy the nearest scenario directory. Set `name`, `tier`, `subject` (the file whose behaviour you are testing) and `agent` in the frontmatter.
3. Write `setup.sh` so the situation needs the rule. Prefer a new variant in `make.py` over hand-edited fixture files.
4. Write `expect.sh`, and a control scenario if yours detects something.
5. Prove the test tests something: run it against the factory **without** your change and watch it fail, then with it.
6. `tests/run.sh` (the static tier checks your scenario is well formed), then `/factory-test <your subject>`.

Changes to the CLI get a line in `tests/cli/test_koujou.sh` instead. A new cross-reference rule (a new kind of name one file may use from another) gets a check in `tests/static/check.py`.

## What is covered

| Subject | Scenarios |
|---|---|
| `agents/factory-reviewer.md` | `reviewer-fails-weak-build`, `reviewer-passes-good-build` |
| `agents/factory-security.md` | `security-finds-traversal`, `security-passes-clean-build` |
| `agents/factory-builder.md` | `builder-meets-acceptance` |
| `skills/factory/reference/swarm.md` | `builder-rebases-conflict` |
| `skills/factory-run/SKILL.md` and the stages around it | `demo-todo` |

Not covered yet, and good first contributions: `factory-tester` and `factory-validator` (a fixture with a page and a planted UI bug), `factory-spec` and `factory-plan` on their own (a raw request in, a lint-clean plan with acceptance commands out), the stuck path at the attempt cap, and `factory-ship` against a remote.

## Demo baseline

Compare a demo run's `koujou times` with the last one recorded here; a change that doubles a number deserves a sentence in the pull request.

| Date | Result | Tasks | Agent runs | First claim to validated | Bounces | Rebases |
|---|---|---|---|---|---|---|
| 2026-11-20 | 20 of 20 checks | 4 | 17 | 7 m 54 s | 0 | 1 |

## Limits worth knowing

- Tier 2 and 3 need Claude Code and spend tokens, so CI does not run them. The person changing a worker runs its scenarios and says so in the pull request.
- A passing scenario shows the instruction worked on this fixture, this time. It is evidence, not proof. The lab notes in `lab/README.md` and the changelog are the longer record.
- The demo's assertions cannot see waste. Compare `koujou times` between demo runs for that.
