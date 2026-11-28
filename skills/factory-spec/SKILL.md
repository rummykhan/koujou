---
name: factory-spec
description: Factory stage 1 — turn a raw request into solid, testable requirements. Use when the user hands the factory an idea, feature request, or vague brief and no approved requirements.md exists for it yet.
---

# Factory: raw requirement → solid requirement

Output: `raw.md` and `requirements.md` in the work order folder (location from `FACTORY.md`; default `docs/factory/<slug>/`). Everything downstream is judged against this document: the plan's acceptance criteria come from it and the validator tests the product against it. A vague sentence here becomes a wrong feature later.

## Steps

1. **Save the raw request** verbatim in `raw.md`, including pasted material and links. It is the record of what was actually asked.

2. **Ground it.** On an existing project, read enough of the code and docs to know what exists, what the request touches, and what it would contradict (earlier decisions, existing behaviour). Many "questions for the user" are answered by the codebase; answer those yourself.

3. **Find the gaps.** Work out what is still undecided and would change what gets built: who the user is, the exact behaviour at the edges, what is out of scope, what "done" looks like, constraints (performance, data, compatibility, cost, deadlines). Separate two kinds:
   - Things with a sensible default → choose it and record it as an assumption.
   - Things only the user can decide → ask. Batch them, at most a handful, each with your recommended answer. Don't ask what you could look up.

4. **Write `requirements.md`**:

   ```markdown
   ---
   status: draft
   lane: S | M | L
   ---
   # <Title>

   ## Problem
   Who has the problem, what it is, why now. Two or three sentences.

   ## Goals
   Outcomes, not features.

   ## Non-goals
   What this deliberately does not do. As important as the goals for keeping builders in scope.

   ## Requirements
   ### R1 — <short name>
   <One behaviour, stated from the user's side.>
   Acceptance:
   - Given <state>, when <action>, then <observable result>
   - ...

   ### R2 — ...

   ## Constraints
   Performance, security, compatibility, data, cost.

   ## Assumptions
   Defaults you chose; each is something the user can overturn.

   ## Prerequisites
   | # | What | Needed by | Why | Status | If unavailable |
   Everything the work needs that only the user can provide. See step 5.

   ## Open questions
   Anything still unresolved. Must be empty before approval.
   ```

5. **Sweep for prerequisites.** Read `~/.claude/skills/factory/reference/blockers.md`. Go through every requirement and ask what it needs from outside the repo that an agent cannot produce: API keys and accounts, third-party app registrations, access, DNS, test users, assets, data, decisions that cost money. Check what the project already has (env variable names, the profile) before listing something as missing. For each, write what exactly is needed, where it should be put, and what the factory will do if it is not available now (build against a fake, or leave that part for the next pass). The point is to ask once, at the start, instead of stopping the factory halfway through the build.

6. **Check it** before showing the user:
   - Could someone who has never seen the conversation verify each acceptance line by using the product? Lines like "works well" or "is fast" fail this; give the number or the observable.
   - Does every requirement describe behaviour, leaving the implementation to design?
   - Is the unhappy path covered: empty, invalid, unauthorised, failure of a dependency?
   - Does anything contradict existing behaviour or a logged decision? Say so explicitly.

7. **No gate here: go on.** Continue straight to design (lane L) or plan (lane M); the user approves these requirements together with the design and plan at the plan gate, where the summary (the requirements in a line each, the assumptions, the lane, and the prerequisites as one batch of asks, each answerable with "here it is", "later", or "not this pass") is part of what they see. Stop here only for a question that would change what gets designed and has no sensible default; ask it, with your recommendation, then continue. Record answers in the Status column; verify anything provided with the cheapest real call before relying on it. The plan gate sets `status: approved`. An unavailable prerequisite does not block approval: it shapes the plan. Changes after approval are edits to this file that the user sees, never silent reinterpretation downstream.

## Next

Lane L → `factory-design`. Lane M → `factory-plan`. Lane S → create the single bead (acceptance criteria copied from the requirement) and go to `factory-run`.
