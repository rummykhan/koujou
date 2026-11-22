#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"
cd "$WORK/todo" || exit 2
wo=$(ls -d docs/factory/*/ 2>/dev/null | head -1); req="${wo}requirements.md"
check "the raw request was saved as asked" grep -qi 'every morning' "${wo}raw.md"
check "requirements were written" test -f "$req"
check "…and left as a draft: nobody approved them for the user" grep -q '^status: draft' "$req"
check "at least two requirements, each with acceptance lines" bash -c "test \"\$(grep -c '^### R[0-9]' '$req')\" -ge 2 && test \"\$(grep -c '^Acceptance' '$req')\" -ge 2"
prereq() { awk '/^## Prerequisites/{f=1;next} /^## /{f=0} f' "$req"; }
check "sending email is listed as something only the user can provide" bash -c "awk '/^## Prerequisites/{f=1;next} /^## /{f=0} f' '$req' | grep -Eqi 'smtp|mail (service|provider)|email (service|provider|account|api)|sendgrid|ses|postmark|mailgun|api key|credential'"
check "…and so is receiving the replies" bash -c "awk '/^## Prerequisites/{f=1;next} /^## /{f=0} f' '$req' | grep -Eqi 'inbound|incoming|receiv|repl|webhook|imap|mailbox|mx|domain'"
check "no prerequisite is marked provided: nothing was handed over" bash -c "! awk '/^## Prerequisites/{f=1;next} /^## /{f=0} f' '$req' | grep -Eqi '\\| *provided *\\|'"
check "the time zone or the recipient is raised as a question or a stated assumption" grep -Eqi 'time ?zone|timezone|which address|recipient|whose' "$req"
report_has "the final message asks the user for something" '\?'
report_has "…and names the mail service among the asks" 'smtp|mail|email'
check "no product code or test was touched" bash -c "test -z \"\$(git status --porcelain -- src test package.json)\" && test -z \"\$(git diff --name-only $(cat "$WORK/base-sha") HEAD -- src test package.json)\""
check "nothing was planned: no epic and no task exists" test "$(bd list --all --limit 0 --json --readonly | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')" = 0
finish
