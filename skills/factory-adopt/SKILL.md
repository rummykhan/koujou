---
name: factory-adopt
description: Onboard an existing codebase into the software factory. Use when a project that already has code has no FACTORY.md and the user wants the factory to work on it, or when FACTORY.md has gone stale and needs refreshing.
---

# Factory: adopt an existing project

This is the existing-project path of `factory-setup`, which also handles beads, `AGENTS.md` and `CLAUDE.md`. If you were invoked directly, run `factory-setup` so those are not skipped.

Produce `FACTORY.md`, the profile every factory stage reads, by finding out how this project actually works. The aim is to fit the factory to the project. An existing project has conventions that work; replacing them with the factory's defaults creates a second source of truth that drifts.

## 1. Discover (read-only)

Find out, by reading and by running harmless commands:

- **What it is**: README, top-level docs, package manifests, directory layout. Which folders are the user's code and which are vendored or upstream.
- **Rules**: `CLAUDE.md`, `AGENTS.md`, project skills in `.claude/skills`, contributor docs. Note hard rules (no deploy without confirmation, forbidden APIs, commit style).
- **Commands**: install, lint, typecheck, test, build, run. Take them from manifests and CI config, since CI is what the project really enforces.
- **Git and deploy**: default branch, branch protection, what a push to the default branch triggers, how deploys happen and who triggers them, environments and their URLs, whether a rollback procedure exists. Existing worktrees (`git worktree list`) and what they are for, so the factory's worktree root does not land among them.
- **Existing planning artifacts**: requirements, specs, decision log, roadmap, pitfalls. These become the Docs map.
- **Beads**: is `.beads/` present? If so, with `--readonly`: `bd status`, `bd ready`, `bd lint`, issue types and labels in use, whether it syncs to a remote, any project-specific bead rules.
- **Test reality**: which areas have tests and which have none.

A large or unfamiliar repo is worth one Explore agent for this; a small one is quicker to read directly.

## 2. Prove the gate

Run the gate on a clean checkout of the base branch and record the result in the profile's Baseline section. The delivery loop attributes every later failure to the task in flight, so it needs a known baseline.

- **Is the base current?** `git fetch` and compare with the remote (`git status -sb`). A baseline measured on a stale base describes code nobody will build on; tell the user rather than pulling for them.
- **One gate per package.** A repo with several packages usually has several gates; CI config shows them. Record each, and which ones you could not run and why.
- **Run it twice.** A test that fails once and passes on rerun is the most expensive kind of baseline problem: it will later be blamed on an innocent task. When that happens, look for state that survives between runs (a local database, a cache, fixed ports, files in tmp) and say what you found.

If the gate is red or cannot run (missing services, secrets), that is the first thing to tell the user: the factory can plan here but cannot deliver until it is fixed. Don't run anything that deploys, bills, or writes outside the repo.

Also work out what a fresh git worktree needs before the gate passes there (install, env files, generated code), and what has to differ between two worktrees running at once (ports, a database name or table prefix). Prove it: create a throwaway worktree outside the repo, run the setup and the gate there, then remove it. If you cannot prove it, set `max_parallel_builders` to 1 and say why; an unproven worktree recipe fails in the middle of a wave.

## 3. Write `FACTORY.md`

Start from `~/.claude/skills/factory/reference/profile-template.md` and fill every section with what you found. Guidelines:

- Point to existing rules; don't restate them.
- Map the Docs map onto what exists. Only default to `docs/factory/<slug>/` for artifacts the project has no home for.
- If pushing or merging to the base branch deploys to production, the git policy must say the factory works on branches and the user merges.
- Record gaps honestly under "Known gaps in the gate"; the validator leans on that list.
- Set `max_parallel_builders` to 1 if a worktree cannot be made to pass the gate independently.

## 4. Beads

- Present → keep the database and its conventions. Note in the profile where they differ from `~/.claude/skills/factory/reference/beads.md`. Do not re-init.
- Absent → ask before running `bd init`; it adds several files to the repo.

Report anything unhealthy you noticed (stale in-progress claims, issues with no acceptance criteria, a roadmap that disagrees with beads) but don't fix it unasked.

An existing backlog rarely has acceptance criteria. Don't rewrite it wholesale. The factory brings an issue up to standard at the moment it picks it up: `factory-plan` gives it criteria, a lane and dependencies before `factory-run` will take it, and everything else stays as the team wrote it.

## 5. Hand over

Show the user the profile and call out: the baseline gate result, the Open questions section (everything you could not determine or had to infer), and the policies you inferred about pushing and deploying, since those are the ones that hurt if wrong. Include the prerequisites the factory will need to operate here at all (credentials for the deploy path, test accounts, access to services), so they can be asked for now. `FACTORY.md` is approved when the user says so. Commit it only if the project's git policy allows.
