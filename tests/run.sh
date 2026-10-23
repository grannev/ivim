#!/usr/bin/env bash
# Headless checks of the whole configuration: ./tests/run.sh
#
# Runs the real config against the plugins and mason packages already
# installed in ~/.local/share/nvim, with a throwaway config and state
# directory and a copy of tests/fixtures as a git repository, so neither
# this repo nor the editor's own state (undo, sessions, shada) changes.
# The island stays silent: there is no token in the throwaway config.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/config" "$tmp/state"
ln -s "$repo" "$tmp/config/nvim"
cp -r "$repo/tests/fixtures" "$tmp/work"
git -C "$tmp/work" init -q
git -C "$tmp/work" add -A
git -C "$tmp/work" -c user.name=tests -c user.email=tests@localhost commit -qm fixtures

cd "$tmp/work"
# the spellfile plugin would stop on a download prompt for ru.utf-8.spl
XDG_CONFIG_HOME="$tmp/config" XDG_STATE_HOME="$tmp/state" timeout 300 \
    nvim --headless --cmd "let g:loaded_spellfile_plugin = 1" -c "luafile $repo/tests/smoke.lua"
