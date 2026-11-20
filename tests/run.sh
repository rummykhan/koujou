#!/bin/bash
# The factory's deterministic tests: no model, a few seconds. Scenarios that need agents are run by /factory-test.
#   tests/run.sh            static + cli
#   tests/run.sh static     broken references, frontmatter, scripts parse, scenarios well formed
#   tests/run.sh cli        the koujou command against real beads in a temp directory
#   tests/run.sh setups     every scenario's setup.sh builds its fixture (catches a rotted scenario)
cd "$(dirname "$0")/.." || exit 2
rc=0
want="${1:-all}"
if [[ $want == all || $want == static ]]; then echo "static"; python3 tests/static/check.py || rc=1; fi
if [[ $want == all || $want == cli ]]; then echo "cli"; bash tests/cli/test_koujou.sh || rc=1; fi
if [[ $want == all || $want == setups ]]; then
  echo "scenario setups"
  if command -v bd >/dev/null 2>&1; then
    tmp="$(mktemp -d)"
    for s in tests/scenarios/*/; do
      n="$(basename "$s")"
      if bash "$s/setup.sh" "$tmp/$n" >/dev/null 2>"$tmp/$n.err"; then printf '    ok    %s\n' "$n"; else printf '    FAIL  %s\n' "$n"; tail -3 "$tmp/$n.err"; rc=1; fi
    done
    rm -rf "$tmp"
  else echo "  skip  bd (beads) is not installed"; fi
fi
[[ $rc == 0 ]] && echo "PASS" || echo "FAIL"
exit $rc
