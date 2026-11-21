#!/usr/bin/env python3
"""koujou wait <epic-or-run-record-id> start|end [bd flags] — time a run spends stopped, waiting on the user.

start stamps `waiting_since`; end adds the elapsed seconds to `waited_s` and clears the stamp. `koujou times`
reports the total, so a run that sat overnight for an answer does not look like a run that worked overnight."""
import json
import subprocess
import sys
from datetime import datetime, timezone


def main(args):
    if len(args) < 2 or args[1] not in ("start", "end"):
        sys.exit("usage: koujou wait <id> start|end [bd flags, e.g. --sandbox]")
    issue, action, flags = args[0], args[1], args[2:]
    out = subprocess.run(["bd", "show", issue, "--json", "--readonly"], capture_output=True, text=True)
    try:
        meta = json.loads(out.stdout)[0].get("metadata") or {}
    except (ValueError, IndexError, KeyError):
        sys.exit(out.stderr.strip() or f"no issue {issue}")
    now = datetime.now(timezone.utc)
    since = meta.get("waiting_since")
    if action == "start":
        if since:
            print(f"{issue}: already waiting since {since}")
            return
        update = ["--set-metadata", f"waiting_since={now.strftime('%Y-%m-%dT%H:%M:%SZ')}"]
        said = "waiting on the user from now"
    else:
        if not since:
            print(f"{issue}: was not waiting")
            return
        try:
            waited = int(meta.get("waited_s") or 0)
        except (TypeError, ValueError):
            waited = 0
        waited += max(0, int((now - datetime.fromisoformat(str(since).replace("Z", "+00:00"))).total_seconds()))
        update = ["--set-metadata", f"waited_s={waited}", "--unset-metadata", "waiting_since"]
        said = f"wait over; {waited}s waited in total"
    done = subprocess.run(["bd", "update", issue, *update, *flags], capture_output=True, text=True)
    if done.returncode != 0:
        sys.exit(done.stderr.strip() or "bd update failed")
    print(f"{issue}: {said}")


if __name__ == "__main__":
    main(sys.argv[1:])
