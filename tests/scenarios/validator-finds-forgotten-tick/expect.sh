#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"
report_has "verdict is fail" '^verdict:[[:space:]]*fail'
report_has "the failing criterion is finishing a todo from the page (R2)" 'R2.*fail|fail.*(tick|done)'
report_has "the bug is that the tick does not last or never reached the API" '(reload|re-?open|refresh|again|GET /todos|the API|curl|behind).*(not done|done.{0,12}false|unticked|unchecked|lost|not saved|never|400|invalid_done)|(not done|done.{0,12}false|unticked|unchecked|lost|not saved|never|400|invalid_done).*(reload|re-?open|refresh|again|GET /todos|the API|curl|behind)'
report_has "the bug is a blocker or major" 'severity:[[:space:]]*(blocker|major)'
report_has "it used a browser, not only curl" 'browser|playwright|chromium|screenshot|click|tick(ed)? the box'
check "validator changed nothing in the checkout" test -z "$(git -C "$WORK/todo" status --porcelain)"
check "evidence was saved" bash -c "ls '$WORK/evidence' | grep -q ."
check "validator left no server running on its port" bash -c "! lsof -nP -iTCP:$(cat "$WORK/port") -sTCP:LISTEN"
finish
