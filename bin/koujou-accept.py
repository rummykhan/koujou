#!/usr/bin/env python3
"""koujou accept <task-id>... | --parent <epic-id> | --label <label>
Run each task's acceptance command (beads metadata `accept`) in the current directory and report pass or fail."""
import json
import re
import subprocess
import sys
import time

# What common runners print when a filter matches nothing (node:test, pytest, jest, vitest, go test, playwright).
EMPTY = re.compile(r"^# tests 0\s*$|no tests ran|No tests found|no test files|no tests to run|^Tests:\s+0 total", re.M | re.I)


def bd(*a):
    out = subprocess.run(["bd", *a, "--json", "--readonly"], capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(out.stderr.strip() or "bd failed")
    return json.loads(out.stdout or "[]")


def main(args):
    if not args or (args[0] in ("--parent", "--label") and len(args) < 2):
        sys.exit("usage: koujou accept <task-id>... | --parent <epic-id> | --label <label>")
    if args[0] in ("--parent", "--label"):
        ids = [i["id"] for i in bd("list", args[0], args[1], "--all", "--limit", "0")]
    else:
        ids = args
    failed, missing, ran = [], [], 0
    for i in ids:
        shown = bd("show", i)
        if not shown:
            sys.exit(f"no issue {i}")
        d = shown[0]
        if d.get("issue_type") == "epic" or "factory:run" in (d.get("labels") or []):
            continue
        cmd = (d.get("metadata") or {}).get("accept")
        if not cmd:
            missing.append(i)
            print(f"  none  {i}  no acceptance command recorded — {d.get('title', '')[:60]}")
            continue
        t = time.time()
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        ran += 1
        secs = time.time() - t
        out = r.stdout + r.stderr
        # The id must come from a test's name. A worktree is usually named after its task, and runners print the
        # directory they run in and sometimes the command itself, so neither may count as the mention.
        names = out.replace(cmd, "")
        mentioned = re.search(r"(?<![\w/.-])" + re.escape(i), names)   # not as a path segment
        if r.returncode == 0 and (EMPTY.search(out) or not mentioned):
            # A filter that matches nothing "passes" in most runners, and that proves nothing. Tests are named
            # with the task id, so a run that never prints the id ran none of this task's tests.
            failed.append(i)
            print(f"  FAIL  {i}  {secs:.1f}s  {cmd}\n        no test named with '{i}' ran (the output never mentions it)")
        elif r.returncode == 0:
            print(f"  pass  {i}  {secs:.1f}s  {cmd}")
        else:
            failed.append(i)
            print(f"  FAIL  {i}  {secs:.1f}s  {cmd}")
            print("\n".join("        " + line for line in out.strip().splitlines()[-15:]))
    print(f"\n  {ran - len(failed)} passed, {len(failed)} failed, {len(missing)} without an acceptance command")
    sys.exit(1 if failed or missing else 0)


if __name__ == "__main__":
    main(sys.argv[1:])
