---
name: factory-new
description: Start a brand-new project under the software factory. Use when the user has an idea and an empty or near-empty directory, and wants the factory to take it from nothing to a working product.
---

# Factory: new project

A new project has no gate, no conventions and no baseline, and the delivery loop needs all three. This skill gets a project to the point where the normal pipeline can run. It does not build the product.

## Order of work

1. **Capture the idea.** Run `factory-spec` first, at lane L. The product requirements decide the stack, so nothing technical is chosen yet.
2. **Design.** Run `factory-design`. For a new project the design must also settle: language and framework, repo layout, how it is tested, how it runs locally, where it will deploy. Prefer boring, well-supported choices and whatever the user already runs elsewhere; ask them rather than assume.
3. **Bootstrap the repo** (after the design is approved):
   - `git init` if needed, a `.gitignore`, a README stating what the project is.
   - `bd init --non-interactive --prefix <short>`; review the files it adds.
   - `AGENTS.md` with the factory block (`~/.claude/skills/factory/reference/agents-template.md`): the project's rules and the System design, which starts as "nothing built yet" plus the approved design's components under "In progress". `CLAUDE.md` imports it with `@AGENTS.md`.
   - `FACTORY.md` from `~/.claude/skills/factory/reference/profile-template.md`. Commands the project does not have yet are written as the commands the walking skeleton will provide.
4. **Plan with a walking skeleton first.** Run `factory-plan`. The first epic is always the skeleton: the thinnest end-to-end slice that builds, has one real test, runs locally, and passes a gate of lint, typecheck (where the language has one), test and build. Every other epic depends on it. Until it lands there is nothing to run a gate against, so skeleton tasks run one at a time, not as a swarm.
5. **Deliver.** `factory-run` on the skeleton epic, then on the feature epics.

## Why skeleton first

Parallel builders each need a worktree where the gate already passes, and a reviewer needs a gate to run. Building features before that exists means every task invents its own tooling and they collide at merge.

## Deployment

A new project has nowhere to deploy at first. Set the deploy policy to "local only" and the validation target to the locally run build until the user asks for an environment; then make provisioning its own epic, with the user confirming anything that creates billable resources.
