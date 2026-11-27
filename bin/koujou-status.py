#!/usr/bin/env python3
"""koujou status [<epic-id> | --label <label>] — where things stand, on one screen.

For each run in progress (an epic, or a pass's run record), or the one named: tasks done, in flight, ready and
waiting; the budget; every live agent with its age, flagged OVER BOX past its time box. Then what is waiting on the
user and what is stuck, across the tracker. Then stray processes: anything still running in a task worktree, which
after a run is a worker's leftover (one builder's `cat` waited on stdin for 63 hours). Read-only."""
import importlib.util
import json
import pathlib
import re
import subprocess
import sys
from datetime import datetime, timezone

HERE = pathlib.Path(__file__).parent


def load(name):
    spec = importlib.util.spec_from_file_location(name.replace("-", "_"), HERE / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def bd(*a):
    out = subprocess.run(["bd", *a, "--json", "--readonly"], capture_output=True, text=True)
    if out.returncode != 0:
        return []
    return json.loads(out.stdout or "[]") or []


def age(t):
    m = int((datetime.now(timezone.utc) - t).total_seconds() // 60)
    return f"{m // 60}h{m % 60:02d}m" if m >= 60 else f"{m}m"


def runs(args):
    if args and args[0] == "--label" and len(args) < 2:
        sys.exit("usage: koujou status [<epic-id> | --label <label>]")
    if args and args[0] == "--label":
        return [(f"pass {args[1]}", ["--label", args[1]], bd("list", "--label", args[1], "--all", "--limit", "0"))]
    if args:
        shown = bd("show", args[0])
        if not shown:
            sys.exit(f"no issue {args[0]}")
        return [(f"{args[0]}  {shown[0].get('title', '')[:70]}", [args[0]], bd("list", "--parent", args[0], "--all", "--limit", "0"))]
    out = []
    for e in bd("list", "--status", "in_progress", "--type", "epic", "--limit", "0"):
        out.append((f"{e['id']}  {e.get('title', '')[:70]}", [e["id"]], bd("list", "--parent", e["id"], "--all", "--limit", "0")))
    for r in bd("list", "--status", "in_progress", "--label", "factory:run", "--limit", "0"):
        lab = next((l for l in r.get("labels") or [] if l.startswith("factory:pass-")), None)
        if lab:
            out.append((f"pass {lab}", ["--label", lab], bd("list", "--label", lab, "--all", "--limit", "0")))
    return out


def secs(etime):
    """ps etime ([[dd-]hh:]mm:ss) in seconds."""
    days, _, rest = etime.rpartition("-")
    parts = [int(x) for x in rest.split(":") if x.isdigit()]
    while len(parts) < 3:
        parts.insert(0, 0)
    return int(days or 0) * 86400 + parts[0] * 3600 + parts[1] * 60 + parts[2]


def strays():
    root = None
    try:
        m = re.search(r"Worktree root:\s*`([^`]+)`", pathlib.Path(subprocess.run(
            ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip() or ".", "FACTORY.md").read_text())
        if m:
            root = pathlib.Path(m.group(1).split("<")[0]).name or None
    except OSError:
        pass
    marks = {".factory-worktrees", "factory-task/"} | ({root} if root else set())
    ps = subprocess.run(["ps", "-axo", "pid=,etime=,command="], capture_output=True, text=True).stdout
    found = []
    for line in ps.splitlines():
        pid, et, cmd = (line.strip().split(None, 2) + ["", ""])[:3]
        if (any(k in cmd for k in marks) and "koujou-status" not in cmd and not re.match(r"\S*claude(\s|$)", cmd)
                and secs(et) >= 600):   # a live worker's command is minutes old at most; leftovers are hours old
            found.append((pid, et, cmd))
    return found


def main(args):
    spawned, budget = load("koujou-spawned"), load("koujou-budget")
    shown_any = False
    for name, sel, listed in runs(args):
        shown_any = True
        ids = [i["id"] for i in listed]
        issues = bd("show", *ids) if ids else []
        if sel[0] != "--label":
            issues += bd("show", sel[0])
        tasks = [d for d in issues if d.get("issue_type") != "epic" and "factory:run" not in (d.get("labels") or [])]
        closed = sum(d.get("status") == "closed" for d in tasks)
        landed = sum("factory:awaiting-merge" in (d.get("labels") or []) and d.get("status") != "closed" for d in tasks)
        flight = sum(d.get("status") == "in_progress" and "factory:awaiting-merge" not in (d.get("labels") or []) for d in tasks)
        opened = sum(d.get("status") == "open" for d in tasks)
        print(f"{name}\n  tasks: {closed} closed, {landed} landed awaiting merge, {flight} in flight, {opened} open")
        print("  " + budget.check(sel)[1])
        for d in issues:
            for role, t in spawned.live_agents(d.get("metadata") or {}):
                box = spawned.BOX.get(role, 60)
                over = (datetime.now(timezone.utc) - t).total_seconds() > box * 60
                print(f"  agent  {d['id']} {role} for {age(t)}" + (f"  OVER BOX ({box}m): is it alive? stop and replace it" if over else ""))
    if not shown_any:
        print("no run in progress")
    asks = bd("list", "--label", "factory:needs-user", "--status", "open", "--limit", "0")
    stuck = [d for d in bd("list", "--label", "factory:stuck", "--limit", "0") if d.get("status") != "closed"]
    print(f"\nwaiting on you: {len(asks)}" + "".join(f"\n  {d['id']}  {d.get('title', '')[:80]}" for d in asks))
    print(f"stuck: {len(stuck)}" + "".join(f"\n  {d['id']}  {d.get('title', '')[:80]}" for d in stuck))
    found = strays()
    print(f"processes in task worktrees for 10m or more: {len(found)}" + "".join(f"\n  pid {p} up {e}  {c[:110]}" for p, e, c in found)
          + ("\n  (a worker's leftover once its task has landed: kill <pid>)" if found else ""))


if __name__ == "__main__":
    main(sys.argv[1:])
