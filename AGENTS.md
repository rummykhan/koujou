# koujou: working on the factory itself

Koujou is a software factory for Claude Code: skills (`skills/factory-*`), worker definitions (`agents/factory-*.md`) and a small CLI (`bin/koujou`, `bin/koujou-*.py`). It is a public repository. The live board is a separate package, [koujou-ui](https://github.com/koujou-ai/koujou-ui); see the workspace `AGENTS.md` one level up for how the two fit together.

## Layout

| Path | What it is |
|---|---|
| `skills/` | The pipeline stages (`factory`, `factory-spec`, `-design`, `-plan`, `-run`, `-ship`, `-retro`, `-setup`, `-adopt`, `-new`, `-security-review`) and `skills/factory/reference/` (beads conventions, swarm protocol, blockers, profile and AGENTS templates) |
| `agents/` | The workers: builder, reviewer, security, tester, validator |
| `bin/` | `koujou` (bash) and its python helpers: accept, budget, converge, ready, spawned, status, times, wait. Standard library only |
| `tests/` | Tier 0 static checks, tier 1 CLI tests, tier 2–3 agent scenarios (`tests/README.md`) |
| `.claude/skills/factory-test` | The skill that runs those scenarios |
| `CHANGELOG.md` | Every change to the factory, tied to the run that taught it, with its expected effect |

`koujou link` symlinks `skills/*`, `agents/` and `bin/koujou` into `~/.claude` and `~/.local/bin`, so edits here are live in every session at once.

## Rules

- **Test before pushing.** `tests/run.sh` must pass. For a change to `factory-run`, `factory-plan`, `factory-ship` or the swarm protocol, also run the demo (`/factory-test demo`) and record its numbers in `tests/README.md`. A new rule comes with a scenario or a CLI test that fails without it.
- **Every change gets a `CHANGELOG.md` entry**: what changed, the incident that taught it, and the expected effect the next retro checks.
- **The factory must beat working by hand.** Prefer a change that removes an agent or a round trip to one that adds a check; speed is a requirement.
- **Write like the rest of the factory**: explain the situation and the reason, edit the sentence where the guidance belongs, keep it general (a lesson, not a diary entry), and remove what no longer earns its place.
- Commits use the GitHub noreply identity (`rummykhan <12664104+rummykhan@users.noreply.github.com>`). Nothing private about the people or projects the factory has been used on goes into this public repository beyond what is already in it.
