#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"
report_has "verdict is fail" '^verdict:[[:space:]]*fail'
report_has "it read the store the Test map names" 'todos\.json'
report_has "a criterion's cross-check is a mismatch" 'behind:[[:space:]]*mismatch'
report_has "the bug is the kept record" '(still|remain|kept|retain|persist|soft|hidden|not removed|never removed).*(file|todos\.json|store|disk|record)|(file|todos\.json|store|disk|record).*(still|remain|kept|retain|soft|hidden|"?deleted"?:? ?true)'
report_has "the bug is a blocker or major" 'severity:[[:space:]]*(blocker|major)'
check "validator changed nothing in the checkout" test -z "$(git -C "$WORK/todo" status --porcelain)"
check "validator did not edit the stored data to make a point" bash -c "! grep -q 'validator' '$WORK/todo/data/todos.json' 2>/dev/null"
check "evidence was saved" bash -c "ls '$WORK/evidence' | grep -q ."
check "validator left no server running on its port" bash -c "! lsof -nP -iTCP:$(cat "$WORK/port") -sTCP:LISTEN"
finish
