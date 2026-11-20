# Sourced by scenario setup scripts. Builds a fresh copy of the todo fixture as a git repository with beads.
#   todo_repo <work-dir>     creates <work-dir>/todo, committed on main, with a beads database (prefix td)
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

todo_repo() {
  local work="$1" repo="$1/todo"
  mkdir -p "$work" && cp -R "$TESTS_DIR/fixtures/todo" "$repo"
  cd "$repo" || return 1
  git init -q -b main
  git config user.name "koujou test" && git config user.email "test@koujou.invalid"
  bd init --non-interactive --prefix td >/dev/null 2>&1 || { echo "bd init failed" >&2; return 1; }
  # bd init writes its own AGENTS.md/CLAUDE.md blocks; the fixture's versions are the ones under test
  cp "$TESTS_DIR/fixtures/todo/AGENTS.md" "$TESTS_DIR/fixtures/todo/CLAUDE.md" .
  git add -A && git commit -q -m "chore: todo fixture" || return 1
}

# new_task <title> <description> <acceptance> <design> [labels]   prints the id; claims nothing
new_task() {
  bd create "$1" -t task -p 2 -d "$2" --acceptance "$3" --design "$4" ${5:+-l "$5"} --silent
}

# The koujou under test is this checkout's, whatever is installed on the machine.
koujou() { "$TESTS_DIR/../bin/koujou" "$@"; }
