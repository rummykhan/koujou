#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"
TESTS_DIR="$(cd "$(dirname "$0")/../.." && pwd)"; id="$(cat "$WORK/task")"; wt="$WORK/wt"
report_has "reports done" '^status:[[:space:]]*done'
report_has "lists coverage for both requirements" 'R1'
report_has "…and R2" 'R2'
check "committed on its own branch, worktree clean" bash -c "test -z \"\$(git -C '$wt' status --porcelain)\" && test \"\$(git -C '$wt' rev-list --count factory/epic..HEAD)\" -ge 1"
check "changed only files under test/acceptance/" bash -c "git -C '$wt' diff --name-only factory/epic HEAD | grep -q . && ! git -C '$wt' diff --name-only factory/epic HEAD | grep -qv '^test/acceptance/'"
check "wrote no bead state" bash -c "cd '$WORK/todo' && test \"\$(bd show $id --json --readonly | python3 -c 'import json,sys; print(json.load(sys.stdin)[0][\"status\"])')\" = in_progress"
run_named() { ( cd "$1" && node --test --test-name-pattern "$id" 2>&1 ); }
check "on the base its tests are selected and fail (the feature is absent)" bash -c "cd '$wt' && out=\$(node --test --test-name-pattern '$id' 2>&1); echo \"\$out\" | grep -q '$id' && ! echo \"\$out\" | grep -q '^# fail 0'"
# Build the feature twice in copies of the tester's branch: the outcome is what judges the tests.
rm -rf "$WORK/good" "$WORK/weak"
for v in good weak; do mkdir "$WORK/$v" && git -C "$wt" archive HEAD | tar -x -C "$WORK/$v" && ( cd "$WORK/$v" && python3 "$TESTS_DIR/fixtures/variants/make.py" "done-$v" td-built >/dev/null ); done
check "on a correct build every one of its tests passes" bash -c "cd '$WORK/good' && out=\$(node --test --test-name-pattern '$id' 2>&1); echo \"\$out\" | grep -q '^# fail 0' && ! echo \"\$out\" | grep -q '^# pass 0'"
check "on a build where done is always true and the body is not checked, its tests fail" bash -c "cd '$WORK/weak' && ! node --test --test-name-pattern '$id' >/dev/null 2>&1"
check "…for both planted defects: a test about not-done fails, and a test about invalid input fails" bash -c "cd '$WORK/weak' && test \"\$(node --test --test-name-pattern '$id' 2>&1 | grep -c '^not ok\|^    not ok\|^        not ok')\" -ge 2"
finish
