#!/bin/bash
WORK="$1"; REPORT="$2"; . "$(dirname "$0")/../../lib/expect.sh"; . "$(dirname "$0")/../../lib/todo.sh"
cd "$WORK/todo" || exit 2
q() { bd list "$@" --all --limit 0 --json --readonly; }
epic=$(q --type epic | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d[0]["id"] if len(d)==1 else "")')
check "plan.json was saved in the work order and is JSON with nodes" python3 -c "import json; assert json.load(open('docs/factory/tidy/plan.json'))['nodes']"
check "exactly one epic was created" test -n "$epic"
ids=$(q --parent "$epic" | python3 -c 'import json,sys; print(" ".join(i["id"] for i in json.load(sys.stdin)))')
bd show $ids --json --readonly > "$WORK/tasks.json" 2>/dev/null
py() { python3 -c "import json,re,sys; T=json.load(open('$WORK/tasks.json')); $1"; }
check "the epic has at least four tasks" py "sys.exit(0 if len(T) >= 4 else 1)"
check "the epic states success criteria" bash -c "bd show $epic --json --readonly | grep -q 'Success Criteria'"
check "bd lint is clean" bd lint
check "the swarm analysis says it can run" bash -c "bd swarm validate $epic 2>&1 | grep -q 'Swarmable: YES'"
check "one task is the QA task" py "sys.exit(0 if sum('qa' in (t.get('labels') or []) for t in T) == 1 else 1)"
check "every task has an acceptance command stored" py "sys.exit(0 if all((t.get('metadata') or {}).get('accept') for t in T) else 1)"
check "…and each fails now: nothing is built, so a command that passes selects nothing real" bash -c "out=\$(koujou accept --parent $epic 2>&1); echo \"\$out\" | grep -q ' 0 passed' && echo \"\$out\" | grep -q '0 without an acceptance command'"
check "every acceptance line of every feature task names how it is checked" py "
bad=[l for t in T if 'qa' not in (t.get('labels') or []) for l in (t.get('acceptance_criteria') or '').splitlines() if l.strip().startswith('- ') and not re.search(r'\b(test|run|manual):', l)]
sys.exit(1 if bad else 0)"
check "every task names its lane" py "sys.exit(0 if all(re.search(r'src/|test/', t.get('design') or '') for t in T) else 1)"
crit() { py "sys.exit(0 if any(re.search(r'$1', (t.get('acceptance_criteria') or ''), re.I) for t in T) else 1)"; }
check "design row covered: the total-count header" crit 'X-Total-Count'
check "design row covered: the line logged on each delete" crit 'stderr|deleted <id>|log(ged|s)? '
check "design row covered: the filter's error" crit 'invalid_done_filter'
check "design row covered: 405 on other methods" crit '405'
check "decision D2 kept: the PATCH and DELETE tasks are not in the same wave" py "
p=[t for t in T if re.search(r'PATCH', t['title']) and 'qa' not in (t.get('labels') or [])]; d=[t for t in T if re.search(r'DELETE|[Dd]elete', t['title']) and 'qa' not in (t.get('labels') or [])]
dep=lambda a,b: any(x.get('id')==b['id'] and x.get('dependency_type')=='blocks' for x in (a.get('dependencies') or []))
sys.exit(0 if p and d and (dep(p[0],d[0]) or dep(d[0],p[0])) else 1)"
check "no product code or test was touched, and nothing was claimed" bash -c "test -z \"\$(git status --porcelain -- src test package.json)\" && ! bd list --status in_progress --json --readonly | grep -q '\"id\"'"
report_has "the gate summary names the waves or what runs in parallel" 'wave|parallel'
finish
