#!/bin/bash
# Tier 1: the koujou command line against real beads in a throwaway directory. No model.
. "$(dirname "$0")/../lib/expect.sh"; . "$(dirname "$0")/../lib/todo.sh"
command -v bd >/dev/null 2>&1 || { echo "  skip  bd (beads) is not installed"; exit 0; }
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

echo "  koujou init / doctor"
mkdir "$WORK/new" && cd "$WORK/new" && git init -q -b main
koujou init >/dev/null 2>&1
check "init creates .beads, FACTORY.md, AGENTS.md, CLAUDE.md" test -d .beads -a -f FACTORY.md -a -f AGENTS.md -a -f CLAUDE.md
check "AGENTS.md has exactly one factory block" test "$(grep -c 'BEGIN SOFTWARE FACTORY' AGENTS.md)" = 1
check "CLAUDE.md imports AGENTS.md" grep -qx '@AGENTS.md' CLAUDE.md
check "init leaves the factory's own files uncommitted" bash -c 'git status --porcelain | grep -q "FACTORY.md" && git status --porcelain | grep -q "AGENTS.md"'
koujou init >/dev/null 2>&1
check "init twice leaves one block and one import" test "$(grep -c 'BEGIN SOFTWARE FACTORY' AGENTS.md)$(grep -cx '@AGENTS.md' CLAUDE.md)" = 11
check "doctor fails while FACTORY.md is still the template" bash -c '! "$0" doctor' "$TESTS_DIR/../bin/koujou"
check "doctor says what to run" bash -c '"$0" doctor 2>&1 | grep -q "/factory-setup"' "$TESTS_DIR/../bin/koujou"
echo "kept" > "$WORK/keep" && mkdir "$WORK/has" && cd "$WORK/has" && git init -q -b main && printf '# Mine\n\nmy rules\n' > CLAUDE.md && printf '# Mine\n' > FACTORY.md
koujou init >/dev/null 2>&1
check "init keeps an existing FACTORY.md" test "$(cat FACTORY.md)" = "# Mine"
check "init keeps existing CLAUDE.md rules" grep -q 'my rules' CLAUDE.md

cd "$TESTS_DIR/fixtures/todo"
check "doctor accepts a current profile" bash -c '"$0" doctor 2>&1 | grep -q "ok    FACTORY.md"' "$TESTS_DIR/../bin/koujou"
mkdir "$WORK/old" && cd "$WORK/old" && git init -q -b main && koujou init >/dev/null 2>&1
grep -v -e '^## Security review' -e 'max_rebases' "$TESTS_DIR/fixtures/todo/FACTORY.md" > FACTORY.md
check "doctor flags a profile from an older factory, naming what is missing" bash -c '"$0" doctor 2>&1 | grep -q "predates.*Security review.*max_rebases"' "$TESTS_DIR/../bin/koujou"

grep -v -e '^## Test map' "$TESTS_DIR/fixtures/todo/FACTORY.md" > FACTORY.md
check "doctor flags a profile with no Test map" bash -c '"$0" doctor 2>&1 | grep -q "predates.*Test map"' "$TESTS_DIR/../bin/koujou"

echo "  koujou awake"
export KOUJOU_STATE="$WORK/state"
mkdir -p "$WORK/fakebin"; printf '#!/bin/bash\nexec sleep 300\n' > "$WORK/fakebin/caffeinate"; chmod +x "$WORK/fakebin/caffeinate"
check "awake start keeps the machine awake and records the pid" bash -c 'PATH="$0:$PATH" koujou awake start | grep -q "keeping this machine awake" && kill -0 "$(cat "$KOUJOU_STATE/awake.pid")"' "$WORK/fakebin"
check "awake start twice does not start a second keeper" bash -c 'PATH="$0:$PATH" koujou awake start | grep -q "already"' "$WORK/fakebin"
check "awake status reports it" bash -c 'koujou awake status | grep -q "awake (pid"'
check "awake stop ends it" bash -c 'p=$(cat "$KOUJOU_STATE/awake.pid"); koujou awake stop | grep -q "stopped" && sleep 0.2 && ! kill -0 "$p" 2>/dev/null && test ! -e "$KOUJOU_STATE/awake.pid"'
unset KOUJOU_STATE

