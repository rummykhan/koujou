# Koujou 工場

**A software factory for Claude Code. Hand it an idea; a swarm of agents takes it to shipped, tested, validated software.**

**Platforms:** macOS, Linux

[![License](https://img.shields.io/github/license/rummykhan/koujou)](LICENSE)
[![Stars](https://img.shields.io/github/stars/rummykhan/koujou?style=flat)](https://github.com/rummykhan/koujou/stargazers)
[![Last commit](https://img.shields.io/github/last-commit/rummykhan/koujou)](https://github.com/rummykhan/koujou/commits/main)
[![Built for Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-D97757)](https://claude.com/claude-code)
[![Tasks by beads](https://img.shields.io/badge/tasks%20by-beads-4B32C3)](https://github.com/gastownhall/beads)
[![QA with Playwright](https://img.shields.io/badge/QA%20with-Playwright-2EAD33)](https://playwright.dev)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](https://github.com/rummykhan/koujou/pulls)

*Koujou* (工場, kōjō) is Japanese for "factory". It turns a raw request into requirements, a design and a dependency graph of tasks, then runs an orchestrated swarm of builder, reviewer and QA agents in parallel git worktrees until the work is validated. You approve at the gates; the factory does the rest, and improves itself after every run.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/flow-dark.svg">
  <img alt="Koujou pipeline: plan with your approval at each step, then a delivery loop of build, review, merge queue, validate and triage, shipped by pull request and followed by a retro" src="docs/flow-light.svg">
</picture>

## ⚡ Quick Start

```bash
# Install koujou (system-wide; also installs beads if you don't have it)
curl -fsSL https://raw.githubusercontent.com/rummykhan/koujou/main/install.sh | bash

# Wire up YOUR project
cd your-project
koujou init
```

Restart Claude Code, open it in your project, and run:

```text
/factory-setup
```

Then give it work:

```text
/factory add CSV export to the posts page
```

**Note:** Koujou is installed once and used everywhere. You don't clone this repository into your project.

`koujou init` is instant. Beads makes one commit for its own files when it is first set up; everything koujou adds is left uncommitted for you to review. It creates `.beads/` (the task database), `FACTORY.md` (the project profile), a factory block in `AGENTS.md` (how work gets done, plus the living system design), and makes `CLAUDE.md` import `AGENTS.md`. `/factory-setup` then reads your code, proves your test gate, and fills those files in.

## 🤖 Installing with an agent

Give your agent this repository and it can do the whole thing. The steps it should run:

```bash
curl -fsSL https://raw.githubusercontent.com/rummykhan/koujou/main/install.sh | bash
```

```bash
cd /path/to/your/project
koujou init
koujou doctor
```

Then restart Claude Code so the new skills and agent types load, and run `/factory-setup` in the project. Agents: don't commit the files `koujou init` creates unless asked; report which files changed.

Already installed? Update instead:

```bash
koujou update
```

## 🛠 Features

* **Idea to shipped:** requirements, system design, epics and tasks, build, review, QA, deploy, validation, bug triage.
* **Swarm in worktrees:** independent tasks are built at the same time, each agent in its own git worktree.
* **Merge queue:** finished branches land one at a time; the others rebase onto the result, and the agent that wrote a change resolves its own conflicts.
* **Security team, on demand:** `/factory-security-review` sends several agents to read a branch or pull request, each through one lens: access, untrusted input, data exposure, each time-boxed. It is not part of the delivery loop (it made runs several times slower); findings come back as beads and you decide what to fix now. Security closes holes without changing what your product does: a fix that would remove or restrict a feature is allowed only for serious harm (data, accounts, money, trust), and then you decide.
* **Acceptance tests close tasks:** every task's criteria name their checks before any code exists, and its tests carry the task id, so `koujou accept <task>` proves it done, at review, at landing and again before shipping.
* **Nobody grades their own work:** a separate reviewer checks every task against those criteria.
* **Time-boxed agents:** every agent's brief carries a time limit (a reviewer 30 minutes, a builder or the validator 60). Past it, a reviewer reports what it verified and marks the rest unverified; a worker that has gone quiet, builder, reviewer or validator, is noticed at the next landing and replaced, instead of being waited on for hours.
* **QA department:** a test engineer writes the acceptance suite from the requirements (Playwright for UIs); a validator uses the running product in a real browser, then reads back what it stored (the database, your cloud account, GitHub) wherever it has read access, and saves evidence. Everything is validated on a local build, so you need no cloud account; a deployed test environment is optional.
* **Works out how to test your project:** setup reads the code, the tests and the infrastructure and writes a test map: how each module is exercised, where its state lives and how to read that back. You are asked only about what it could not infer, before work starts. Ask it to check one module on its own (`/factory test the billing module`) and it does.
* **Ships by pull request:** the factory pushes the branch, opens the PR, waits for CI, merges when you approve, then checks the deploy and closes the issues. Production changes a normal deploy doesn't make (a new table, a migration) follow a fixed routine: diff first, apply only the expected change, verify, and check after the deploy that the shipped code is really using it.
* **Knows where the time went:** every task's build, review and queue time is recorded in beads; `koujou times` adds it up, with time spent waiting on you counted apart from work.
* **You are asked once:** API keys, access and decisions are requested up front, in one batch, including when the work comes from your existing backlog. What you can't provide is built against a fake and listed under "Waiting on you". Permission counts too: "may the factory create this table, or will you?" is asked at the start, not when the branch is finished.
* **Asks you can answer in a line:** anything that would block the merge reaches you while work continues, not in the final report. Wording and similar asks arrive as a draft to approve, and security findings are told in plain steps: who does what, and what you would lose.
* **Loops stop on evidence, not on a count:** validation and fixing go round as long as bugs are closing. A bug that hides a deeper bug waits while the deeper one is fixed first, then comes back to the top. The loop stops and comes to you when it is not converging: a fix that fails twice, a chain of bugs that keeps getting deeper, two rounds with no fewer bugs open, or the run's agent budget.
* **Living system design:** `AGENTS.md` holds an as-built description of your system, rewritten whenever an epic ships.
* **Self-improving:** every epic ends with a retro that edits the factory's own skills and worker instructions, logged in [`CHANGELOG.md`](CHANGELOG.md).
* **Fits your project:** `FACTORY.md` holds your commands, git and deploy policy; the skills stay generic.

## 📖 Commands

In your terminal:

| Command | Action |
| --- | --- |
| `koujou init` | Wire the current project: beads, `FACTORY.md`, `AGENTS.md`, `CLAUDE.md`. |
| `koujou doctor` | Check the installation and the current project. |
| `koujou accept <task-id>` | Run a task's acceptance tests (or `--parent <epic-id>` for all of an epic's). |
| `koujou times <epic-id>` | Time per task (build, review, queue), bounces, rebases and agents used. |
| `koujou ready <epic-id>` | The tasks of a run that can start now. Like `bd ready`, but a task that has landed and stays open until you merge counts as done, so the next wave shows up. Also lists what is in flight and for how long, and flags a worker that has been quiet far longer than any build so far. |
| `koujou spawned <id>...` | Count one agent run against a task, or against the epic for agents no single task owns (scouts, the validator), so `koujou times` and the run's budget see every agent. |
| `koujou converge <epic-id>` | After a validation round: may the fix loop go on? Says continue, which bug is stuck, or stop, from the run's record. |
| `koujou wait <epic-id> start\|end` | Mark when a run stops to wait for you and when it resumes, so `koujou times` reports waiting apart from work. |
| `koujou update` | Pull the latest koujou and relink. |
| `koujou uninstall` | Remove the links. Beads and your projects are untouched. |

In Claude Code:

| Command | Action |
| --- | --- |
| `/factory-setup` | Onboard a project, existing or empty. Run once. It follows `factory-adopt` for a codebase and `factory-new` for an empty directory; you don't call those yourself. |
| `/factory <request>` | Size the work and run the pipeline. |
| `/factory-spec` | Raw request → testable requirements. |
| `/factory-design` | Requirements → system design. |
| `/factory-plan` | Design → epics and a task graph in beads. |
| `/factory-run <epic-id>` | The delivery loop: build, review, merge queue, validate, triage. |
| `/factory-security-review <branch or PR>` | On demand: security agents read the change through three lenses; findings become beads. |
| `/factory-ship` | Pull request, CI, merge with your approval, deploy check, close the issues. |
| `/factory-retro` | Learn from the run and improve the factory. |

## 🔄 How a run goes

**1. You describe what you want.** The factory writes requirements with acceptance criteria and lists everything it needs from you.

```text
/factory let users export their posts as CSV
```

**2. You approve the requirements, the design (for bigger work) and the plan.** The plan is a graph of tasks in beads:

```bash
bd swarm validate <epic-id>
```

```text
Wave 1: 3 issues   ← built in parallel
Wave 2: 1 issues
Max parallelism: 3
```

**3. The swarm builds.** Each ready task gets a worktree and a builder; a QA tester writes acceptance tests alongside. Reviewers pass or bounce each branch; passing branches land one at a time, and the rest rebase. There is no security stage in the loop: run `/factory-security-review` on the branch or the pull request when you want one.

**4. QA.** The acceptance suite runs and a validator uses the real product, locally. Bugs are triaged: fix now (back into the loop) or defer to the next phase.

**5. It ships.** You get a report (what was built, the evidence, the time it took, what was deferred, what is waiting on you) and a pull request. Approve, and the factory merges it and checks the deploy.

See what's happening at any time:

```bash
bd epic status
```

```bash
bd list --label factory:needs-user --status open
```

## 🏭 The workers

| Worker | Job |
| --- | --- |
| **Orchestrator** | Your Claude Code session. Briefs agents, merges, records state in beads, talks to you. |
| `factory-builder` | Implements one task in its own worktree. |
| `factory-reviewer` | Independently checks a task against its acceptance criteria. Read-only. |
| `factory-security` | On demand only (`/factory-security-review`): several at once, each hunting exploitable defects through one lens. Read-only. |
| `factory-tester` | QA. Writes the automated acceptance suite from the requirements. |
| `factory-validator` | QA. Exercises the running product like a user. |

Workers coordinate through a per-task mailbox (beads comments) and never touch each other's files. The rules are in [`skills/factory/reference/swarm.md`](skills/factory/reference/swarm.md).

## 📁 What's in this repo

| Path | What |
| --- | --- |
| [`skills/`](skills) | The pipeline stages, as Claude Code skills. |
| [`skills/factory/reference/`](skills/factory/reference) | Conventions: beads, swarm protocol, blockers, templates. |
| [`agents/`](agents) | The worker definitions. |
| [`bin/koujou`](bin/koujou) | The CLI. |
| [`CHANGELOG.md`](CHANGELOG.md) | What the factory changed about itself, and why. |
| [`tests/`](tests) | The factory's own tests: static checks, CLI tests, and agent scenarios. |
| [`lab/`](lab) | Notes from the test runs the factory was developed against. |

## 🤝 Contributing

The factory is tested like software. Before opening a pull request:

```bash
tests/run.sh
```

That runs the static checks and the CLI tests in a few minutes, with no model. If you changed a skill or a worker, open Claude Code in this repository and run the scenarios for it:

```text
/factory-test
```

A new rule comes with a scenario that fails without it. [`tests/README.md`](tests/README.md) explains how the tests are designed and how to add one.

## ✅ Requirements

* [Claude Code](https://claude.com/claude-code)
* `git` and `bash`
* [beads](https://github.com/gastownhall/beads) (`bd`), installed for you by the installer

## 🧪 Status

Koujou is new. It has delivered two epics and a six-issue backlog pass end to end in a lab project (through a pull request, CI and merge), and two backlog passes on a live Next.js product: four issues, then six, the second through pull request, merge, a production deploy the factory watched, and a smoke check of the live site. It has also taken a new infrastructure library, [shukka](https://github.com/rummykhan/shukka), through requirements, design, planning and some 30 tasks, validated by a live acceptance suite against a real AWS account; that run is why the security review left the loop and agents got time limits (see [`CHANGELOG.md`](CHANGELOG.md)). Not yet exercised with real agents: validation of a deployed test environment, a task marked stuck, `/factory-security-review` on its own, and a brand-new project (`/factory-setup` on an empty directory). See [`lab/README.md`](lab/README.md) for exactly what has and has not been tested.

## 📝 License

[MIT](LICENSE)
