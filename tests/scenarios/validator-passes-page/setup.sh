#!/bin/bash
. "$(dirname "$0")/../../lib/todo.sh"; . "$TESTS_DIR/lib/page_epic.sh"
page_epic "$1" page-good
