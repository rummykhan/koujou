---
name: factory
description: Software factory overview and router. Use when the user wants the factory to deliver something ("factory this", "run the factory", "take this idea to shipped"), asks where a piece of work stands in the pipeline, or you need the factory's stages, sizing rules, artifacts, and beads conventions before using any other factory-* skill.
---

# Software Factory

A pipeline that turns a raw idea into shipped, validated work on any project. Beads (`bd`) holds the dependency graph and all task state; markdown files hold the thinking; subagents do the building, reviewing and validating; this session orchestrates and is the only one who talks to the user.

## Pipeline

```
raw idea ──► requirements ──► design ──► plan (epic + task graph in beads) ══► delivery loop ──► ship ──► shipped
            factory-spec     factory-design   factory-plan                     factory-run      factory-ship
                                                        ▲ THE gate: the user approves             (merges itself once
                                                          requirements + design + plan together    the PR is mergeable)
                                                                                                    │
                                                           factory improves itself ◄── factory-retro ┘
```

Project setup comes first, once per project: `factory-setup`. It initialises beads, writes `FACTORY.md` (the project profile every other stage reads), and puts the factory block in `AGENTS.md`, which carries the living system design. It follows `factory-adopt` for an existing codebase and `factory-new` for a greenfield one.

A security review is not a stage of the pipeline: the user asks for one when they want it, on any branch or pull request (`factory-security-review`), and its findings come back as beads.

There is **one human gate: the plan**. Spec, design and plan run back to back without stopping, and the user approves the three together, as one picture: what will be built (requirements), how (design), and in what pieces, at what budget (plan). That gate exists so the user and the factory share one understanding before any code: an error caught there costs a sentence, the same error caught after delivery costs the epic. After it, the factory builds, validates, opens the pull request and merges it once it is mergeable, without asking again. It stops for the user only for what it cannot decide or provide (`factory:needs-user`), or when the budget runs out.

A question only the user can answer that would change the design itself (who the product is for, a choice that costs money) is asked up front, in one batch, before the design is written; everything else is a recorded default the user sees at the gate.

**No gate at all** for Direct and lane-S work, and for small work an existing pattern in the code already settles (another route like the twenty already there, a field added the way the last one was): the factory goes ahead, and the user sees it in the report and on the board.

## Start here

1. No `FACTORY.md` at the repo root → run `factory-setup` first.
2. Read `FACTORY.md` and the System design in `AGENTS.md`. It overrides anything generic in these skills: commands, git and deploy policy, doc locations, limits.
3. Size the work, then enter the pipeline at the right stage.

## Sizing

Ceremony should match risk. Pick the smallest lane that fits and tell the user which one you picked.

