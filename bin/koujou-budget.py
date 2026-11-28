#!/usr/bin/env python3
"""koujou budget <epic-id> | --label <label> [bd flags] — is the run still inside its budget of agents and time?

A run gets a budget when it starts, and every `koujou spawned` checks it, so a run cannot drift past it unnoticed:
shukka v1 spawned 135 agents over 61 hours for work its owner would have written by hand in far less.

  agents   `agent_budget` on the epic (or run record: the user's raise wins), else max_agent_runs in FACTORY.md,
           else 3 per planned task (one builder, one retry, a share of the end review and validation), at least 10
  time     `time_budget_h` on the epic, else time_budget_hours in FACTORY.md, else 1 hour per planned task, at least
           4 (fractions allowed); measured from the run's start, less the time it stood waiting on the user (koujou wait)

Raising a budget is the user's call: `bd update <epic> --set-metadata agent_budget=<n>` (or time_budget_h=<h>).
Exit 0 inside the budget, 1 over it."""
import json
import pathlib
import re
import subprocess
import sys
from datetime import datetime, timezone


def bd(*a):
    out = subprocess.run(["bd", *a, "--json", "--readonly"], capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(out.stderr.strip() or "bd failed")
    return json.loads(out.stdout or "[]")


def num(v, default=0):
    try:
        return int(float(v))
    except (TypeError, ValueError):
        return default


def real(v):
    try:
        return float(v) or None
    except (TypeError, ValueError):
        return None


def profile(name):
    # FACTORY.md sits at the repository root; read it there whatever directory the command runs in
    top = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip()
    try:
        m = re.search(rf"`?{name}`?\s*:\s*(\d+(?:\.\d+)?)", (pathlib.Path(top or ".") / "FACTORY.md").read_text())
        return float(m.group(1)) if m else None
    except OSError:
        return None


def ts(v):
    try:
        return datetime.strptime(v, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
    except (TypeError, ValueError):
        return None


def check(args):
    """Returns (over, line). Shared with koujou spawned."""
    if not args or (args[0] == "--label" and len(args) < 2):
        sys.exit("usage: koujou budget <epic-id> | --label <label> [bd flags]")
    if args[0] == "--label":
        ids, holder = [i["id"] for i in bd("list", "--label", args[1], "--all", "--limit", "0")], None
    else:
        shown = bd("show", args[0])
        if not shown:
            sys.exit(f"no issue {args[0]}")
        holder = shown[0]
        ids = [i["id"] for i in bd("list", "--parent", args[0], "--all", "--limit", "0")]
    issues = []
    for d in (bd("show", *ids) if ids else []):
        if "factory:run" in (d.get("labels") or []):
            holder = d
        elif d.get("issue_type") != "epic":
            issues.append(d)
    return compute(holder, issues)


def compute(holder, issues):
    """(over, line) from the run's holder (epic or run record) and its issues, already read."""
    meta = (holder or {}).get("metadata") or {}

    planned = sum(1 for d in issues if d.get("issue_type") != "bug")
    runs = sum(num((d.get("metadata") or {}).get("agent_runs")) for d in issues) + num(meta.get("agent_runs"))
    agents = int(real(meta.get("agent_budget")) or profile("max_agent_runs") or max(10, 3 * planned))
    hours = real(meta.get("time_budget_h")) or profile("time_budget_hours") or max(4, planned)
    hours = int(hours) if float(hours).is_integer() else hours

    start = ts(meta.get("claimed_at")) or ts((holder or {}).get("started_at"))
    end = ts((holder or {}).get("closed_at")) or datetime.now(timezone.utc)
    elapsed = 0
    if start:
        elapsed = (end - start).total_seconds() - num(meta.get("waited_s"))
        if ts(meta.get("waiting_since")):
            elapsed -= (end - ts(meta["waiting_since"])).total_seconds()
    used_h = max(0, elapsed) / 3600

    over = []
    if runs > agents:
        over.append(f"{runs} agents, budget {agents}")
    if used_h > hours:
        over.append(f"{used_h:.1f}h working, budget {hours}h")
    if over:
        return True, ("OVER BUDGET: " + "; ".join(over) + ". Before spawning another agent, tell the user what is "
                      "taking the time and what is left, and ask whether to go on (they raise it with "
                      "bd update <epic> --set-metadata agent_budget=<n> / time_budget_h=<h>).")
    return False, f"within budget: {runs} of {agents} agents, {used_h:.1f}h of {hours}h ({planned} planned tasks)"


def main(args):
    flags_free = [a for a in args if not (a.startswith("--") and a != "--label")]
    over, line = check(flags_free)
    print(line)
    sys.exit(1 if over else 0)


if __name__ == "__main__":
    main(sys.argv[1:])
