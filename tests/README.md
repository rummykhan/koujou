# Testing the factory

Koujou is mostly prose: skills and worker definitions that agents follow. A typo in a script fails loudly; a weak sentence in a worker file fails quietly, weeks later, as a bug a reviewer waved through. These tests exist to make the second kind fail loudly too, before a change is pushed.

```bash
tests/run.sh          # tiers 0 and 1: a few minutes, no model. CI runs this on every pull request.
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
| **1. CLI** (`tests/cli/test_koujou.sh`) and scenario setups | `koujou init`, `doctor`, `accept`, `ready`, `spawned`, `times`, `wait` and `converge` against real beads in a temp directory; every scenario's fixture still builds | beads | one to two minutes in CI, five or more on a laptop |
| **2. Module scenarios** (`tests/scenarios/*`, `tier: module`) | One worker, or one stage (spec, plan, adopt) run on its own up to its gate, in a prepared situation, judged by what is true afterwards | Claude Code | one agent each: under a minute for a worker, two to three for a stage. The two browser scenarios share one browser: run them one after the other |
| **3. Demo** (`tests/scenarios/demo-todo`, `demo-fix-loop`) | The whole pipeline, from a raw request to a merged branch; and the fix loop on a built epic with a planted bug whose cause is one level deeper | Claude Code | 12 to 25 agent runs; 6 to 12 for the fix loop |

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
4. **Every detector has a control.** A reviewer that fails everything would pass "reviewer fails a weak build". So that scenario is paired with "reviewer passes a good build", and the two always run together (`control:` and `control-for:` in the frontmatter). Add the pair, never the half. A control can also live inside one scenario's `expect.sh`, when the thing under test produces something that can be run: `tester-writes-acceptance` builds the feature correctly and wrongly under the tester's tests and requires pass on one and fail on the other.
5. **Check the negative space.** What the agent must not have done is half of most worker rules: a reviewer that edited the worktree, a builder that closed its own bead or merged its branch, a security agent that left a server running. These are cheap `check` lines and they catch the worst failures.
6. **Judge by what the output does, where it does anything.** A report can say the right words about work that is wrong. When a worker produces something executable (tests, a fix, a script), run it against a known-good and a known-bad case rather than reading its report: a tester's suite against two builds, a builder's fix against the reproduction. Reports are the judge only for workers whose product is a judgement (reviewer, security, validator), and there the control scenario keeps them honest.
7. **Keep the fixture as awkward as real projects.** Each real project broke something the tidy fixture never did: a code repository apart from the tracker, issues that stay open until someone merges, a test runner that prints the directory but no test names. When a run on a real project trips on its shape, the shape goes into tier 1 as a test before the fix is called done.
8. **Twice before it is a failure.** Agents are not deterministic. `/factory-test` re-runs a failing scenario once from a fresh setup and reports `flaky` or `fail`. Flaky is a real result: the instruction is not strong enough to hold every time.

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
| `agents/factory-reviewer.md` | `reviewer-fails-weak-build`, `reviewer-fails-hollow-tests` (a correct product whose acceptance tests would pass on a broken one), `reviewer-passes-good-build` |
| `agents/factory-security.md` (used by `skills/factory-security-review`, on demand) | `security-finds-traversal`, `security-passes-clean-build` |
| `agents/factory-builder.md` | `builder-meets-acceptance`, `builder-bug-deeper-cause`, `builder-bug-in-lane` |
| `agents/factory-tester.md` | `tester-writes-acceptance` (its tests must pass on a correct build of the feature and fail on a planted wrong one) |
| `agents/factory-validator.md` | `validator-finds-kept-record`, `validator-passes-stored-build` (the store disagrees with the interface); `validator-finds-forgotten-tick`, `validator-passes-page` (in a real browser: a page that shows a change the API never received) |
| `skills/factory-spec/SKILL.md` | `spec-finds-prerequisite` (a small-sounding request that needs two things only the user has; stops at its gate) |
| `skills/factory-plan/SKILL.md` | `plan-covers-design` (the plan judged as data: lint, swarm, acceptance commands that fail now, every row of the design owned by a task) |
| `skills/factory-adopt/SKILL.md` | `adopt-writes-profile` (a project with its own rules and a file-backed store; the profile judged against the fixture's facts) |
| `skills/factory/reference/swarm.md` | `builder-rebases-conflict` |
| `skills/factory-run/SKILL.md` and the stages around it | `demo-todo` (a clean run), `demo-fix-loop` (validation finds a bug; triage, the bug stack, `koujou converge`) |

Not covered yet, and good first contributions: `factory-design` on its own; the tester's reviewer catching a suite that passes on a wrong stand-in product; the stuck path (a fix that fails validation twice, a chain deeper than `max_fix_depth`) with real agents; `factory-ship` against a remote; `factory-retro`; and two rules in `factory-run` that only an orchestrator in a long run meets: replacing a worker gone quiet (the flag itself, in `koujou ready`, is tested in tier 1) and fixing a pre-existing security finding whose harm the epic raises (seen once, in a `demo-todo` run, without being asked for). The CLI tier covers what the second real project's shape broke: a code repository apart from the tracker (`BEADS_DIR`), tasks left open until the merge (`koujou ready`, `koujou converge`), a runner that prints the worktree path but no test names (`koujou accept`), and agents nobody counted (`koujou spawned`).

## Demo baseline

Compare a demo run's `koujou times` with the last one recorded here; a change that doubles a number deserves a sentence in the pull request.

| Date | Result | Tasks | Agent runs | First claim to validated | Bounces | Rebases |
|---|---|---|---|---|---|---|
| 2026-11-20 | 20 of 20 checks | 4 | 17 | 7 m 54 s | 0 | 1 |
| 2026-11-21 | 20 of 20 checks | 4 | 12 | 10 m 42 s | 0 | 0 |
| 2026-11-22 | 20 of 20 checks, after one fix (deferred bugs filed without reproduction steps failed `bd lint`) | 5 (4 planned, 1 security fix) | 15 | 13 m 57 s | 0 | 0 |

`demo-fix-loop`:

| Date | Result | Bugs filed | Agent runs | First validation to passing one | Rounds | Open after each round |
|---|---|---|---|---|---|---|
| 2026-11-21 | 16 of 16 checks | 2 (one under the other) | 8 | 7 m 36 s | 2 | 1, 0 |
| 2026-11-22 | 17 of 17 checks (one check added: `bd lint`) | 2 (one under the other) | 6 | 13 m 40 s (the orchestrator was also running other tests) | 2 | 1, 0 |
| 2026-11-22, second run | 17 of 17 checks | 2 (one under the other) | 7, counted with `koujou spawned` (5 on tasks, 2 for the run) | 6 m 01 s | 2 | 1, 0 |

## Limits worth knowing

- Tier 2 and 3 need Claude Code and spend tokens, so CI does not run them. The person changing a worker runs its scenarios and says so in the pull request.
- A passing scenario shows the instruction worked on this fixture, this time. It is evidence, not proof. The lab notes in `lab/README.md` and the changelog are the longer record.
- The demo's assertions cannot see waste. Compare `koujou times` between demo runs for that.
