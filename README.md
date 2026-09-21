# iVim

A Neovim configuration built around
[island-shell](../island-shell) — the Dynamic Island at the top of the
screen is the editor's status line, notification area and buffer switcher.
Commands and their output use Neovim's native display.

Lazy.nvim, LSP through mason, treesitter, telescope, blink.cmp, conform,
gitsigns and nvim-tree, with a local graphite palette inspired by macOS.

## Appearance

`colors/ivim.lua` owns the palette: transparent editor surfaces, muted
Tree-sitter accents, italic control keywords, a subtle current-line highlight,
an 80-column guide and rounded transparent panels.
Panels use the terminal background with blending disabled, hiding buffer text
behind them while preserving the terminal's transparency.
Absolute line numbers and quiet git marks stay beside the code. Diagnostics
use underlines; press `<leader>d` for details. The command line appears when
needed, and the island owns mode, file state and editor actions.

Commands (`:`, `/`, `?`) and their output stay in Neovim. The island command
interface is disabled in `lua/plugins/island.lua`; its source is preserved on
the `archive/island-command-ui-2026-09-19` branches in this repository and
island-shell. Clicking diagnostic counters in the island panel shows
up to three problems in the current file; clicking a row jumps to its location.

Telescope is the primary file navigator (`<leader>ff`); the compact file tree
is available with `<leader>e`. Completion documentation appears after a short
delay. Completion opens automatically: `Tab` and `Shift-Tab` move through the
list, while `Enter` accepts the selected item. `Ctrl-Backspace` deletes the
previous word. Quotes and brackets are left untouched; pressing `Enter` after
an opening brace creates a closed block and places the cursor one indentation
level inside it. Scrolling remains immediate, without animation plugins.

## Layout

    init.lua                 loads config.options, config.keymaps, config.lazy
    lua/config/              options, keymaps, the lazy.nvim bootstrap
    lua/plugins/*.lua        one spec file per concern
    lua/plugins/island.lua   the island layer (see CLAUDE.md)
    lazy-lock.json           pinned plugin versions

`~/.config/nvim` is a symlink to this directory. Indentation is four
spaces everywhere (`.editorconfig`, `.stylua.toml`).
