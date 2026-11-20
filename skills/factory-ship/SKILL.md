---
name: factory-ship
description: Factory stage 5 — ship a validated epic or pass. Pushes the branch, opens the pull request, waits for CI, merges with the user's approval, checks the deployment, then closes the issues and cleans up. Use at the end of factory-run, or later on a branch that is waiting to be merged ("ship it", "open the PR", "merge the factory branch").
---

# Factory: ship

Input: an epic or pass branch whose gate is green, whose reviews and security review passed, and whose last validation passed. Output: the work on the base branch, deployed where the project deploys, issues closed, tracker synced, machine clean.

Read `FACTORY.md` first: `## Git policy` (push, integration, who merges, merge method) and `## Deploy policy` (what a merge triggers, rollback, post-deploy checks). The profile decides how far this stage goes on its own:

| Profile says | The factory does |
|---|---|
| Integration: pull request; merge: factory, after approval (the default) | Everything below, stopping once to ask before merging |
| Merge: factory, standing permission | Everything below without stopping, for the environments the permission names |
| Merge: user | Steps 1 to 3, then hands over the PR link and waits; resume at step 5 when the user says it is merged |
| Push: never, or no remote | Step 1, then merges locally into the base branch only if the profile allows it; otherwise hands over the branch name |

Never read silence as approval, and never treat approval given for an earlier merge as covering this one unless the profile records standing permission.

## 1. Check that it is ready

- No child of the epic (or issue in the pass) is open except those labelled `factory:awaiting-merge`, `factory:deferred` or `factory:stuck`; stuck ones are named in the PR as not included.
- `report.md` exists and names the commit that was validated. If the branch has moved since, re-run the gate; if product code changed, it needs validating again before it ships.
- Fetch the base. If it has moved, bring the branch up to date (`git rebase origin/<base>`, or merge if the project's history style says so), resolve conflicts, and run the full gate again. A conflict in product code that is not mechanical goes to a builder, and the result to a reviewer, like any other change.
- The working tree is clean and nothing in the diff is a secret, a local env file or evidence too large to commit.

## 2. Push and open the pull request

```bash
git push -u origin factory/<epic-id>
gh pr create --base <base> --head factory/<epic-id> --title "<outcome, in the project's style>" --body-file <work-order>/pr.md
```

Write `pr.md` from the report: what changed for users, by requirement or issue; how it was verified (gate result, review counts, security review result, validator verdict, where the evidence is); what is not included (deferred, stuck, waiting on the user); what merging will trigger (a deploy to which environment); how to roll back. Keep it short enough to be read.

One pull request per epic or pass. Task branches are not pushed; they were merged into the epic branch one at a time during the run.

## 3. Wait for CI

```bash
gh pr checks <number> --watch
```

A red check is a failure of this stage, not noise. Read the log. If the branch caused it, it goes back into the delivery loop as a fix-now bug (builder, reviewer, merge), then push again. If it fails on the base too, show the user; do not merge over it.

## 4. Merge

Show the user, in one message: the PR link, the checks, what merging triggers, anything not included, and the rollback. Ask to merge. On approval (or standing permission):

```bash
gh pr merge <number> --<merge|squash|rebase per the profile> --delete-branch
```

If the profile requires a human reviewer on the PR, the factory does not approve its own PR or bypass branch protection; it waits.

## 5. After the merge

- **Watch the deploy** the merge triggered, with the command the profile gives (a CI run, a pipeline, a stack status). Wait for it to finish; a merge is not a deploy.
- **Check the deployed product**: run the profile's post-deploy smoke. If the profile names a deployed environment for validation (see below), run the acceptance suite or the validator against it now.
- **If the deploy or the check fails**: tell the user at once, with what failed and the rollback procedure from the profile. Roll back yourself only if the profile says the factory may. Then it is a P0 bug in the next round.
- **Close the issues**: every issue labelled `factory:awaiting-merge` in this epic or pass is closed with a reason naming the merge commit, and the label removed; then close the epic if every child is closed. `bd dolt push` if the tracker syncs and the profile says the factory may push it.
- **Record the time**: `bd update <epic> --set-metadata shipped_at=$(date -u +%FT%TZ)`.
- **Clean up**: remove the epic worktree and local branch, stop anything this run started, and update the user's checkout only if they ask.
- Add what shipped, the merge commit and the deploy result to `report.md`.

## Validating a deployed environment

The delivery loop validates a local build by default: it needs no cloud account, costs nothing, and cannot hurt anyone. A project that has a deployed test environment can add it in the profile (`Deployed validation`), and then this stage runs the acceptance suite and a `factory-validator` against that URL after the deploy, with test accounts only. Against production, the check is the smoke command and read-only pages unless the profile explicitly allows more: no sign-ups with invented people, no writes to real data, nothing billable.

## Next

`factory-retro`, if it has not run for this epic yet.
