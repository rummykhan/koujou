#!/bin/bash
# Prints a TCP port nobody is listening on, starting from $1 (default 3400). Scenario runners use this, never a guess:
# a guessed port once pointed a security agent at a local MySQL.
p="${1:-3400}"
while lsof -nP -iTCP:"$p" -sTCP:LISTEN >/dev/null 2>&1; do p=$((p+1)); done
echo "$p"
