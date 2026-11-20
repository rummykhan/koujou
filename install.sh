#!/usr/bin/env bash
# Software Factory installer.
#
#   curl -fsSL https://raw.githubusercontent.com/rummykhan/software-factory/main/install.sh | bash
#   or, from a clone:  ./install.sh
#
# What it does:
#   1. installs beads (bd) if it is missing
#   2. puts the factory in ~/.software-factory (clone, or update if already there) unless run from a clone
#   3. links its skills and agents into ~/.claude, and the `factory` command into ~/.local/bin
# Safe to re-run. Remove with:  factory uninstall
set -euo pipefail

REPO="${FACTORY_REPO:-https://github.com/rummykhan/software-factory.git}"
HOME_DIR="${FACTORY_HOME:-$HOME/.software-factory}"

say() { printf '%s\n' "$*"; }

# 1. beads
if command -v bd >/dev/null 2>&1; then
  say "beads    $(bd version 2>/dev/null | head -1)"
elif command -v brew >/dev/null 2>&1; then
  say "beads    installing with Homebrew"; brew install beads
elif command -v npm >/dev/null 2>&1; then
  say "beads    installing with npm"; npm install -g @beads/bd
else
  say "beads    installing with the beads install script"
  curl -fsSL https://raw.githubusercontent.com/gastownhall/beads/main/scripts/install.sh | bash
fi

# 2. locate or fetch the factory
SELF="${BASH_SOURCE[0]:-}"
if [[ -n "$SELF" && -d "$(cd "$(dirname "$SELF")" 2>/dev/null && pwd)/skills/factory" ]]; then
  SRC="$(cd "$(dirname "$SELF")" && pwd)"            # running from a clone
  say "factory  using this checkout: $SRC"
else
  command -v git >/dev/null 2>&1 || { say "git is required"; exit 1; }
  if [[ -d "$HOME_DIR/.git" ]]; then
    say "factory  updating $HOME_DIR"; git -C "$HOME_DIR" pull --ff-only --quiet
  else
    say "factory  cloning into $HOME_DIR"
    git clone --quiet "$REPO" "$HOME_DIR" 2>/dev/null \
      || { command -v gh >/dev/null 2>&1 && gh repo clone "${REPO#https://github.com/}" "$HOME_DIR" -- --quiet; } \
      || { say "could not clone $REPO (private repo? run: gh auth login)"; exit 1; }
  fi
  SRC="$HOME_DIR"
fi

# 3. link
exec "$SRC/bin/factory" link
