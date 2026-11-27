---
name: factory-retro
description: Factory self-improvement pass. After an epic is delivered (or stopped), studies what the run actually did — bounces, escaped bugs, late blockers, protocol slips, orchestrator workarounds — and improves the project profile, the factory's skills, and the worker agents' instructions. Use at the end of every factory-run, or when the user asks the factory to improve itself or its workers.
---

# Factory: retrospective and self-improvement

A factory that runs the same way after a bad epic as before it has learned nothing. This stage turns each run's evidence into changes at three levels:

| Level | Lives in | Scope | Example |
|---|---|---|---|
| **Project** | `FACTORY.md` (commands, known gaps, a `## Lessons` section) and the project's pitfalls doc | This project only | "The gate does not start the real process; the validator must." |
| **Factory process** | The factory's skills (`factory-*`) and references | Every project | "Reviewers need a three-dot diff once the epic branch has moved." |
| **Workers** | The factory's agent files (`factory-builder`, `-reviewer`, `-security`, `-tester`, `-validator`) | Every project | "Stop processes by PID, never by pattern." |

The factory's own source is wherever `~/.claude/skills/factory` points (`readlink` it); edit the files there, not copies.

## 1. Gather the evidence

Work from what happened, not from impressions.

- **Beads:** for the epic and each child, `bd show <id> --json`: `fix_attempts`, notes, close reasons, comments (the mailbox), labels (`factory:stuck`, `factory:needs-user`, `factory:deferred`). The epic's `validate_rounds` and `round_open` (did each round leave fewer bugs open?), and any bug with `reopened` or a chain of bugs underneath it.
- **Bugs by where they were caught:** each bug filed during the run, with the stage that found it and the earliest stage that could have (requirements, design, plan, build, review, automated QA, validation).
- **Agent reports:** things workers flagged about their own run (a rule they bent, a guess they made, something that confused them), and things reviewers or the validator noted about another worker's conduct.
- **Orchestrator friction:** every place you worked around a skill, hit an error following it, improvised a step it did not cover, or had to re-brief an agent because the first brief was not enough.
- **Design drift:** does the System design in `AGENTS.md` still describe the code? Check a few named paths and interfaces. Did any worker act on a stale line in it?
- **User friction:** questions the user had to be asked late that could have been asked at the start; anything the user corrected.
- **Time and cost:** `koujou times <epic-id>` (or `--label factory:pass-<n>`) and `koujou budget <epic-id>`: build, review and queue time per task, bounces, rebases, agents spawned, and the totals against the budget. Look for the task that took several times longer than its siblings, time spent waiting in the merge queue (lanes overlapped), review time that rivals build time, and every agent that caught nothing (a reviewer that passed first time, a scout whose report changed nothing): those are the next things to cut.
- **Against doing it by hand:** the factory is only worth running if it is at least as fast as the user working directly with one agent. Estimate honestly how long a single session would have taken for the same result, from the size of the diff and the live cycles it needed, and say which side won and by how much.
- **Merge conflicts:** which files conflicted, between which tasks, and whether their lanes or a missing dependency should have kept them apart.
- **Security findings** (only if the user ran `factory-security-review`): each introduced finding, and whether the task's reviewer or its acceptance criteria could have caught it earlier.

## 2. Find the causes

For each incident ask what, in the instructions or the plan, made it likely. Useful questions:

- A bug escaped review and automated QA → what kind of check would have caught it, and which worker's instructions should make that check natural?
- A task bounced → was the acceptance criterion vague, the lane wrong, the contract missing, or the builder's brief thin?
- A blocker appeared mid-run → could the prerequisite sweep have found it? What question would have surfaced it?
- A worker broke the protocol → did the protocol say it, and say why? Was the brief missing something the worker needed?
- Something went notably well → what made it work, so it is kept on purpose?

One incident is an anecdote. Prefer changes backed by a pattern (the same thing twice in a run, or once in each of two runs), or by a single incident whose consequence was severe.

## 3. Decide the changes

Put each lesson at the narrowest level that fixes it. Project-specific facts go in the project; only what would recur on other projects goes into the factory.

Write changes the way the rest of the factory is written:

- Explain the situation and the reason, so the worker can apply it to cases the rule's author did not foresee. A bare prohibition teaches one case.
- Edit the existing sentence or section where the guidance belongs. Don't append a list of patches at the end of a file.
- Keep it general. "Stop processes by PID" is a lesson; "don't run pkill on linklab" is a diary entry.
- **Remove as well as add.** Every instruction costs attention on every future run. If a step never caught anything, or guards against a mistake workers no longer make, cut or shorten it and note that in the changelog.
- Prefer changes that remove an agent or a round trip over ones that add a check. A new check must say which incident it would have caught and what it costs per run; speed is a requirement, not a nice-to-have.
- Don't tune a worker toward leniency to reduce bounces. A reviewer that fails less because it checks less is a regression.

## 4. Apply

- **Project level:** edit `FACTORY.md` and the pitfalls doc directly. Lessons go under `## Lessons` in `FACTORY.md` as one line each, dated, with the bead id that taught it. Workers read this section before starting.
- **Factory and worker level:** edit the skill or agent file in the factory source, then add an entry to `CHANGELOG.md` in the factory repo:

  ```markdown
  ## <date> — <project> / <epic id>
  - **<file>**: <what changed> — because <the incident, with bead ids>. Expected effect: <what should be different next run>.
  ```

  The expected effect is what the next retro checks. A change whose effect never shows up gets reverted.
- **Risky changes** — anything that loosens a gate, removes a human approval, widens what agents may do without asking, or rewrites a worker's role — are proposed to the user with the evidence, not applied.

## 5. Check earlier changes

Read the last few `CHANGELOG.md` entries. For each expected effect, did this run show it? Mark entries `confirmed`, `no evidence yet`, or `did not help` (and revert those).

## 6. Report

Write `retro.md` in the work order. It opens with a `## Speed` table, one row per run this project has had (copy the earlier rows from the last retro), so the trend is visible at a glance:

```markdown
| Run | Tasks | Agents (budget) | Working hours (budget) | Hand estimate | Faster than by hand? |
```

A run slower than by hand gets a cause and a change aimed at it, or the retro says plainly that the factory should not have been used for that kind of work. Then: the numbers (tasks, first-pass review rate, validation rounds, bugs by stage caught vs. stage that could have caught, blockers found late), what changed at each level and why, what was removed, and proposals waiting for the user. Tell the user the short version: what the factory learned and what it changed about itself.
