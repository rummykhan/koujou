# Prerequisites and blockers: getting what only the user can provide

Agents can write code; they cannot conjure an API key, an account, a DNS record, a design asset or a business decision. Work that needs one of these either waits for the user or goes ahead on a stand-in. The factory's job is to find these needs **early**, ask for them **once, together**, and keep everything else moving when an answer is not available.

## What counts as a prerequisite

Anything outside the repo that the work needs and an agent cannot produce:

- **Credentials and access** — API keys, OAuth client ids, cloud profiles, repo or registry permissions, test accounts, webhook secrets
- **External setup** — a third-party app registration, a domain or DNS record, a billing plan, a sandbox tenant, an allow-listed IP
- **Production changes the deploy does not make** — a new table, index, queue, environment variable or secret, or a data migration, where the project's normal deploy ships code only. Code that fails open or falls back when the thing is missing will look shipped while doing nothing
- **Decisions** — a product or pricing choice, anything that spends money or is hard to reverse, a legal or brand call, and any behaviour the issue leaves open where the options differ in security or in what users are promised (which hosts a redirect may go to; whether one part of the system may write another's data)
- **Assets and data** — logos, copy, sample files, a data export, a schema from another team
- **Permission** — something the factory could do itself but the profile reserves for the user: deploying infrastructure, running a migration, editing a legal page, spending money. This is a question of yes or no, and it is asked with the others up front: "this work needs a new table in production; may the factory create it, or will you?" A permission discovered at the end of the run holds a finished branch hostage to a one-word answer
- **People** — a manual step only the user can do (approve an app, click a confirmation email, sign in once with a real account)

## Stage 1: sweep for them up front

`factory-spec` and `factory-design` each end with a prerequisite sweep. A pass picked from an existing backlog skips both stages, so `factory-plan` runs the same sweep as its intake, with one scout per issue, and records it in the pass's `intake.md`. Go through the requirements and design and ask of every external touchpoint: what does this need that we do not have? Check what already exists before asking (env files by variable *name*, secret managers the profile mentions, existing config). Record the result in the requirements under `## Prerequisites`:

| # | What | Needed by | Why | Status | If unavailable |
|---|---|---|---|---|---|
| P1 | Stripe test secret key, as `STRIPE_SECRET_KEY` in `.env.local` | R3 | Create checkout sessions | pending | Build against a fake gateway behind the same interface; real-key verification moves to the next pass |

Then ask the user for all of them in one message, at the approval gate, each with what exactly is needed, where to put it, and what happens if they cannot provide it now. For anything the factory could do itself given leave (a production change, a page's wording), ask for the leave rather than for the deed, and say exactly what the factory would run or write. Three answers are possible, and all three are fine:

- **Provided** → status `provided`. Verify it works with the cheapest possible call before relying on it.
- **Later** → status `pending`. The work that needs it is planned behind a gate (below) and everything else proceeds.
- **Not this pass** → status `next pass`. The dependent work is either built against a stand-in or left out of this epic, and the report says so.

## Stage 2: encode them in the plan

In `factory-plan`, every prerequisite that is not `provided` becomes a bead so the graph knows about it:

```bash
P=$(bd create "P1: Stripe test secret key in .env.local as STRIPE_SECRET_KEY" -t task -p 1 \
      -l factory:needs-user \
      -d "<what, where to put it, how the factory will verify it>" \
      --acceptance "- The key is present and a test API call succeeds" --silent)
bd gate create --blocks $P --reason "Waiting on the user: Stripe test key"
bd dep add <task-that-needs-it> $P
```

The prerequisite bead is not a child of the epic. It often outlives the epic (the key arrives next week), and a child that cannot close keeps the epic open. Mention it in the epic's notes instead.

Then shape the plan so as little as possible sits behind it:

- Put the external thing behind an interface and plan a fake or sandbox implementation, so builders and QA proceed without the real one.
- Split each dependent task into the part buildable now (against the interface) and a thin verification task that needs the real thing. Only the thin task depends on the prerequisite bead.
- A prerequisite marked `next pass` gets no gate in this epic: its thin tasks are created with `factory:deferred` and no parent, and the epic's success criteria are written to be satisfiable without them.

## Stage 3: bubble up what surfaces mid-run

Some needs only appear once someone is in the code. The path is always the same:

1. **The worker stops guessing.** A builder, tester or validator that hits a need only the user can meet does not invent a value, hard-code a placeholder that looks real, skip the check silently, or go hunting through the machine for credentials it was not given. It finishes what does not depend on the need and reports it under `needs_user`, stating what is needed, why, what it tried, and what stand-in would let work continue.
2. **The orchestrator records it** as a `factory:needs-user` bead with a gate, blocking exactly the work that needs it, and adds it to the requirements' prerequisite table.
3. **The orchestrator keeps the factory running** on everything not behind the gate.
4. **The orchestrator tells the user**, choosing the moment by impact:
   - On the critical path (nothing else can proceed, or most of the epic is behind it) → now.
   - It will block the merge (a production change someone must make, a permission, a decision the shipped code depends on) → at the next wave boundary, while building continues. Never hold it for the final report: the second real pass finished with three such asks, all known for hours, and the validated branch then waited on answers that took the user one line.
   - Otherwise → batched, at the next natural stop (before deploy, in the report). One message listing every open need beats five interruptions.
5. **When the user answers**, verify the thing works, `bd gate resolve <gate>`, close the prerequisite bead, and the blocked tasks reappear in `bd ready`.
6. **If the epic finishes first**, the gated tasks are moved out of it (`bd update <task> --parent "" --add-label factory:deferred`; the gate stays), and the report lists them under "Waiting on you" with exactly what is needed to pick them up in the next pass.

What is waiting on the user, at any time: `bd list --label factory:needs-user --status open` and `bd gate list`.

## Bring a draft, not a question

When the need is something the factory can produce and the user only has to approve (wording for a page, a config value, a default behaviour, a migration script), produce it. Make the change as its own commit on the branch, name it in the pull request as awaiting the user's eye, and show the user the result. "Two legal pages need your wording" sent a user away to write prose; the same user, asked again, said to draft it. A bare question is for choices where the factory has no basis to prefer one answer.

Two limits on drafts of anything the public or a customer will read (legal pages, pricing, emails):

- Quote the new sentences to the user in full. A summary of a promise is not the promise.
- Every sentence must be true of the product as shipped. If the draft commits the user to something nothing implements ("removed on request by email"), either reword it or file an issue for the missing part and say so beside the quote.

## Asking so that it gets answered

A question the user has to decode does not get answered. Write each ask so that someone who has not read the code can decide:

- Say what happens, to whom, in the order it happens, with the product's own nouns. For a security finding: who the attacker is, what they do step by step, what the victim loses, and whether it was reproduced or reasoned.
- Give the options, what each costs the user or their customers, and the one you recommend.
- If an ask goes unanswered while the user answers the things around it, the wording failed. Rewrite it from the start in plainer terms; do not send the same paragraph again.

## Waiting is not working

When the run can do nothing more until the user answers, `koujou wait <epic or run record> start`; when they answer, `koujou wait <id> end`. The report then shows working time and waiting time apart, and a run that sat overnight does not read as a run that worked overnight.

## Secrets

- A secret goes where the profile says (an env file that is git-ignored, a secret manager). It never goes into a bead, a comment, a commit, a log, a report, or an agent brief. Refer to secrets by variable name.
- Ask the user to place the secret themselves rather than paste it into the conversation, when that is practical.
- An agent given access to a credential uses it only for the task it was given for, against test or sandbox systems unless the profile says otherwise.
