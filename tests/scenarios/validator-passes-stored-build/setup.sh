#!/bin/bash
. "$(dirname "$0")/../../lib/todo.sh"; . "$TESTS_DIR/lib/stored_delete.sh"
stored_delete "$1" delete-stored-good
