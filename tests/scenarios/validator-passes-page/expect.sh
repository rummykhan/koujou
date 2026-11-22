#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"
report_has "verdict is pass" '^verdict:[[:space:]]*pass'
report_has "it used a browser, not only curl" 'browser|playwright|chromium|screenshot|click|tick(ed)? the box'
report_has "it checked what the page showed against the API, or by opening the page again" 'behind:[[:space:]]*matches|reload|re-?open|GET /todos'
report_lacks "no blocker or major bug is reported on a correct build" 'severity:[[:space:]]*(blocker|major)'
check "validator changed nothing in the checkout" test -z "$(git -C "$WORK/todo" status --porcelain)"
check "evidence was saved" bash -c "ls '$WORK/evidence' | grep -q ."
check "validator left no server running on its port" bash -c "! lsof -nP -iTCP:$(cat "$WORK/port") -sTCP:LISTEN"
finish