echo "  koujou accept"
todo_repo "$WORK/a" >/dev/null || fail "fixture repo"
good=$(new_task "passes" "d" "- x — test: unit" "Lane: test/")
empty=$(new_task "selects nothing" "d" "- x — test: unit" "Lane: test/")
red=$(new_task "fails" "d" "- x — test: unit" "Lane: test/")
none=$(new_task "has no command" "d" "- x — test: unit" "Lane: test/")
cat > test/accept.test.js <<JS
import test from 'node:test';
import assert from 'node:assert/strict';
test('$good: holds', () => assert.equal(1, 1));
test('$red: does not hold', () => assert.equal(1, 2));
JS
for t in $good $empty $red; do bd update $t --set-metadata accept="node --test --test-name-pattern \"$t\"" >/dev/null; done
check "a passing acceptance command passes" koujou accept $good
check "a failing one fails" bash -c '! "$0" accept "$1"' "$TESTS_DIR/../bin/koujou" $red
check "a command that selects no tests fails" bash -c '! "$0" accept "$1"' "$TESTS_DIR/../bin/koujou" $empty
check "…and says why" bash -c '"$0" accept "$1" | grep -q "no test named"' "$TESTS_DIR/../bin/koujou" $empty
quiet=$(new_task "prints only where it ran" "d" "- x — test: unit" "Lane: test/")
bd update $quiet --set-metadata accept="pwd" >/dev/null
mkdir -p "wt/$quiet"
check "the id in the worktree's path is not a test name" bash -c 'cd "wt/$1" && ! "$0" accept "$1"' "$TESTS_DIR/../bin/koujou" $quiet
check "a task without a command fails the run" bash -c '! "$0" accept "$1"' "$TESTS_DIR/../bin/koujou" $none
check "an unknown id is an error" bash -c '! "$0" accept td-nope' "$TESTS_DIR/../bin/koujou"

echo "  koujou accept from a second repository (code and tracker apart)"
# The second real project keeps beads in a workspace repository and the code in another git repository checked out
# inside it: from a code worktree bd finds no database unless BEADS_DIR says where it is.
TRACKER="$PWD"; mkdir -p "$WORK/code/test" && (cd "$WORK/code" && git init -q -b main && cp "$TRACKER/test/accept.test.js" test/ && printf '{"type":"module"}' > package.json)
check "without BEADS_DIR the code repository cannot see the task" bash -c 'cd "$1" && ! "$0" accept "$2" 2>/dev/null' "$TESTS_DIR/../bin/koujou" "$WORK/code" $good
check "with BEADS_DIR the task's tests run where the code is" bash -c 'cd "$1" && BEADS_DIR="$3/.beads" "$0" accept "$2"' "$TESTS_DIR/../bin/koujou" "$WORK/code" $good "$TRACKER"