| Lane | Fits | Stages |
|---|---|---|
| **Direct** | Work whose time goes to live cycles, not to writing code: a deploy or migration, recovering a stuck stack, debugging production, a switch-over. Also a few-line change you can make and verify in minutes | No factory stages. This session does it itself, end to end without stopping: change, run live, read the result, fix, repeat. A bead records it, opened before the work so the board shows it while it is done: `koujou direct start "<title>"`, then `koujou direct done <id> --pr <url>` (or `koujou ship --bead <id>`), with what was done and the evidence in its close reason. Code changes still go through the project's gate and its integration: `koujou ship` pushes the branch, opens the pull request, merges it by the profile's method and names the deploy command, in one step |
| **S** | A bug, or a change with one obvious implementation, touching one area | One bead with acceptance criteria → `factory-run` on that bead |
| **Check** | "Test the billing module", "is sign-in still working": one module examined as it stands, nothing to build | One `factory-validator` on the running product, briefed with the module's Test map row and, as criteria, what the System design and any requirements say the module does. Bugs it finds become `factory:deferred` beads; fixing them is a pass |
| **Pass** | Several existing backlog issues, possibly from different epics | `factory-plan` intake (scout, ask once) → `factory-run --label factory:pass-<n>` |
| **M** | A feature in existing architecture; a few tasks; no new components, data stores or external services | `factory-spec` → `factory-plan` (design notes go in the epic's design field) → `factory-run` |
| **L** | New product, new subsystem, a new data model or integration, or anything expensive to undo | `factory-spec` → `factory-design` → `factory-plan` → `factory-run` |

Pick **Direct** over the factory whenever an agent would mostly wait on a live system: on the shukka and Orbitary switch-overs, every production defect was a one-line fix behind a 10–20 minute deploy, and routing each through a builder added an agent's start-up and a context rebuilt from nothing to every cycle. The session doing it directly was several times faster.

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
| `security.md` | factory-security-review (only when asked) | What the security review covered and found, and what happened to each finding |
| `report.md` | factory-run | What shipped, evidence, time taken, deferred bugs, stuck items, what is waiting on the user |
| `evidence/` | factory-validator | Screenshots, response captures, logs behind the validation verdict |
| `retro.md` | factory-retro | What the run taught and what the factory changed about itself |

Each markdown artifact starts with a frontmatter `status: draft | approved` line. Spec, design and plan may each start on their predecessor's draft; `factory-run` starts only once the plan gate has approved all three, and only the user approves.

If the project already has homes for these (a `REQUIREMENTS.md`, a specs folder, a decision log), `FACTORY.md` maps to them and you use those instead of creating parallel ones. Two sources of truth drift within days.

## Roles

| Role | Who | May write code | May write beads |
|---|---|---|---|
| Orchestrator | This session | Merges only | Yes — the only writer |
| `factory-builder` | Subagent, one per task, in its own worktree | Yes | No |
| `factory-reviewer` | Subagent, fresh context: one review of each epic's assembled branch, plus per-task reviews for tasks labelled `security` or `review` | No | No |
| `factory-security` | Subagents, several at once, each reading a change through one lens (access, input, exposure); only in `factory-security-review`, on demand | No | No |
| `factory-tester` (QA) | Subagent, only when the plan has a `qa` task (lane L, flows across slices): writes the acceptance suite from the requirements | Tests only | No |
| `factory-validator` (QA) | Subagent, black-box against the running product, in a real browser for UIs | No | No |

Two rules carry most of the weight:

- **Nobody grades their own work.** The builder never declares a task done; the orchestrator does, by running the task's acceptance command and the gate and reading the diff against criteria written before the code existed, and one independent reviewer reads the assembled epic.
- **Lean, inside a budget.** The factory must beat the user working by hand with one agent, or it has no reason to exist. Few builders, few larger tasks, no agent whose report would not change anything; every run has a budget of agents and time that `koujou spawned` enforces, and the retro compares each run against doing it by hand.
- **One writer for beads.** Subagents report; the orchestrator records. This keeps state honest and avoids races between parallel builders.

Three more hold the rest together:

- **QA is independent of the builders.** The validator uses the running product, then reads back what it stored (the database, the cloud account, GitHub) wherever the factory has read access. How each module is tested is worked out from the project and kept in the profile's Test map; the user is asked only about what could not be inferred, before work starts. Details in the agent files.
- **Ask the user once, early.** Everything only the user can provide (keys, accounts, access, decisions, assets) is swept for while writing the requirements and design and asked for in one batch, at the plan gate at the latest. What they cannot provide now is built against a fake or moved to the next pass; what surfaces mid-run bubbles up through a `factory:needs-user` gate while other work continues. Protocol: `~/.claude/skills/factory/reference/blockers.md`.
- **The system design stays current.** `AGENTS.md` holds a short, as-built description of the system: components, data model, flows, interfaces, external dependencies. It is rewritten where needed in the same change that alters the system, so every agent starts from the real architecture. Format: `~/.claude/skills/factory/reference/agents-template.md`.
- **Every run teaches the factory.** `factory-retro` ends each epic by turning the run's evidence into changes to the project profile, the factory's skills, and the workers' instructions.

## Beads conventions

Full detail and command recipes are in `~/.claude/skills/factory/reference/beads.md`. The essentials:

- An **epic** is the unit of delivery; **tasks** are its children; **bugs** found during the run are children too (fix now) or parentless with `factory:deferred` (next phase).
- Dependencies mean "cannot start until", never "I'd do this first". Two tasks that would edit the same files get a dependency between them, so everything `bd ready` returns together is safe to build in parallel.
- Every task carries acceptance criteria that each name their check, and one acceptance command (metadata `accept`) that runs the task's own tests, named with its id. `koujou accept <id>` runs it; it is what closes the task. `bd lint` enforces the sections.
- Loop counters live in metadata: `fix_attempts` and `rebases` on a task, `reopened` on a bug whose fix failed validation, `validate_rounds` and `round_open` (open fix-now bugs after each round) on an epic. Limits come from `FACTORY.md`; the validate-and-fix loop has no round limit and stops on evidence that it is not converging (`koujou converge`).
- Time lives there too: beads stamps claim and close, the run stamps built, reviewed, merged, validated and shipped. `koujou times <epic-id>` adds it up.
- A close reason records what shipped, the evidence, and any residue.

## Status

When asked where things stand: `koujou status` (every run in progress with its tasks and budget, live agents and any past their time box, what waits on the user, what is stuck, processes left in task worktrees, whether the machine is kept awake), plus the `status:` line of the work order's artifacts. Report the stage, what is waiting on the user, and what is stuck.
