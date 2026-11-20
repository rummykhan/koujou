#!/bin/bash
. "$(dirname "$0")/../../lib/todo.sh"; . "$TESTS_DIR/lib/done_branch.sh"
done_branch "$1" done-weak