echo "  koujou ready"
repic=$(bd create "a run that closes on merge" -t epic -d "x

## Success Criteria
- y" --silent)
ra=$(bd create "first" -t task --parent $repic -d d --acceptance "- x" --silent)
rb=$(bd create "second, needs first" -t task --parent $repic -d d --acceptance "- x" --silent)
rc=$(bd create "third, needs second" -t task --parent $repic -d d --acceptance "- x" --silent)
rd=$(bd create "for later" -t task --parent $repic -l factory:deferred -d d --acceptance "- x" --silent)
bd dep add $rb $ra >/dev/null; bd dep add $rc $rb >/dev/null
K="$TESTS_DIR/../bin/koujou"
check "at the start only the task with no dependency is ready" bash -c 'test "$("$0" ready "$1" 2>/dev/null | grep -c .)" = 1 && "$0" ready "$1" 2>/dev/null | grep -q "^$2 "' "$K" $repic $ra
bd update $ra --claim >/dev/null
check "a claimed task is in flight, and nothing is ready behind it" bash -c 'test -z "$("$0" ready "$1" 2>/dev/null)" && "$0" ready "$1" 2>&1 | grep -q "0 ready, 1 in flight, 2 waiting"' "$K" $repic
bd update $ra --add-label factory:awaiting-merge >/dev/null
check "landed and awaiting merge counts as done: its dependent is ready" bash -c '"$0" ready "$1" 2>/dev/null | grep -q "^$2 "' "$K" $repic $rb
check "…where bd ready alone still shows nothing" bash -c '! bd ready --parent "$1" --exclude-type epic --json | grep -q "$2"' _ $repic $rb
check "the task two steps behind still waits, and says on what" bash -c '"$0" ready "$1" 2>&1 | grep -q "$2 waits on $3"' "$K" $repic $rc $rb
check "a deferred task is never offered" bash -c '! "$0" ready "$1" 2>/dev/null | grep -q "^$2 "' "$K" $repic $rd
old() { python3 -c "from datetime import datetime, timedelta, timezone; import sys; print((datetime.now(timezone.utc)-timedelta(seconds=int(sys.argv[1]))).strftime('%Y-%m-%dT%H:%M:%SZ'))" "$1"; }
bd update $ra --set-metadata claimed_at=$(old 4000) --set-metadata built_at=$(old 3880) >/dev/null   # a 2 minute build, long ago
bd update $rb --claim --set-metadata claimed_at=$(old 120) >/dev/null
check "a task building for two minutes is in flight and not flagged" bash -c '"$0" ready "$1" 2>&1 | grep "$2 building" | grep -vq QUIET' "$K" $repic $rb
bd update $rb --set-metadata claimed_at=$(old 2700) >/dev/null
check "a task building far longer than any build so far is flagged quiet" bash -c '"$0" ready "$1" 2>&1 | grep "$2 building for 45m" | grep -q "QUIET"' "$K" $repic $rb
bd close $rb --reason done --force >/dev/null 2>&1
check "a closed dependency frees its dependent too" bash -c '"$0" ready "$1" 2>/dev/null | grep -q "^$2 "' "$K" $repic $rc

echo "  koujou times"
epic=$(bd create "an epic" -t epic -d "x

## Success Criteria
- y" --silent)
t1=$(bd create "timed task" -t task --parent $epic -d d --acceptance "- x" --silent)
bd update $epic --claim >/dev/null; bd update $t1 --claim >/dev/null
start=$(bd show $t1 --json | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["started_at"])')
plus() { python3 -c "from datetime import datetime, timedelta; import sys; print((datetime.fromisoformat(sys.argv[1].replace('Z','+00:00'))+timedelta(seconds=int(sys.argv[2]))).strftime('%Y-%m-%dT%H:%M:%SZ'))" "$start" "$1"; }
bd update $t1 --set-metadata built_at=$(plus 90) --set-metadata reviewed_at=$(plus 150) --set-metadata merged_at=$(plus 160) --set-metadata agent_runs=3 --set-metadata fix_attempts=1 >/dev/null
out=$(koujou times $epic)
check "times shows build, review and queue durations" bash -c 'echo "$0" | grep -Eq "1m30s +1m00s +10s +2m40s +1 +0 +3"' "$out"
bd update $t1 --set-metadata claimed_at=$(plus 60) >/dev/null
check "times prefers the run's own claim stamp over an older claim" bash -c '"$0" times "$1" | grep -Eq "30s +1m00s +10s +1m40s"' "$TESTS_DIR/../bin/koujou" $epic
check "times totals the agents" bash -c 'echo "$0" | grep -q "agents spawned: 3"' "$out"
check "spawned adds one to a task's count" bash -c '"$0" spawned "$1" | grep -q "$1: 4 agent runs"' "$TESTS_DIR/../bin/koujou" $t1
koujou spawned $epic >/dev/null; koujou spawned $epic >/dev/null
check "spawned on the epic counts agents no task owns, and times adds them" bash -c '"$0" times "$1" | grep -q "agents spawned: 6 (4 on tasks, 2 for the run"' "$TESTS_DIR/../bin/koujou" $epic
check "spawned on an unknown id is an error" bash -c '! "$0" spawned td-nope 2>/dev/null' "$TESTS_DIR/../bin/koujou"
echo "  koujou budget"
check "a run inside its budget says so" bash -c '"$0" budget "$1" | grep -q "^within budget: 6 of 10 agents"' "$TESTS_DIR/../bin/koujou" $epic
check "spawned reports the run's budget after counting" bash -c '"$0" spawned "$1" | grep -q "^within budget: 7 of 10 agents"' "$TESTS_DIR/../bin/koujou" $t1
bd update $epic --set-metadata agent_budget=5 >/dev/null
check "over the agent budget, budget exits 1 and says what to do" bash -c '! "$0" budget "$1" >/dev/null && "$0" budget "$1" | grep -q "^OVER BUDGET: 7 agents, budget 5.*ask whether to go on"' "$TESTS_DIR/../bin/koujou" $epic
check "over the budget, spawned still counts but exits 3" bash -c '"$0" spawned "$1" >/dev/null; [ $? = 3 ] && bd show "$1" --json | grep -q "\"agent_runs\": *6"' "$TESTS_DIR/../bin/koujou" $t1
bd update $epic --set-metadata agent_budget=100 --set-metadata time_budget_h=4 --set-metadata claimed_at=$(python3 -c "from datetime import datetime, timedelta, timezone; print((datetime.now(timezone.utc)-timedelta(hours=5)).strftime('%Y-%m-%dT%H:%M:%SZ'))") >/dev/null
check "over the time budget is over too" bash -c '"$0" budget "$1" | grep -q "^OVER BUDGET: 5.0h working, budget 4h"' "$TESTS_DIR/../bin/koujou" $epic
bd update $epic --set-metadata waited_s=7200 >/dev/null
check "time spent waiting on the user does not count" bash -c '"$0" budget "$1" | grep -q "^within budget: .*3.0h of 4h"' "$TESTS_DIR/../bin/koujou" $epic
bd update $epic --set-metadata time_budget_h=100 --set-metadata waited_s=0 >/dev/null
koujou wait $epic start >/dev/null
check "wait start stamps waiting_since" bash -c 'bd show "$0" --json | grep -q waiting_since' $epic
check "a second start keeps the first stamp" bash -c '"$0" wait "$1" start | grep -q "already waiting"' "$TESTS_DIR/../bin/koujou" $epic
bd update $epic --set-metadata waiting_since=$(python3 -c "from datetime import datetime, timedelta, timezone; print((datetime.now(timezone.utc)-timedelta(seconds=7200)).strftime('%Y-%m-%dT%H:%M:%SZ'))") >/dev/null
check "times counts a wait that is still open" bash -c '"$0" times "$1" | grep -Eq "waiting on the user: 2h0[0-9]m"' "$TESTS_DIR/../bin/koujou" $epic
koujou wait $epic end >/dev/null
check "wait end clears the stamp and keeps the total" bash -c 'bd show "$0" --json | python3 -c "import json,sys; m=json.load(sys.stdin)[0][\"metadata\"]; sys.exit(0 if \"waiting_since\" not in m and int(m[\"waited_s\"])>=7200 else 1)"' $epic
check "times reports the finished wait" bash -c '"$0" times "$1" | grep -Eq "waiting on the user: 2h0[0-9]m"' "$TESTS_DIR/../bin/koujou" $epic
check "wait end when not waiting says so" bash -c '"$0" wait "$1" end | grep -q "was not waiting"' "$TESTS_DIR/../bin/koujou" $epic
check "wait on an unknown id is an error" bash -c '! "$0" wait td-nope start' "$TESTS_DIR/../bin/koujou"
check "times on an unknown id is an error" bash -c '! "$0" times td-nope' "$TESTS_DIR/../bin/koujou"

echo "  koujou converge"
K="$TESTS_DIR/../bin/koujou"
bug() { bd create "$1" -t bug --parent $epic -d d --acceptance "- x" --silent; }
b1=$(bug "bug one"); b2=$(bug "bug two"); b3=$(bug "bug three")
check "round 1 with three bugs goes on" bash -c '"$0" converge "$1" --record | grep -q "^continue: 3 open"' "$K" $epic
bd close $b1 --reason fixed >/dev/null; bd close $b2 --reason fixed >/dev/null
check "a round that closes bugs goes on, however many rounds" bash -c '"$0" converge "$1" --record | grep -q "after each round: 3, 1"' "$K" $epic
check "without --record nothing is written" bash -c '"$0" converge "$1" >/dev/null; "$0" converge "$1" | grep -q "after each round: 3, 1;"' "$K" $epic
check "a deferred bug is not counted" bash -c 'x=$(bd create "later" -t bug --parent "$1" -l factory:deferred -d d --acceptance "- x" --silent); "$0" converge "$1" | grep -q "^continue: 1 open"' "$K" $epic
check "a landed bug waiting for the merge is not counted" bash -c 'x=$(bd create "landed" -t bug --parent "$1" -l factory:awaiting-merge -d d --acceptance "- x" --silent); bd update $x --claim >/dev/null; "$0" converge "$1" | grep -q "^continue: 1 open"' "$K" $epic
"$K" converge $epic --record >/dev/null
check "two rounds without the number falling stops the loop" bash -c '! "$0" converge "$1" --record' "$K" $epic
check "…and says what the numbers were" bash -c '"$0" converge "$1" | grep -q "stop: no progress.*3, 1, 1, 1"' "$K" $epic
bd update $epic --set-metadata round_open=3 >/dev/null
bd update $b3 --set-metadata reopened=2 >/dev/null
b4=$(bug "bug four")
check "a bug whose fix failed twice is stuck; the rest go on" bash -c 'o=$("$0" converge "$1"); echo "$o" | grep -q "^stuck $2: its fix has failed validation twice" && echo "$o" | grep -q "^continue: 1 open"' "$K" $epic $b3
bd close $b4 --reason fixed >/dev/null
check "when every open bug is stuck the loop stops" bash -c '! "$0" converge "$1" >/dev/null && "$0" converge "$1" | grep -q "stop: every open bug is stuck"' "$K" $epic
bd update $b3 --set-metadata reopened=0 >/dev/null
c1=$(bug "under 1"); c2=$(bug "under 2"); c3=$(bug "under 3")
bd dep add $b3 $c1 >/dev/null; bd dep add $c1 $c2 >/dev/null
check "a chain three deep is allowed" bash -c 'o=$("$0" converge "$1"); echo "$o" | grep -q "^continue: 4 open" && ! echo "$o" | grep -q "^stuck"' "$K" $epic
bd dep add $c2 $c3 >/dev/null
check "a chain four deep marks its top stuck" bash -c '"$0" converge "$1" | grep -q "^stuck $2: fixing it has uncovered a chain of 4"' "$K" $epic $b3
bd close $c3 --reason fixed >/dev/null
check "…and it is unstuck when the bottom closes" bash -c '! "$0" converge "$1" | grep -q "^stuck"' "$K" $epic
printf -- '- `max_agent_runs`: 2\n' >> FACTORY.md
bd update $epic --set-metadata agent_budget=0 >/dev/null
check "over the agent budget stops the loop" bash -c '! "$0" converge "$1" >/dev/null && "$0" converge "$1" | grep -Eq "stop: budget: [0-9]+ agent runs so far, limit 2"' "$K" $epic
bd update $epic --set-metadata agent_budget=50 >/dev/null
check "the user's raise on the epic beats the profile's limit" bash -c '"$0" budget "$1" | grep -Eq "^within budget: [0-9]+ of 50 agents"' "$K" $epic
check "…in converge too" bash -c '"$0" converge "$1" | grep -Eq "of 50 agent runs used"' "$K" $epic
check "budget reads FACTORY.md from the repository root, wherever it runs" bash -c 'mkdir -p sub && cd sub && bd update "$1" --set-metadata agent_budget=0 >/dev/null && "$0" budget "$1" | grep -Eq "^OVER BUDGET: [0-9]+ agents, budget 2"' "$K" $epic
bd update $epic --set-metadata time_budget_h=0.5 >/dev/null
check "a fractional time budget is kept" bash -c '"$0" budget "$1" | grep -q "budget 0.5h\|of 0.5h"' "$K" $epic
check "converge on an unknown id is an error" bash -c '! "$0" converge td-nope' "$K"

finish
