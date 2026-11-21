#!/bin/bash
. "$(dirname "$0")/../../lib/todo.sh"; . "$(dirname "$0")/../../lib/search_bug.sh"
search_bug "$1" search-store-bug || exit 1
test "$(search_status "$1/wt")" = 500 || { echo "fixture does not reproduce the bug" >&2; exit 1; }
