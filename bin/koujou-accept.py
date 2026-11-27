#!/usr/bin/env python3
"""koujou accept <task-id>... | --parent <epic-id> | --label <label>
Run each task's acceptance command (beads metadata `accept`) in the current directory and report pass or fail.

koujou accept --red <task-id> --base <ref>
Prove the task's tests fail without its change: in the current worktree (clean), take the code back to <ref> while
keeping the branch's test files, run the acceptance command, then restore the branch. It must FAIL; a pass means the
tests do not test the change. This replaces the hollow-test check a per-task reviewer used to make."""
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


TESTISH = re.compile(r"(^|/)(tests?|__tests__|spec|e2e)/|[._-](test|spec)\.[a-z0-9]+$|_test\.[a-z]+$|(^|/)test_[^/]+$", re.I)


def git(*a, check=True):
    r = subprocess.run(["git", *a], capture_output=True, text=True)
    if check and r.returncode != 0:
        sys.exit(f"git {' '.join(a)}: {r.stderr.strip()}")
    return r.stdout


def red(args):
    if len(args) != 3 or args[1] != "--base":
        sys.exit("usage: koujou accept --red <task-id> --base <ref>")
    i, base = args[0], args[2]
    shown = bd("show", i)
    if not shown:
        sys.exit(f"no issue {i}")
    cmd = (shown[0].get("metadata") or {}).get("accept")
    if not cmd:
        sys.exit(f"{i}: no acceptance command recorded")
    if git("status", "--porcelain").strip():
        sys.exit("the worktree has uncommitted changes; commit or stash them first")
    fork = git("merge-base", "HEAD", base).strip()
    changed = [f for f in git("diff", "--name-only", f"{fork}..HEAD").splitlines() if f]
    code = [f for f in changed if not TESTISH.search(f)]
    if not code:
        sys.exit(f"{i}: the branch changes only test files; nothing to take back")
    try:
        # code files back to where the branch started; files the branch added are removed
        existed = set(git("ls-tree", "-r", "--name-only", fork, "--", *code).splitlines())
        if existed:
            git("checkout", fork, "--", *sorted(existed))
        for f in set(code) - existed:
            git("rm", "-q", "--cached", "--", f, check=False)
            try:
                __import__("os").remove(f)
            except OSError:
                pass
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    finally:
        git("reset", "-q", "--hard", "HEAD")
    out = (r.stdout + r.stderr).replace(cmd, "")
    if r.returncode != 0 and not re.search(r"(?<![\w/.-])" + re.escape(i), out):
        # a command that breaks before any test runs (a bad path, a missing tool) fails too, and proves nothing
        print(f"  FAIL  {i}  without the change no test named with '{i}' ran, so the check proves nothing:")
        print("\n".join("        " + line for line in out.strip().splitlines()[-10:]))
        sys.exit(1)
    if r.returncode == 0:
        print(f"  FAIL  {i}  its tests pass without the change ({len(code)} code file(s) taken back to {fork[:8]}): "
              "they do not test what the task changed")
        sys.exit(1)
    print(f"  red   {i}  its tests fail without the change, as they should ({len(code)} code file(s) taken back)")


def main(args):
    if args and args[0] == "--red":
        return red(args[1:])
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
