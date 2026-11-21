#!/usr/bin/env python3
"""koujou converge <epic-id> | --label <label> [--record] [bd flags] — may the fix loop go on?

After a validation round has been triaged, this reads the run from beads and answers from evidence, not from a
count of rounds: a loop that is closing bugs may run as long as it needs; one that is not, stops.

  stuck <id>: ...   this bug stops and goes to the user; the rest carry on
  stop: ...         the whole loop stops (exit 1)
  continue: ...     build the open bugs and validate again (exit 0)

--record appends this round's count of open fix-now bugs to the run's history (`round_open`) and adds one to
`validate_rounds`; without it nothing is written."""
import json
import pathlib
import re
import subprocess
import sys

SKIP = {"factory:deferred", "factory:stuck", "factory:needs-user"}


def bd(*a):
    out = subprocess.run(["bd", *a, "--json", "--readonly"], capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(out.stderr.strip() or "bd failed")
    return json.loads(out.stdout or "[]")


def num(v, default=0):
    try:
        return int(v)
    except (TypeError, ValueError):
        return default


def limit(name, default):
    try:
        m = re.search(rf"`?{name}`?\s*:\s*(\d+)", pathlib.Path("FACTORY.md").read_text())
        return int(m.group(1)) if m else default
    except OSError:
        return default


def main(args):
    record = "--record" in args
    args = [a for a in args if a != "--record"]
    if not args or (args[0] == "--label" and len(args) < 2):
        sys.exit("usage: koujou converge <epic-id> | --label <label> [--record] [bd flags]")
    if args[0] == "--label":
        ids, flags, holder = [i["id"] for i in bd("list", "--label", args[1], "--all", "--limit", "0")], args[2:], None
    else:
        shown = bd("show", args[0])
        if not shown:
            sys.exit(f"no issue {args[0]}")
        holder, flags = shown[0], args[1:]
        ids = [i["id"] for i in bd("list", "--parent", args[0], "--all", "--limit", "0")]

    issues = {}
    for d in (bd("show", *ids) if ids else []):  # one call for all of them: a call per issue made a large run slow
        i = d["id"]
        if "factory:run" in (d.get("labels") or []):
            holder = d
            continue
        if d.get("issue_type") != "epic":
            issues[i] = d
    if holder is None:
        sys.exit("no epic or run record (a task labelled factory:run) to hold the round history")

    bugs = {i: d for i, d in issues.items() if d.get("issue_type") == "bug" and not SKIP & set(d.get("labels") or [])}
    live = {i: d for i, d in bugs.items() if d.get("status") != "closed"}

    def depth(i, seen=()):
        # how many open bugs sit under this one: a bug whose fix is waiting on another bug's fix, and so on down
        below = [b["id"] for b in live[i].get("dependencies") or []
                 if b.get("dependency_type") == "blocks" and b["id"] in live and b["id"] not in seen]
        return 1 + max((depth(b, (*seen, i)) for b in below), default=0)

    max_depth = limit("max_fix_depth", 3)
    stuck = {}
    for i, d in live.items():
        if num((d.get("metadata") or {}).get("reopened")) >= 2:
            stuck[i] = "its fix has failed validation twice"
    for i in live:
        if i not in stuck and depth(i) > max_depth:
            stuck[i] = f"fixing it has uncovered a chain of {depth(i)} bugs, each waiting on the next (limit {max_depth})"
    for i, why in stuck.items():
        print(f"stuck {i}: {why}")
    going = [i for i in live if i not in stuck]

    meta = holder.get("metadata") or {}
    history = [num(x) for x in str(meta.get("round_open") or "").split(",") if x.strip() != ""]
    if record:
        history.append(len(live))
        done = subprocess.run(["bd", "update", holder["id"], "--set-metadata", "round_open=" + ",".join(map(str, history)),
                               "--set-metadata", f"validate_rounds={len(history)}", *flags], capture_output=True, text=True)
        if done.returncode != 0:
            sys.exit(done.stderr.strip() or "bd update failed")
    shown = ", ".join(map(str, history)) or "none recorded"

    runs = sum(num((d.get("metadata") or {}).get("agent_runs")) for d in issues.values()) + num(meta.get("agent_runs"))
    planned = sum(1 for d in issues.values() if d.get("issue_type") != "bug")
    budget = limit("max_agent_runs", max(30, 12 * planned))

    stop = None
    if not going and live:
        stop = "every open bug is stuck"
    elif len(history) >= 3 and history[-1] and history[-1] >= history[-2] >= history[-3]:
        stop = f"no progress: open fix-now bugs after each round were {shown}; two rounds running have not brought the number down"
    elif runs > budget:
        stop = f"budget: {runs} agent runs so far, limit {budget} (max_agent_runs)"
    if stop:
        print(f"stop: {stop}")
        sys.exit(1)
    print(f"continue: {len(going)} open fix-now bug(s); open after each round: {shown}; {runs} of {budget} agent runs used")


if __name__ == "__main__":
    main(sys.argv[1:])
