# AGENTS.md: the factory block

`AGENTS.md` is the file every coding agent reads on entering the repo, whatever tool it runs in. The factory keeps one managed block in it. The block does two jobs: it tells any agent how work gets done here, and it carries the **living system design**, the current shape of the system, so nobody has to reverse-engineer the architecture from the code before making a change.

Rules for the block:

- Everything between the `BEGIN` and `END` markers is the factory's. Leave whatever else is in the file alone (including the block `bd init` manages), and never duplicate what another section already says: point to it.
- Claude Code reads `CLAUDE.md`, not `AGENTS.md`. `CLAUDE.md` must contain the line `@AGENTS.md` so both tools see the same thing. If `CLAUDE.md` already has project rules, keep them and add the import.
- The system design describes what **is built**, as of the commit it names. Planned work lives in the work order's `design.md` until it ships; the "In progress" list is the only place the block mentions it.
- Keep it to about two screens. It is a map: a component gets a line or two and a path. When a section outgrows that, move the detail to a document under the docs folder and link it.
- It is updated in the same change that alters the system: `factory-run` rewrites the affected sections when an epic closes, and `factory-retro` checks that it still matches the code. A design section that is wrong is worse than none, because agents trust it.

## Template

```markdown
<!-- BEGIN SOFTWARE FACTORY — managed block. Edit through the factory (/factory-setup, /factory-run); keep these markers. -->
## How work gets done here

This project is delivered through the software factory. The project profile is [`FACTORY.md`](FACTORY.md): commands, the gate, git and deploy policy, QA, lessons learned. Read it before changing code.

- **Tasks live in beads** (`bd ready`, `bd show <id>`). Every task has acceptance criteria written before the code; work to them.
- **Pipeline:** requirements → design → plan → build → review → QA → validate, with the user approving requirements, design, plan and any deploy. Start a piece of work with `/factory`.
- **Nobody closes their own work.** A task is done when an independent review passes and the gate (`<gate command>`) is green.
- **Need something only a human can provide** (a key, access, a decision)? Don't guess or stub silently: record it as a `factory:needs-user` bead and carry on with what does not depend on it.
- **Changed the system's shape?** Update the System design below in the same change.

## System design

_As built at `<short sha>` · updated <date>_

### Purpose
<Two or three sentences: what the system does and for whom.>

### Components
| Component | Responsibility | Where |
|---|---|---|
| <name> | <what it owns and decides> | `<path>` |

### Data model
<Entities, where each is stored, the keys that matter. One line each.>

### Key flows
1. **<Flow name>:** <the path through the components, in one or two lines>

### Interfaces
<What the outside world can call or see: routes, CLI commands, events, pages. Shapes worth knowing, or a link to where they are specified.>

### External dependencies
| Service | Used for | Configured by | Stand-in for tests |
|---|---|---|---|
| <service> | <purpose> | `<ENV_VAR>` (name only) | <fake / sandbox / none> |

### Decisions that constrain changes
- <Decision and its consequence> — <link to the decision log entry or design doc>

### In progress
- <epic id> — <what it will change here once it ships>
<!-- END SOFTWARE FACTORY -->
```

## Writing it for an existing project

Reverse-engineer the design from the code, not from old documents: read the entry points, the route or command table, the storage layer and the configuration, then describe what you found. Where the code and an existing architecture document disagree, the code is what is built; mention the disagreement to the user. Mark anything you inferred without confirming with "(inferred)" until someone confirms it.

## Updating it

Change only the sections the work touched, update the commit and date in the stamp line, and remove the epic from "In progress". If a change makes a line in "Decisions that constrain changes" untrue, that is a superseded decision: say so in the decision log, then update the line.
