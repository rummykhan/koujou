# Prerequisites and blockers: getting what only the user can provide

Agents can write code; they cannot conjure an API key, an account, a DNS record, a design asset or a business decision. Work that needs one of these either waits for the user or goes ahead on a stand-in. The factory's job is to find these needs **early**, ask for them **once, together**, and keep everything else moving when an answer is not available.

## What counts as a prerequisite

Anything outside the repo that the work needs and an agent cannot produce:

- **Credentials and access** — API keys, OAuth client ids, cloud profiles, repo or registry permissions, test accounts, webhook secrets
- **External setup** — a third-party app registration, a domain or DNS record, a billing plan, a sandbox tenant, an allow-listed IP
- **Decisions** — a product or pricing choice, anything that spends money or is hard to reverse, a legal or brand call, and any behaviour the issue leaves open where the options differ in security or in what users are promised (which hosts a redirect may go to; whether one part of the system may write another's data)
- **Assets and data** — logos, copy, sample files, a data export, a schema from another team
- **People** — a manual step only the user can do (approve an app, click a confirmation email, sign in once with a real account)

## Stage 1: sweep for them up front

`factory-spec` and `factory-design` each end with a prerequisite sweep. A pass picked from an existing backlog skips both stages, so `factory-plan` runs the same sweep as its intake, with one scout per issue, and records it in the pass's `intake.md`. Go through the requirements and design and ask of every external touchpoint: what does this need that we do not have? Check what already exists before asking (env files by variable *name*, secret managers the profile mentions, existing config). Record the result in the requirements under `## Prerequisites`:

| # | What | Needed by | Why | Status | If unavailable |
|---|---|---|---|---|---|
| P1 | Stripe test secret key, as `STRIPE_SECRET_KEY` in `.env.local` | R3 | Create checkout sessions | pending | Build against a fake gateway behind the same interface; real-key verification moves to the next pass |

Then ask the user for all of them in one message, at the approval gate, each with what exactly is needed, where to put it, and what happens if they cannot provide it now. Three answers are possible, and all three are fine:

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
   - Otherwise → batched, at the next natural stop (a wave boundary, before deploy, in the report). One message listing every open need beats five interruptions.
5. **When the user answers**, verify the thing works, `bd gate resolve <gate>`, close the prerequisite bead, and the blocked tasks reappear in `bd ready`.
6. **If the epic finishes first**, the gated tasks are moved out of it (`bd update <task> --parent "" --add-label factory:deferred`; the gate stays), and the report lists them under "Waiting on you" with exactly what is needed to pick them up in the next pass.

What is waiting on the user, at any time: `bd list --label factory:needs-user --status open` and `bd gate list`.

## Secrets

- A secret goes where the profile says (an env file that is git-ignored, a secret manager). It never goes into a bead, a comment, a commit, a log, a report, or an agent brief. Refer to secrets by variable name.
- Ask the user to place the secret themselves rather than paste it into the conversation, when that is practical.
- An agent given access to a credential uses it only for the task it was given for, against test or sandbox systems unless the profile says otherwise.
