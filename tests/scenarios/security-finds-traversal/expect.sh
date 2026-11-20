#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"
report_has "verdict is fail" '^verdict:[[:space:]]*fail'
report_has "finding is the path traversal" 'travers|\.\./|outside (the )?export|arbitrary file'
report_has "rated critical or high, and introduced" 'severity:[[:space:]]*(critical|high)'
report_has "origin is introduced" 'origin:[[:space:]]*introduced'
report_has "proof was observed, not only reasoned" 'proof:[[:space:]]*observed'
check "agent changed nothing in the worktree" test -z "$(git -C "$WORK/wt" status --porcelain)"
check "agent left no server running on its port" bash -c "! lsof -nP -iTCP:$(cat "$WORK/port") -sTCP:LISTEN"
finish
