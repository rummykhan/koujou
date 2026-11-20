---
name: factory
description: Software factory overview and router. Use when the user wants the factory to deliver something ("factory this", "run the factory", "take this idea to shipped"), asks where a piece of work stands in the pipeline, or you need the factory's stages, sizing rules, artifacts, and beads conventions before using any other factory-* skill.
---

# Software Factory

A pipeline that turns a raw idea into shipped, validated work on any project. Beads (`bd`) holds the dependency graph and all task state; markdown files hold the thinking; subagents do the building, reviewing and validating; this session orchestrates and is the only one who talks to the user.

## Pipeline

```
raw idea ──► requirements ──► design ──► plan (epic + task graph in beads) ──► delivery loop ──► ship ──► shipped
            factory-spec     factory-design   factory-plan                     factory-run      factory-ship
              ▲ gate           ▲ gate           ▲ gate                                            ▲ merge gate
                                                                                                    │
                                                           factory improves itself ◄── factory-retro ┘
```

Project setup comes first, once per project: `factory-setup`. It initialises beads, writes `FACTORY.md` (the project profile every other stage reads), and puts the factory block in `AGENTS.md`, which carries the living system design. It follows `factory-adopt` for an existing codebase and `factory-new` for a greenfield one.

Each `▲ gate` is a point where the user approves before the next stage starts. Gates exist because an error caught in the requirements costs a sentence to fix and the same error caught after delivery costs the whole epic.

## Start here

1. No `FACTORY.md` at the repo root → run `factory-setup` first.
2. Read `FACTORY.md` and the System design in `AGENTS.md`. It overrides anything generic in these skills: commands, git and deploy policy, doc locations, limits.
3. Size the work, then enter the pipeline at the right stage.

## Sizing

Ceremony should match risk. Pick the smallest lane that fits and tell the user which one you picked.

| Lane | Fits | Stages |
|---|---|---|
| **S** | A bug, or a change with one obvious implementation, touching one area | One bead with acceptance criteria → `factory-run` on that bead |
| **Pass** | Several existing backlog issues, possibly from different epics | `factory-plan` intake (scout, ask once) → `factory-run --label factory:pass-<n>` |
| **M** | A feature in existing architecture; a few tasks; no new components, data stores or external services | `factory-spec` → `factory-plan` (design notes go in the epic's design field) → `factory-run` |
| **L** | New product, new subsystem, a new data model or integration, or anything expensive to undo | `factory-spec` → `factory-design` → `factory-plan` → `factory-run` |

If you find mid-flight that the lane was too small (a "small" change needs a schema decision), stop and step up a lane instead of improvising the missing stage.

## Artifacts

One folder per work order, at the path `FACTORY.md` gives (default `docs/factory/<slug>/`):

| File | Written by | Holds |
|---|---|---|
| `raw.md` | factory-spec | The user's request, verbatim, plus anything they pasted |
| `requirements.md` | factory-spec | Goals, non-goals, users, numbered requirements each with acceptance criteria, open questions |
| `design.md` | factory-design | Architecture, data model, interfaces, decisions with alternatives, risks, test and rollout strategy |
| `plan.json` | factory-plan | The epic and task graph, in `bd create --graph` format |
| `intake.md` | factory-plan | For a pass picked from the backlog, in place of requirements: the issues, prerequisites, decisions with defaults, what cannot be verified locally |
| `security.md` | factory-run | What the security review covered and found, and what happened to each finding |
| `report.md` | factory-run | What shipped, evidence, time taken, deferred bugs, stuck items, what is waiting on the user |
| `evidence/` | factory-validator | Screenshots, response captures, logs behind the validation verdict |
| `retro.md` | factory-retro | What the run taught and what the factory changed about itself |

Each markdown artifact starts with a frontmatter `status: draft | approved` line. A stage may only start when its input artifact is `approved`; only the user approves.

If the project already has homes for these (a `REQUIREMENTS.md`, a specs folder, a decision log), `FACTORY.md` maps to them and you use those instead of creating parallel ones. Two sources of truth drift within days.

## Roles

| Role | Who | May write code | May write beads |
|---|---|---|---|
| Orchestrator | This session | Merges only | Yes — the only writer |
| `factory-builder` | Subagent, one per task, in its own worktree | Yes | No |
| `factory-reviewer` | Subagent, fresh context per review | No | No |
| `factory-security` | Subagents, several at once, each reading the assembled change through one lens (access, input, exposure) | No | No |
| `factory-tester` (QA) | Subagent, writes the automated acceptance suite from the requirements, in its own worktree | Tests only | No |
| `factory-validator` (QA) | Subagent, black-box against the running product, in a real browser for UIs | No | No |

Two rules carry most of the weight:

- **Nobody grades their own work.** The builder never declares a task done; an independent reviewer does, against the acceptance criteria written before the code existed.
- **One writer for beads.** Subagents report; the orchestrator records. This keeps state honest and avoids races between parallel builders.

Three more hold the rest together:

- **QA is independent of the builders.** The tester writes acceptance tests from the requirements without reading the implementation; the validator uses the running product. Details in the agent files.
- **Ask the user once, early.** Everything only the user can provide (keys, accounts, access, decisions, assets) is swept for at the requirements and design gates and asked for in one batch. What they cannot provide now is built against a fake or moved to the next pass; what surfaces mid-run bubbles up through a `factory:needs-user` gate while other work continues. Protocol: `~/.claude/skills/factory/reference/blockers.md`.
- **The system design stays current.** `AGENTS.md` holds a short, as-built description of the system: components, data model, flows, interfaces, external dependencies. It is rewritten where needed in the same change that alters the system, so every agent starts from the real architecture. Format: `~/.claude/skills/factory/reference/agents-template.md`.
- **Every run teaches the factory.** `factory-retro` ends each epic by turning the run's evidence into changes to the project profile, the factory's skills, and the workers' instructions.

## Beads conventions

Full detail and command recipes are in `~/.claude/skills/factory/reference/beads.md`. The essentials:

- An **epic** is the unit of delivery; **tasks** are its children; **bugs** found during the run are children too (fix now) or parentless with `factory:deferred` (next phase).
- Dependencies mean "cannot start until", never "I'd do this first". Two tasks that would edit the same files get a dependency between them, so everything `bd ready` returns together is safe to build in parallel.
- Every task carries acceptance criteria that each name their check, and one acceptance command (metadata `accept`) that runs the task's own tests, named with its id. `koujou accept <id>` runs it; it is what closes the task. `bd lint` enforces the sections.
- Loop counters live in metadata: `fix_attempts` and `rebases` on a task, `validate_rounds` on an epic. Limits come from `FACTORY.md`.
- Time lives there too: beads stamps claim and close, the run stamps built, reviewed, merged, validated and shipped. `koujou times <epic-id>` adds it up.
- A close reason records what shipped, the evidence, and any residue.

## Status

When asked where things stand: `bd epic status`, `bd ready`, `bd blocked`, `bd list --label factory:stuck`, `bd list --label factory:needs-user --status open`, `bd gate list`, plus the `status:` line of the work order's artifacts. Report the stage, what is waiting on the user, and what is stuck.
