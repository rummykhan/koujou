---
name: factory-design
description: Factory stage 2 — turn approved requirements into a system design. Use for lane-L work (new product or subsystem, new data model, new integration, anything expensive to undo) once requirements.md is approved and before planning tasks.
---

# Factory: requirements → system design

Input: an approved `requirements.md`. Output: `design.md` beside it. The design exists so that many builders, working in parallel without talking much, produce parts that fit. It needs to pin down the things two builders would otherwise each decide differently, and no more.

## Steps

1. **Read** the requirements, `FACTORY.md`, the System design in `AGENTS.md`, the project's rules and decision log, and the code the work will touch. If the System design disagrees with the code, fix the System design first; a design built on a wrong map inherits the error. A design that ignores the existing architecture gets rejected at review or, worse, merged.

2. **Explore before committing.** For each significant choice (data model, where a responsibility lives, sync or async, build or buy), consider at least one real alternative and say why you chose as you did. If a choice hinges on something unknown (does the API support this? is it fast enough?), make it a `spike` task for the plan, not a guess.

3. **Write `design.md`**:

   ```markdown
   ---
   status: draft
   ---
   # Design: <Title>

   ## Overview
   The shape of the solution in a paragraph, and a diagram if components interact.

   ## Components
   Each component or module: its responsibility, what it owns, what it depends on.
   For existing code: what changes and what stays untouched.

   ## Data model
   Entities, fields, keys, indexes, migrations. What happens to existing data.

   ## Contracts
   The exact interfaces where separately built pieces meet: route paths and
   payloads, function signatures, event shapes, types. Builders implement these
   as written, so write them precisely.

   ## Key flows
   The main paths through the system, including at least one failure path.

   ## Decisions
   | # | Decision | Alternatives considered | Why |
   Flag any that would take more than a couple of days to reverse.

   ## Risks
   What could go wrong, and how each is reduced or detected.

   ## Test strategy
   What is covered by unit and integration tests (builders), by the automated
   acceptance suite (QA tester: Playwright for UI flows, real requests for APIs),
   and what the validator must check by hand because no test can. Name the
   handles QA will rely on: routes, labels, roles, error messages.

   ## Rollout
   Order of delivery, migrations, feature flags, how to roll back.

   ## Requirement coverage
   | Requirement | Where it is satisfied |
   Every R-number appears. A requirement with no home is a gap.
   ```

4. **Design for parallel building.** Draw the boundaries so that components can be built independently behind the contracts. If two pieces cannot be separated cleanly, say so; the planner will sequence them.

5. **Sweep for prerequisites again.** Design choices create needs the requirements did not show: a chosen provider needs an account and keys, a deployment target needs access, an integration needs a sandbox. Add them to the requirements' `## Prerequisites` table (see `~/.claude/skills/factory/reference/blockers.md`), and for each external dependency design the seam: an interface with a fake implementation, so building and QA do not wait on the real thing.

6. **Check it**: every requirement covered; every contract precise enough to code against without asking; nothing here that contradicts a logged decision without saying it supersedes it; no decisions hidden in prose that belong in the Decisions table.

7. **No gate here: go on to the plan.** The plan gate walks the user through the overview, the decisions (especially the hard-to-reverse ones), the risks, and any new prerequisites, together with the requirements and the plan. On approval there, set `status: approved`, copy hard-to-reverse decisions into the project's decision log if it keeps one, and add the epic to "In progress" in the System design in `AGENTS.md` with a line on what it will change. The as-built sections are not touched until the work ships.

## Next

`factory-plan`.
