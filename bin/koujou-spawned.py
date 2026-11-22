#!/usr/bin/env python3
"""koujou spawned <id>... [bd flags, e.g. --sandbox]
Count one agent run against each id: a task, or the epic (or a pass's run record) for agents that belong to no single
task: scouts, security lenses, the validator. Adds one to the issue's `agent_runs`, so nobody keeps the number in
their head; `koujou times` and the budget in `koujou converge` read it."""
import json
import subprocess
import sys


def main(args):
    ids = [a for a in args if not a.startswith("-")]
    flags = [a for a in args if a.startswith("-")]
    if not ids:
        sys.exit("usage: koujou spawned <id>... [bd flags, e.g. --sandbox]")
    for i in ids:
        out = subprocess.run(["bd", "show", i, "--json", "--readonly"], capture_output=True, text=True)
        shown = json.loads(out.stdout or "[]") if out.returncode == 0 else []
        if not shown:
            sys.exit(f"no issue {i}")
        try:
            n = int((shown[0].get("metadata") or {}).get("agent_runs") or 0) + 1
        except (TypeError, ValueError):
            n = 1
        done = subprocess.run(["bd", "update", i, "--set-metadata", f"agent_runs={n}", *flags], capture_output=True, text=True)
        if done.returncode != 0:
            sys.exit(done.stderr.strip() or "bd update failed")
        print(f"{i}: {n} agent run{'s' if n != 1 else ''}")


if __name__ == "__main__":
    main(sys.argv[1:])
