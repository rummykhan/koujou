#!/usr/bin/env python3
"""koujou times <epic-id> | --label <label> — where a factory run's time went, read from beads."""
import json
import subprocess
import sys
from datetime import datetime


def bd(*a):
    out = subprocess.run(["bd", *a, "--json", "--readonly"], capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(out.stderr.strip() or "bd failed")
    return json.loads(out.stdout or "[]")


def ts(v):
    try:
        return datetime.fromisoformat(str(v).replace("Z", "+00:00"))
    except (TypeError, ValueError):
        return None


def dur(a, b):
    if not a or not b or b < a:
        return None
    return (b - a).total_seconds()


def fmt(s):
    if s is None:
        return "-"
    s = int(s)
    h, m = divmod(s // 60, 60)
    return f"{h}h{m:02d}m" if h else (f"{m}m{s % 60:02d}s" if m else f"{s}s")


def main(args):
    if not args or (args[0] == "--label" and len(args) < 2):
        sys.exit("usage: koujou times <epic-id> | --label <label>")
    epic = None
    if args[0] == "--label":
        ids = [i["id"] for i in bd("list", "--label", args[1], "--all", "--limit", "0")]
        title = f"label {args[1]}"
    else:
        shown = bd("show", args[0])
        if not shown:
            sys.exit(f"no issue {args[0]}")
        epic = shown[0]
        ids = [i["id"] for i in bd("list", "--parent", args[0], "--all", "--limit", "0")]
        title = f"{epic['id']} — {epic['title']}"

    rows, firsts, lasts, runs_total = [], [], [], 0
    for i in ids:
        d = bd("show", i)[0]
        if d.get("issue_type") == "epic":
            continue
        if "factory:run" in (d.get("labels") or []):  # a pass's run record stands in for the epic
            epic = d
            continue
        m = d.get("metadata") or {}
        start = ts(d.get("started_at"))
        built, reviewed, merged = ts(m.get("built_at")), ts(m.get("reviewed_at")), ts(m.get("merged_at"))
        end = merged or ts(d.get("closed_at"))
        if start:
            firsts.append(start)
        last = end or reviewed or built
        if last:
            lasts.append(last)
        runs = m.get("agent_runs")
        try:
            runs_total += int(runs)
        except (TypeError, ValueError):
            pass
        rows.append((
            d["id"], d.get("status", ""),
            fmt(dur(start, built)), fmt(dur(built, reviewed)), fmt(dur(reviewed, merged)), fmt(dur(start, end)),
            str(m.get("fix_attempts", 0)), str(m.get("rebases", 0)), str(runs if runs is not None else "-"),
            (d.get("title") or "")[:44],
        ))

    if not rows:
        sys.exit("no issues found")
    head = ("issue", "status", "build", "review", "queue", "total", "bounces", "rebases", "agents", "title")
    w = [max(len(r[k]) for r in rows + [head]) for k in range(len(head))]
    print(title)
    for r in [head] + rows:
        print("  " + "  ".join(c.ljust(w[k]) for k, c in enumerate(r)).rstrip())
    print()
    if firsts and lasts:
        print(f"  build waves, first claim to last landing: {fmt(dur(min(firsts), max(lasts)))}")
    if epic:
        m = epic.get("metadata") or {}
        s = ts(epic.get("started_at"))
        if firsts and (not s or min(firsts) < s):
            s = min(firsts)
        for label, key in (("security review done", "security_at"), ("validated", "validated_at"), ("shipped", "shipped_at")):
            if ts(m.get(key)):
                print(f"  start to {label}: {fmt(dur(s, ts(m.get(key))))}")
        if ts(epic.get("closed_at")):
            print(f"  start to closed: {fmt(dur(s, ts(epic.get('closed_at'))))}")
        try:
            runs_total += int(m.get("agent_runs"))  # agents not tied to one task: scouts, security lenses, validators
        except (TypeError, ValueError):
            pass
        if "validate_rounds" in m:
            print(f"  validation rounds that found bugs: {m['validate_rounds']}")
    if runs_total:
        print(f"  agents spawned: {runs_total}")
    print("  build = claim to builder done (incl. retries) · review = to review pass · "
          "queue = to landing on the epic branch · '-' = not recorded")


if __name__ == "__main__":
    main(sys.argv[1:])
