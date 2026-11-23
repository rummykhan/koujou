---
name: factory-ship
description: Factory stage 5 — ship a validated epic or pass. Pushes the branch, opens the pull request, waits for CI, merges with the user's approval, checks the deployment, then closes the issues and cleans up. Use at the end of factory-run, or later on a branch that is waiting to be merged ("ship it", "open the PR", "merge the factory branch").
---

# Factory: ship

Input: an epic or pass branch whose gate is green, whose reviews passed and whose last validation passed. Output: the work on the base branch, deployed where the project deploys, issues closed, tracker synced, machine clean.

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
- `report.md` exists and names the commit that was validated. If the branch has moved since, re-run the gate, and treat what was added as unreviewed: a `factory-reviewer` reads that diff (told there is no task, only "does this do what its commit says, and nothing else"), a `factory-security` agent too if it touches what a lens covers, and whatever user-visible behaviour it changed is validated again. Copy and wording changes count: on the second real pass two legal pages were edited after validation and reached production seen only by the gate. Say in the report what was added late and how it was checked.
- Every prerequisite of this epic or pass is closed, or the user has said to ship without it. One that needs a production change is handled in step 1b.
- `report.md` and `pr.md` describe the branch as it is now. Asks that have been answered since they were written come out of "waiting on you".
- Fetch the base. If it has moved, bring the branch up to date (`git rebase origin/<base>`, or merge if the project's history style says so), resolve conflicts, and run the full gate again. A conflict in product code that is not mechanical goes to a builder, and the result to a reviewer, like any other change.
- The working tree is clean and nothing in the diff is a secret, a local env file or evidence too large to commit.

## 1b. Production changes the deploy does not make

A new table, index, queue, secret or migration that the project's normal deploy will not create has to exist before the code that uses it is merged. Who may make it is the profile's Deploy policy. If that is the user, ask (the intake should already have); a yes covers this change only, so record it on the prerequisite's issue and ask whether the profile should say so for next time. Do not edit the profile's policy on your own.

When the factory makes the change:

1. Confirm the branch contains the current base (`git merge-base --is-ancestor origin/<base> HEAD`), so that applying it cannot undo someone else's change.
2. Look before applying: the tool's dry run or diff (`cdk diff`, `terraform plan`, the migration's dry run), scoped to the smallest unit that holds the change (one stack, one migration).
3. Go on only if the diff shows exactly what the prerequisite names and nothing else. Anything more, and any replacement or deletion, goes to the user with the diff.
4. Apply that one unit, not everything.
5. Verify the thing itself with a read-only call (the table is active, the index exists, the variable is set), and write what you ran and saw on the prerequisite's issue before closing it.
6. Note a post-deploy check for step 5 that would show the shipped code actually using it.

## 2. Push and open the pull request

```bash
git push -u origin factory/<epic-id>
gh pr create --base <base> --head factory/<epic-id> --title "<outcome, in the project's style>" --body-file <work-order>/pr.md
```

Write `pr.md` from the report: what changed for users, by requirement or issue; how it was verified (gate result, review counts, validator verdict, a security review's result if the user asked for one, where the evidence is); what is not included (deferred, stuck, waiting on the user); what merging will trigger (a deploy to which environment); how to roll back. Keep it short enough to be read.

One pull request per epic or pass. Task branches are not pushed; they were merged into the epic branch one at a time during the run.

## 3. Wait for CI

```bash
gh pr checks <number> --watch
```

A red check is a failure of this stage, not noise. Read the log. If the branch caused it, it goes back into the delivery loop as a fix-now bug (builder, reviewer, merge), then push again. If it fails on the base too, show the user; do not merge over it.

## 4. Merge

Show the user, in one message: the PR link, the checks, what merging triggers, anything not included, and the rollback. Ask to merge. On approval (or standing permission):

```bash
gh pr merge <number> --<merge|squash|rebase per the profile> --delete-branch --match-head-commit <the sha that was checked>
```

`--match-head-commit` makes the merge fail if the branch moved after the checks you showed.

If the profile requires a human reviewer on the PR, the factory does not approve its own PR or bypass branch protection; it waits.

## 5. After the merge

- **Watch the deploy** the merge triggered, with the command the profile gives (a CI run, a pipeline, a stack status). Wait for it to finish; a merge is not a deploy.
- **Check the deployed product**: run the profile's post-deploy smoke. Then check what this change in particular needed: for each production prerequisite, the check noted in step 1b, done with reads and with the product's ordinary public behaviour only (a page that shows the new wording; the new table gaining a row after normal use; the logs free of the error the code writes when the thing is missing). Code that fails open looks healthy to a smoke test while doing nothing. What you could not check without probing production goes in the report as not verified, with what would show it. If the profile names a deployed environment for validation (see below), run the acceptance suite or the validator against it now.
- **If the deploy or the check fails**: tell the user at once, with what failed and the rollback procedure from the profile. Roll back yourself only if the profile says the factory may. Then it is a P0 bug in the next round.
- **Close the issues**: every issue labelled `factory:awaiting-merge` in this epic or pass is closed with a reason naming the merge commit, and the label removed. Then confirm none is left (`bd list --label factory:awaiting-merge`) before closing the epic or the run record: a loop that failed quietly once closed the record over eight open issues. `bd dolt push` if the tracker syncs and the profile says the factory may push it.
- **Record the time**: `bd update <epic> --set-metadata shipped_at=$(date -u +%FT%TZ)`, and `koujou wait <epic> end` if the run was waiting.
- **Clean up**: remove the epic worktree and local branch, stop anything this run started, and update the user's checkout only if they ask. Then look: `git worktree list` and `git branch --list 'factory*'` should show nothing of this run. Report what you saw, not what you intended.
- Add what shipped, the merge commit and the deploy result to `report.md`.

## Validating a deployed environment

The delivery loop validates a local build by default: it needs no cloud account, costs nothing, and cannot hurt anyone. A project that has a deployed test environment can add it in the profile (`Deployed validation`), and then this stage runs the acceptance suite and a `factory-validator` against that URL after the deploy, with test accounts only. Against production, the check is the smoke command and read-only pages unless the profile explicitly allows more: no sign-ups with invented people, no writes to real data, nothing billable.

## Next

`factory-retro`, if it has not run for this epic yet.
