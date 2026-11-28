---
name: factory-adopt
description: Onboard an existing codebase into the software factory. Use when a project that already has code has no FACTORY.md and the user wants the factory to work on it, or when FACTORY.md has gone stale and needs refreshing.
---

# Factory: adopt an existing project

This is the existing-project path of `factory-setup`, which also handles beads, `AGENTS.md` and `CLAUDE.md`. If you were invoked directly, run `factory-setup` so those are not skipped.

Produce `FACTORY.md`, the profile every factory stage reads, by finding out how this project actually works. The aim is to fit the factory to the project. An existing project has conventions that work; replacing them with the factory's defaults creates a second source of truth that drifts.

## 1. Discover (read-only)

Find out, by reading and by running harmless commands:

- **What it is**: README, top-level docs, package manifests, directory layout. Which folders are the user's code and which are vendored or upstream. Whether the code is in this repository at all: a workspace repository that holds the tracking (beads, roadmap, specs) with the product checked out inside it as its own git-ignored repository is two repositories, and the profile must say which one each command, branch and worktree belongs to. Check that beads is reachable from where the code is: run `bd show` on any issue from inside the code repository. If it finds no database, the profile's Beads section gives the `BEADS_DIR` every worker and every `koujou accept` run must set.
- **Rules**: `CLAUDE.md`, `AGENTS.md`, project skills in `.claude/skills`, contributor docs. Note hard rules (no deploy without confirmation, forbidden APIs, commit style).
- **Commands**: install, lint, typecheck, test, build, run. Take them from manifests and CI config, since CI is what the project really enforces.
- **What a local run touches**: the database, buckets and third parties the product talks to when started on this machine. A project with no local database and no test account reads, and may write, production from a laptop. Find that out here, from the configuration defaults, not during validation.
- **Git and deploy**: default branch, branch protection, what a push to the default branch triggers, how deploys happen and who triggers them, environments and their URLs, whether a rollback procedure exists. Existing worktrees (`git worktree list`) and what they are for, so the factory's worktree root does not land among them.
- **Existing planning artifacts**: requirements, specs, decision log, roadmap, pitfalls. These become the Docs map.
- **Beads**: is `.beads/` present? If so, with `--readonly`: `bd status`, `bd ready`, `bd lint`, issue types and labels in use, whether it syncs to a remote, any project-specific bead rules.
- **Test reality**: which areas have tests and which have none.
- **How each module is tested, and where its state lives**: for every module a user or another system touches, how it is reached (page, route, command, job) and what it writes to (a table, a bucket, a file, a third party). Read this from the code, the existing tests, env files and the infrastructure definitions (CDK, CloudFormation, Terraform, a compose file). Then find out what this machine can already read, with calls that change nothing: the local database or its emulator, `aws sts get-caller-identity` and the profiles in use, `gcloud auth list`, `gh auth status`. Use only access the project already names; never go looking for other credentials.

A large or unfamiliar repo is worth one Explore agent for this; a small one is quicker to read directly.

## 2. Prove the gate

Run the gate on a clean checkout of the base branch and record the result in the profile's Baseline section. The delivery loop attributes every later failure to the task in flight, so it needs a known baseline.

- **Is the base current?** `git fetch` and compare with the remote (`git status -sb`). A baseline measured on a stale base describes code nobody will build on; tell the user rather than pulling for them.
- **One gate per package.** A repo with several packages usually has several gates; CI config shows them. Record each, and which ones you could not run and why.
- **Run it twice.** A test that fails once and passes on rerun is the most expensive kind of baseline problem: it will later be blamed on an innocent task. When that happens, look for state that survives between runs (a local database, a cache, fixed ports, files in tmp) and say what you found.

- **A red gate may be your own shell.** Before recording a failure, ask whether the command needs something your shell is denied: a build that downloads fonts or packages fails in a network-sandboxed shell with an error that names the code, not the network. Run it once with network access. Only a failure that survives that is the project's.
- **Build where the user is not working.** A build or dev server run in the user's checkout overwrites their build output under whatever they have running. Prove app builds in the throwaway worktree below.

If the gate is red or cannot run (missing services, secrets), that is the first thing to tell the user: the factory can plan here but cannot deliver until it is fixed. Don't run anything that deploys, bills, or writes outside the repo.

Also work out what a fresh git worktree needs before the gate passes there (install, env files, generated code), and what has to differ between two worktrees running at once (ports, a database name or table prefix). Prove it: create a throwaway worktree outside the repo, run the setup and the gate there, then remove it. If you cannot prove it, set `max_parallel_builders` to 1 and say why; an unproven worktree recipe fails in the middle of a wave.

## 3. Write `FACTORY.md`

Start from `~/.claude/skills/factory/reference/profile-template.md` and fill every section with what you found. Guidelines:

- Point to existing rules; don't restate them.
- Map the Docs map onto what exists. Only default to `docs/factory/<slug>/` for artifacts the project has no home for.
- If pushing or merging to the base branch deploys to production, the git policy must say the factory works on branches and the user merges.
- Record gaps honestly under "Known gaps in the gate"; the validator leans on that list.
- Fill the Test map from what you inferred, one row per module, and try each cross-check once so the row is a command that ran, not a guess. A module you cannot work out how to exercise, or whose state you cannot read, still gets its row, marked "interface only" or "unknown", and a line under Open questions. Do not ask about a row you could infer.
- Set `max_parallel_builders` to 1 if a worktree cannot be made to pass the gate independently.
- If a local run reaches production data, say so in the Deploy policy's validation target, list every path that writes under Validation's "Never use", mark those modules "interface only" in the Test map, and put the choice of a safe place to test writes (a local emulator, a test table set) under Open questions with your recommendation. The factory validates such a project read-only until the user answers.

## 4. Beads

- Present → keep the database and its conventions. Note in the profile where they differ from `~/.claude/skills/factory/reference/beads.md`. Do not re-init.
- Absent → ask before initialising it, and say what that does, because it is more than a database: bd makes a commit of its own on the current branch, with whatever git identity applies (check it against the project's), and points git's `core.hooksPath` at `.beads/hooks`. Initialise through `koujou init`, which passes `--skip-agents`: plain `bd init` also writes `.agents/`, `.codex/`, `.cursor/` and its own blocks into `AGENTS.md`, one of which says "do not commit without clear authority", against builders that commit on their task branches. If such a block is already there, settle the disagreement in the profile in so many words.

Report anything unhealthy you noticed (stale in-progress claims, issues with no acceptance criteria, a roadmap that disagrees with beads) but don't fix it unasked.

An existing backlog rarely has acceptance criteria. Don't rewrite it wholesale. The factory brings an issue up to standard at the moment it picks it up: `factory-plan` gives it criteria, a lane and dependencies before `factory-run` will take it, and everything else stays as the team wrote it.

## 5. Hand over

Show the user the profile and call out: the baseline gate result, the Open questions section (everything you could not determine or had to infer, the Test map rows you are unsure of among them: "I will test billing through the checkout page and read the result from the `invoices` table with the local database; is that right, and is there a sandbox account?"), and the policies you inferred about pushing and deploying, since those are the ones that hurt if wrong. Include the prerequisites the factory will need to operate here at all (credentials for the deploy path, test accounts, access to services), so they can be asked for now. `FACTORY.md` is approved when the user says so. Commit it only if the project's git policy allows.
