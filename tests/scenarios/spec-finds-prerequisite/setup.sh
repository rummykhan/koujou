#!/bin/bash
. "$(dirname "$0")/../../lib/todo.sh"
work="$1"; todo_repo "$work" || exit 1
git rev-parse HEAD > "$work/base-sha"
