#!/bin/bash
. "$(dirname "$0")/../../lib/todo.sh"
todo_repo "$1" || exit 1
git rev-parse HEAD > "$1/base-sha"
