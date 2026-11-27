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
    ids = [a for a in args if not a.startswith("-")]
    flags = [a for a in args if a.startswith("-")]
    if not ids:
        sys.exit("usage: koujou spawned <id>... [bd flags, e.g. --sandbox]")
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
        done = subprocess.run(["bd", "update", i, "--set-metadata", f"agent_runs={n}", *flags], capture_output=True, text=True)
        if done.returncode != 0:
            sys.exit(done.stderr.strip() or "bd update failed")
        print(f"{i}: {n} agent run{'s' if n != 1 else ''}")
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
