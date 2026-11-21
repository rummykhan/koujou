#!/usr/bin/env bash
# Koujou (software factory) installer.
#
#   curl -fsSL https://raw.githubusercontent.com/rummykhan/koujou/main/install.sh | bash
#   or, from a clone:  ./install.sh
#
# What it does:
#   1. installs beads (bd) if it is missing
#   2. puts the factory in ~/.koujou (clone, or update if already there) unless run from a clone
#   3. links its skills and agents into ~/.claude, and the `factory` command into ~/.local/bin
# Safe to re-run. Remove with:  koujou uninstall
set -euo pipefail

REPO="${KOUJOU_REPO:-https://github.com/rummykhan/koujou.git}"
HOME_DIR="${KOUJOU_HOME:-$HOME/.koujou}"

say() { printf '%s\n' "$*"; }

# 1. beads — try each way of installing it until `bd` actually runs (a package manager can report success and
#    leave no working binary: the npm package's download step is skipped or fails on some machines)
bd_works() { hash -r 2>/dev/null; command -v bd >/dev/null 2>&1 && bd version >/dev/null 2>&1; }
if bd_works; then
  say "beads    $(bd version 2>/dev/null | head -1)"
else
  if ! bd_works && command -v brew >/dev/null 2>&1; then
    say "beads    installing with Homebrew"; brew install beads || true
  fi
  if ! bd_works && command -v npm >/dev/null 2>&1; then
    say "beads    installing with npm"; npm install -g @beads/bd || true
    bd_works || { say "beads    the npm package left no working bd; removing it"; npm uninstall -g @beads/bd >/dev/null 2>&1 || true; }
  fi
  if ! bd_works; then
    say "beads    installing with the beads install script"
    curl -fsSL https://raw.githubusercontent.com/gastownhall/beads/main/scripts/install.sh | bash || true
    export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
  fi
  bd_works || { say "Could not install beads. Install it from https://github.com/gastownhall/beads and run this again."; exit 1; }
  # the beads script may build bd into ~/go/bin, which is on nobody's PATH; put it beside koujou so both are found together
  case "$(command -v bd)" in "$HOME/go/bin/"*)
    mkdir -p "$HOME/.local/bin" && ln -sf "$HOME/go/bin/bd" "$HOME/.local/bin/bd"
    say "beads    linked into ~/.local/bin (it was built in ~/go/bin, which is not on your PATH)";;
  esac
  say "beads    $(bd version 2>/dev/null | head -1)"
fi

# 2. locate or fetch the factory
SELF="${BASH_SOURCE[0]:-}"
if [[ -n "$SELF" && -d "$(cd "$(dirname "$SELF")" 2>/dev/null && pwd)/skills/factory" ]]; then
  SRC="$(cd "$(dirname "$SELF")" && pwd)"            # running from a clone
  say "koujou   using this checkout: $SRC"
else
  command -v git >/dev/null 2>&1 || { say "git is required"; exit 1; }
  if [[ -d "$HOME_DIR/.git" ]]; then
    say "koujou   updating $HOME_DIR"; git -C "$HOME_DIR" pull --ff-only --quiet
  else
    say "koujou   cloning into $HOME_DIR"
    slug="${REPO#https://github.com/}"; slug="${slug%.git}"
    GIT_TERMINAL_PROMPT=0 git clone --quiet "$REPO" "$HOME_DIR" 2>/dev/null \
      || { command -v gh >/dev/null 2>&1 && gh repo clone "$slug" "$HOME_DIR" -- --quiet; } \
      || { say "could not clone $REPO (private repo? run: gh auth login)"; exit 1; }
  fi
  SRC="$HOME_DIR"
fi

# 3. link
exec "$SRC/bin/koujou" link
