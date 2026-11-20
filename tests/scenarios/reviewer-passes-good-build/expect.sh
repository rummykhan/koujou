#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"
report_has "verdict is pass" '^verdict:[[:space:]]*pass'
report_lacks "no criterion left unmet or unproven" '":[[:space:]]*(unmet|unproven)'
check "reviewer changed nothing in the worktree" test -z "$(git -C "$WORK/wt" status --porcelain)"
finish
