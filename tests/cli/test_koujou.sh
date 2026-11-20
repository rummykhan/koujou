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
check "a task without a command fails the run" bash -c '! "$0" accept "$1"' "$TESTS_DIR/../bin/koujou" $none
check "an unknown id is an error" bash -c '! "$0" accept td-nope' "$TESTS_DIR/../bin/koujou"

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
check "times totals the agents" bash -c 'echo "$0" | grep -q "agents spawned: 3"' "$out"
check "times on an unknown id is an error" bash -c '! "$0" times td-nope' "$TESTS_DIR/../bin/koujou"

finish
