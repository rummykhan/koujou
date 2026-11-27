#!/usr/bin/env python3
"""koujou spawned <id>... [bd flags, e.g. --sandbox]
Count one agent run against each id: a task, or the epic (or a pass's run record) for agents that belong to no single
task: the epic review, the validator, scouts. Adds one to the issue's `agent_runs`, so nobody keeps the number in
their head; `koujou times` and the budget in `koujou converge` read it.

After counting it checks the run's budget (koujou budget) and exits 3, with the reason, when the run is over it:
the spawn is still counted, but the orchestrator must go to the user before starting it, and does not count it
again once the user raises the budget. An issue with no epic, pass label or parent is counted but has no budget."""
import importlib.util
import json
import pathlib
import subprocess
import sys
from datetime import datetime, timezone

# Time boxes in minutes, by role: what `koujou status` and `koujou ready` hold each live agent to.
BOX = {"builder": 60, "reviewer": 30, "epic-review": 45, "validator": 60, "tester": 60, "scout": 20, "security": 30}
# A role is over once its stage is stamped later than the spawn, so a forgotten `koujou reported` is not a false alarm.
DONE_STAMP = {"builder": "built_at", "reviewer": "reviewed_at", "validator": "validated_at"}


def live_agents(meta):
    """[(role, started datetime)] from the `agent_live` metadata, less those whose stage has since been stamped."""
    out = []
    for part in str(meta.get("agent_live") or "").split(","):
        role, _, at = part.partition("@")
        try:
            t = datetime.strptime(at, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
        except ValueError:
            continue
        stamp = meta.get(DONE_STAMP.get(role, ""))
        try:
            if stamp and datetime.strptime(stamp, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc) >= t:
                continue
        except ValueError:
            pass
        out.append((role, t))
    return out


def reported(args):
    """koujou reported <id> [--role <role>]: the agent has reported; it is no longer live."""
    role = args[args.index("--role") + 1] if "--role" in args and args.index("--role") + 1 < len(args) else None
    ids = [a for i, a in enumerate(args) if not a.startswith("-") and (i == 0 or args[i - 1] != "--role")]
    flags = [a for a in args if a.startswith("-") and a not in ("--role", "--all")]
    if not ids or not (role or "--all" in args):
        sys.exit("usage: koujou reported <id>... --role <role> | --all")
    for i in ids:
        shown = json.loads(subprocess.run(["bd", "show", i, "--json", "--readonly"], capture_output=True, text=True).stdout or "[]")
        if not shown:
            sys.exit(f"no issue {i}")
        parts = [p for p in str((shown[0].get("metadata") or {}).get("agent_live") or "").split(",") if p]
        keep = []
        if role:  # drop the oldest live agent of that role, keep the rest
            mine = [k for k, p in enumerate(parts) if p.startswith(role + "@")]
            keep = [p for k, p in enumerate(parts) if not mine or k != mine[0]]
        subprocess.run(["bd", "update", i, "--set-metadata", "agent_live=" + ",".join(keep), *flags], capture_output=True, text=True)
        print(f"{i}: {len(keep)} agent(s) still live")


def run_of(issue):
    """The run an issue's agents count against: the epic, a pass's label, or None."""
    labels = issue.get("labels") or []
    if issue.get("issue_type") == "epic":
        return [issue["id"]]
    passes = [l for l in labels if l.startswith("factory:pass-")]
    if passes:
        return ["--label", passes[0]]
    if issue.get("parent"):
        return [issue["parent"]]
    return None


def main(args):
    if args and args[0] == "--reported":
        return reported(args[1:])
    role = None
    resumed = "--resumed" in args
    args = [a for a in args if a != "--resumed"]
    if "--role" in args:
        k = args.index("--role")
        role = args[k + 1] if k + 1 < len(args) else None
        if role not in BOX:
            sys.exit(f"--role is one of: {', '.join(BOX)}")
        args = args[:k] + args[k + 2:]
    ids = [a for a in args if not a.startswith("-")]
    flags = [a for a in args if a.startswith("-")]
    if not ids:
        sys.exit("usage: koujou spawned <id>... [--role builder|reviewer|epic-review|validator|tester|scout|security] [bd flags]")
    runs = []
    for i in ids:
        out = subprocess.run(["bd", "show", i, "--json", "--readonly"], capture_output=True, text=True)
        shown = json.loads(out.stdout or "[]") if out.returncode == 0 else []
        if not shown:
            sys.exit(f"no issue {i}")
        try:
            n = int((shown[0].get("metadata") or {}).get("agent_runs") or 0) + 1
        except (TypeError, ValueError):
            n = 1
        sets = [] if resumed else ["--set-metadata", f"agent_runs={n}"]
        if resumed and not role:
            sys.exit("--resumed needs --role: it marks a continued agent live again without counting a new run")
        if role:
            meta = shown[0].get("metadata") or {}
            now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
            live = [f"{r}@{t.strftime('%Y-%m-%dT%H:%M:%SZ')}" for r, t in live_agents(meta)] + [f"{role}@{now}"]
            sets += ["--set-metadata", "agent_live=" + ",".join(live)]
        done = subprocess.run(["bd", "update", i, *sets, *flags], capture_output=True, text=True)
        if done.returncode != 0:
            sys.exit(done.stderr.strip() or "bd update failed")
        print(f"{i}: {n - 1 if resumed else n} agent run{'s' if (n - 1 if resumed else n) != 1 else ''}"
              + (f" ({role} resumed, live again, not counted)" if resumed else ""))
        r = run_of(shown[0])
        if r and r not in runs:
            runs.append(r)
    spec = importlib.util.spec_from_file_location("budget", pathlib.Path(__file__).with_name("koujou-budget.py"))
    budget = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(budget)
    over_any = False
    for r in runs:
        over, line = budget.check(r)
        print(line)
        over_any = over_any or over
    if over_any:
        sys.exit(3)


if __name__ == "__main__":
    main(sys.argv[1:])
