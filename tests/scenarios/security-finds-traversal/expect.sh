#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"
report_has "verdict is fail" '^verdict:[[:space:]]*fail'
report_has "finding is the path traversal" 'travers|\.\./|outside (the )?export|arbitrary file'
report_has "rated critical or high, and introduced" 'severity:[[:space:]]*(critical|high)'
report_has "origin is introduced" 'origin:[[:space:]]*introduced'
report_has "proof was observed, not only reasoned" 'proof:[[:space:]]*observed'
check "the high finding has a plain account for the owner, free of file names" python3 - "$REPORT" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
m = re.search(r"^\s*plain:\s*(.+?)(?=^\s*(?:proof|fix|where|attack|origin|severity|- id|not_covered):)", text, re.S | re.M)
sys.exit(0 if m and len(m.group(1).split()) >= 12 and not re.search(r"\b[\w/-]+\.(js|ts|json|md):?\d*", m.group(1).replace("package.json", "")) else 1)
PY
check "agent changed nothing in the worktree" test -z "$(git -C "$WORK/wt" status --porcelain)"
check "agent left no server running on its port" bash -c "! lsof -nP -iTCP:$(cat "$WORK/port") -sTCP:LISTEN"
finish
