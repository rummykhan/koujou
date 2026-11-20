# Software Factory

A reusable delivery pipeline for Claude Code. It takes a raw idea to shipped, validated software on any project, using [beads](https://github.com/steveyegge/beads) (`bd`) for the dependency graph and a swarm of subagents working in parallel git worktrees under one orchestrator.

```
raw idea → requirements → design → epics + task graph → build ⇄ review → merge → deploy → validate → triage ─┐
           /factory-spec  /factory-design  /factory-plan  └──────────── /factory-run ────────────────────────┤
                ▲ you approve   ▲ you approve   ▲ you approve                    fix now (capped) ◄──────────┤
                                                                                 defer to next phase ◄───────┘
```

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/rummykhan/software-factory/main/install.sh | bash
cd your-project
factory init
```

Then restart Claude Code and, in the project, run `/factory-setup` followed by `/factory <what you want built>`.

### What each step does

| Step | Effect |
|---|---|
| `install.sh` | Installs [beads](https://github.com/gastownhall/beads) (`bd`) if missing (Homebrew, then npm, then the beads install script). Clones this repo to `~/.software-factory`. Links its skills into `~/.claude/skills`, its agents into `~/.claude/agents/factory`, and the `factory` command into `~/.local/bin`. Safe to re-run. |
| `factory init` | In the current project, instantly and without committing: `git init` if needed; `bd init` if there is no `.beads/` (an existing database is kept); creates `FACTORY.md` from the template; appends the factory block to `AGENTS.md`; makes `CLAUDE.md` import `AGENTS.md`. Idempotent. |
| `/factory-setup` | In Claude Code: reads the code, proves the gate, fills in `FACTORY.md` and the system design in `AGENTS.md`, and asks you once for anything only you can provide. |
| `factory doctor` | Checks the installation and the current project, and says what is still unfilled. |
| `factory update` | Pulls the latest factory and relinks. `factory uninstall` removes the links. |

### For AI agents installing this

If you were handed this repository and asked to install it, do exactly this:

1. Run the installer: `curl -fsSL https://raw.githubusercontent.com/rummykhan/software-factory/main/install.sh | bash`. If `~/.software-factory` already exists, run `~/.software-factory/bin/factory update` instead.
2. In the user's project directory, run `factory init` (or `~/.software-factory/bin/factory init` if `~/.local/bin` is not on the PATH), then `factory doctor`.
3. Tell the user to restart Claude Code so the new skills and agent types load, then run `/factory-setup` in the project. If the skills are already available in your session, run `factory-setup` yourself now.
4. Do not commit the files `factory init` created unless the user asks; report which files changed.

Requirements: `git`, `bash`, Claude Code, and one of Homebrew, npm or curl for beads. macOS and Linux.

## Use

| You want | Run |
|---|---|
| Set up a project (existing or empty) | `/factory-setup` |
| Deliver something | `/factory` — sizes it (S/M/L) and routes to the right stage |
| A specific stage | `/factory-spec`, `/factory-design`, `/factory-plan`, `/factory-run <epic-id>`, `/factory-retro` |

`/factory-setup` leaves three files in the project:

| File | Holds |
|---|---|
| `FACTORY.md` | The project profile: commands, the gate, git and deploy policy, QA, prerequisites, limits, lessons |
| `AGENTS.md` | A managed factory block: how work gets done here, and the living system design (as built, updated whenever an epic ships). `CLAUDE.md` imports it |
| `.beads/` | The task graph |

## What is in here

| Path | What |
|---|---|
| `skills/factory` | Overview, sizing lanes, artifacts, roles. `reference/` holds the beads conventions, swarm protocol, blocker protocol, profile and AGENTS.md templates, and an example plan |
| `skills/factory-setup`, `factory-adopt`, `factory-new` | Project setup: the entry point and its two paths |
| `skills/factory-spec`, `factory-design`, `factory-plan` | The three upstream stages, each ending at a user approval |
| `skills/factory-run` | The delivery loop the orchestrator follows |
| `skills/factory-retro` | The self-improvement pass; its changes are logged in `CHANGELOG.md` |
| `agents/` | Workers: `factory-builder`, `factory-reviewer`, and the QA department, `factory-tester` and `factory-validator` |
| `lab/` | Lab notes; `lab/workspace/` (git-ignored) holds throwaway projects the factory is tested on |

## How it holds together

- **`FACTORY.md` adapts the factory to the project**: commands, the gate, git and deploy policy, where docs live, limits. Skills stay generic.
- **Beads is the only task state.** Epics, tasks, bugs, dependencies, loop counters (`fix_attempts`, `validate_rounds`), human gates.
- **Acceptance criteria are written before code**, and the builder never judges its own work: a reviewer checks each task, a QA tester writes the acceptance suite from the requirements (Playwright for UIs), and a black-box validator uses the assembled product in a real browser.
- **You are asked once, early.** Keys, accounts, access and decisions are swept for at the requirements gate and requested in one batch. What you cannot provide is built against a fake or moved to the next pass; what surfaces mid-run waits behind a `factory:needs-user` gate while other work continues.
- **Parallel by construction.** Tasks that are ready together own different files; each gets a worktree and a builder; the orchestrator merges one at a time.
- **Agents coordinate through bead comments** (a mailbox per task) and the orchestrator, per `skills/factory/reference/swarm.md`.
- **Loops are capped.** A task that fails review `max_fix_attempts` times is marked stuck and gated for you; an epic that fails validation `max_validate_rounds` times stops.
- **The factory improves itself.** Each epic ends with a retro that turns the run's evidence into changes to the project profile, the skills and the workers' instructions.
- **You approve** requirements, design, plan, and any deploy beyond local.

## License

MIT. See [LICENSE](LICENSE).
