#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"
report_has "verdict is pass" '^verdict:[[:space:]]*pass'
check "no introduced critical or high finding" python3 - "$REPORT" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
for block in re.split(r"\n\s*- id:", text)[1:]:
    if re.search(r"severity:\s*(critical|high)", block) and re.search(r"origin:\s*introduced", block):
        sys.exit(1)
PY
check "agent changed nothing in the worktree" test -z "$(git -C "$WORK/wt" status --porcelain)"
check "agent left no server running on its port" bash -c "! lsof -nP -iTCP:$(cat "$WORK/port") -sTCP:LISTEN"
finish
