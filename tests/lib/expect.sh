# Sourced by scenario expect scripts. Each check prints one line; `finish` sets the exit code.
FAILS=0
ok()   { printf '    ok    %s\n' "$1"; }
fail() { printf '    FAIL  %s\n' "$1"; FAILS=$((FAILS+1)); }
check() { # check "<what>" <command...>
  local what="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$what"; else fail "$what"; fi
}
report_has() { # report_has "<what>" <extended regex>   — against the agent's final report ($REPORT)
  if grep -Eqi -- "$2" "$REPORT"; then ok "$1"; else fail "$1 (report does not match /$2/)"; fi
}
report_lacks() {
  if grep -Eqi -- "$2" "$REPORT"; then fail "$1 (report matches /$2/)"; else ok "$1"; fi
}
finish() { [ "$FAILS" -eq 0 ]; }
