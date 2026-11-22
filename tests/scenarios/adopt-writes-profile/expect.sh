#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"
cd "$WORK/todo" || exit 2
sec() { awk -v h="$1" '$0 ~ "^## "h{f=1;next} /^## /{f=0} f' FACTORY.md; }
check "FACTORY.md was written and is not the template" bash -c "test -f FACTORY.md && ! grep -q '<One paragraph' FACTORY.md"
check "it has every section later stages read" bash -c "for s in 'Test map' 'QA' 'Security review' 'Baseline' 'Git policy' 'Limits'; do grep -q \"^## \$s\" FACTORY.md || exit 1; done; grep -q '^- Merge:' FACTORY.md && grep -q 'max_rebases' FACTORY.md"
check "the gate is the project's own command" bash -c "grep -q 'npm run gate' FACTORY.md"
check "the baseline records a gate that was run and was green" bash -c "awk '/^## Baseline/{f=1;next} /^## /{f=0} f' FACTORY.md | grep -Eqi 'green|pass'"
check "the Test map says where the todos live: the file" bash -c "awk '/^## Test map/{f=1;next} /^## /{f=0} f' FACTORY.md | grep -q 'todos.json'"
check "…and gives a way to read it back" bash -c "awk '/^## Test map/{f=1;next} /^## /{f=0} f' FACTORY.md | grep -Eqi 'cat |read|jq|TODO_DATA'"
check "the git policy says the factory merges locally, as the owner allowed" bash -c "awk '/^## Git policy/{f=1;next} /^## /{f=0} f' FACTORY.md | grep -Eqi 'local'"
check "open questions has a section" grep -q '^## Open questions' FACTORY.md
check "AGENTS.md has one factory block with a System design that is not the template" bash -c "test \"\$(grep -c 'BEGIN SOFTWARE FACTORY' AGENTS.md)\" = 1 && grep -q '## System design' AGENTS.md && ! grep -q '<Two or three sentences' AGENTS.md"
check "the System design knows the store is a file" bash -c "awk '/BEGIN SOFTWARE FACTORY/{f=1} f' AGENTS.md | grep -Eqi 'todos.json|data/'"
check "the owner's own rules are still in AGENTS.md" grep -q 'Never commit anything under' AGENTS.md
check "CLAUDE.md imports AGENTS.md" grep -qx '@AGENTS.md' CLAUDE.md
check "beads is initialised with the prefix the owner gave" bash -c "test -d .beads && bd create probe -t task -d d --acceptance '- x' --silent | grep -q '^td-'"
check "no product code or test was changed" bash -c "test -z \"\$(git status --porcelain -- src test package.json)\" && test -z \"\$(git diff --name-only $(cat "$WORK/base-sha") HEAD -- src test package.json)\""
check "no data file was left in the project by a trial run" test ! -e data/todos.json
check "no throwaway worktree is left" test "$(git worktree list | wc -l | tr -d ' ')" = 1
check "nothing is left listening on the port" bash -c "! lsof -nP -iTCP:$(cat "$WORK/port") -sTCP:LISTEN >/dev/null 2>&1"
report_has "the hand-over states the baseline result" 'green|pass'
finish
