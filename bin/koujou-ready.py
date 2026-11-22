#!/usr/bin/env python3
"""koujou ready <epic-id> | --label <label>
The tasks of a run that can start now. Like `bd ready`, except that a task which is built, reviewed and landed but
left open until the user merges (label factory:awaiting-merge) counts as finished: `bd ready` still sees it as in
progress, so in a project that closes issues on merge it shows nothing after the first wave."""
import json
import subprocess
import sys

DONE = "factory:awaiting-merge"
HELD = {"factory:stuck", "factory:needs-user", "factory:deferred", "factory:run"}


def bd(*a):
    out = subprocess.run(["bd", *a, "--json", "--readonly"], capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(out.stderr.strip() or "bd failed")
    return json.loads(out.stdout or "[]")


def main(args):
    if not args or (args[0] == "--label" and len(args) < 2):
        sys.exit("usage: koujou ready <epic-id> | --label <label>")
    sel = ["--label", args[1]] if args[0] == "--label" else ["--parent", args[0]]
    ids = [i["id"] for i in bd("list", *sel, "--all", "--limit", "0")]
    issues = {d["id"]: d for d in (bd("show", *ids) if ids else [])}

    def finished(d):
        return d.get("status") == "closed" or DONE in (d.get("labels") or [])

    ready, waiting = [], []
    for i, d in issues.items():
        labels = set(d.get("labels") or [])
        if d.get("issue_type") == "epic" or finished(d) or d.get("status") != "open" or labels & HELD:
            continue
        blockers = [b for b in d.get("dependencies") or [] if b.get("dependency_type") == "blocks"]
        # a blocker outside the run (a gate, an issue in another epic) is read from what the dependency row itself says
        open_blockers = [b["id"] for b in blockers
                         if not finished(issues.get(b["id"], b))]
        (waiting if open_blockers else ready).append((i, d, open_blockers))
    for i, d, _ in ready:
        tag = " [" + ",".join(sorted(set(d.get("labels") or []))) + "]" if d.get("labels") else ""
        print(f"{i}  {d.get('title', '')}{tag}")
    in_flight = [i for i, d in issues.items() if d.get("status") == "in_progress" and not finished(d)
                 and d.get("issue_type") != "epic" and "factory:run" not in (d.get("labels") or [])]
    print(f"\n  {len(ready)} ready, {len(in_flight)} in flight, {len(waiting)} waiting"
          + ("".join(f"\n  {i} waits on {', '.join(b)}" for i, _, b in waiting)), file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv[1:])
