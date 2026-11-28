---
name: factory-setup
description: Set up the software factory in a project, in one go — beads, AGENTS.md with the living system design, CLAUDE.md, and the FACTORY.md profile. Use when the user says "set up the factory here", "onboard this project", "koujou init", or when any factory skill finds no FACTORY.md. Works for both existing codebases and empty directories.
---

# Factory: set up a project

One command should take a project from "never seen the factory" to "ready to deliver". Do every step yourself; ask the user only for what cannot be discovered, and ask it all at the end, together.

## 0. Check the tools

- `bd version` works. If `bd` is missing, install it: `brew install beads` where Homebrew exists, otherwise `npm install -g @beads/bd`. Verify with `bd version`.
- The factory skills and agents are linked (`ls ~/.claude/skills/factory ~/.claude/agents/factory`). If not, run `install.sh` from the factory repo.

## 1. Wire the project

Run `koujou init` in the project root (if the command is not on the PATH: `~/.koujou/bin/koujou init`, or `bin/koujou init` from the factory checkout). It is instant and idempotent: it initialises git and beads if they are missing (an existing `.beads/` is kept), copies the `FACTORY.md` template, appends the factory block to `AGENTS.md`, and makes `CLAUDE.md` import `AGENTS.md`. It never commits. Everything after this step is filling those files with what is true of this project. `koujou doctor` reports what is still template.

## 2. Work out which path this is

- **Existing project** — there is product code. Follow `factory-adopt` for discovery, the baseline gate and the profile.
- **New project** — empty or only notes. Follow `factory-new`; the profile is filled in as the design settles and the walking skeleton lands.

## 3. Beads

- `.beads/` exists → keep it. `bd doctor` should be clean; `bd setup claude --check` should report the session hook installed (run `bd setup claude` if not).
- `koujou init` created it → it ran `bd init --skip-agents`, so beads wrote no instruction files of its own, and installed the `bd prime` session hook itself. bd still makes a commit, with whatever git identity applies here; `koujou init` prints it. If the project commits under another identity (a noreply address on a public repository), amend that commit before anything is pushed.
- If the repo has a git remote and the user wants beads shared across machines, that is `bd dolt push`; leave it off until they ask.

## 4. FACTORY.md

Filled in by the path from step 2, from `~/.claude/skills/factory/reference/profile-template.md`. For an existing project that includes the proven baseline gate and the proven worktree recipe.

## 5. AGENTS.md and CLAUDE.md

Follow `~/.claude/skills/factory/reference/agents-template.md`:

- The factory block is already in `AGENTS.md` from `koujou init`; update it in place. Fill "How work gets done here" from the profile, and write the **System design** from the code as it is today. For a new project the design sections say "nothing built yet" and are filled when the first epic closes.
- Make sure `CLAUDE.md` contains the line `@AGENTS.md`. Keep whatever else it holds.
- If `bd init` wrote a "do not commit unless asked" rule into these files, the profile's git policy must say that factory workers commit on their own task branches, so workers are not caught between the two.

## 6. Check it end to end

- `koujou doctor` reports no problems.
- `bd ready` runs.
- The gate command from the profile runs (existing projects: green, twice).
- `AGENTS.md` has exactly one factory block; `CLAUDE.md` imports it; the System design names real paths (`ls` a few).
- `git status` shows only the files setup was meant to touch.

## 7. Hand over

Tell the user, briefly:

- What was set up and which files changed. Commit them only if the project's git policy allows; otherwise leave them staged for the user.
- The baseline gate result, and anything red or flaky.
- **Everything you need from them, as one list**: open questions from the profile (policies you inferred), and the prerequisites the factory will need to operate here (deploy credentials, test accounts, access), each answerable with "here it is", "later", or "not needed".
- The next step: `/factory <what you want built>`.
