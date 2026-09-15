# iVim

A Neovim configuration built around
[island-shell](../island-shell) — the Dynamic Island at the top of the
screen is the editor's status line, notification area and buffer switcher,
so the terminal stays clean: no status line, no message noise.

Lazy.nvim, LSP through mason, treesitter, telescope, blink.cmp, conform,
gitsigns, nvim-tree, Oceanic Next on a transparent Alacritty.

## Layout

    init.lua                 loads config.options, config.keymaps, config.lazy
    lua/config/              options, keymaps, the lazy.nvim bootstrap
    lua/plugins/*.lua        one spec file per concern
    lua/plugins/island.lua   the island layer (see CLAUDE.md)
    lazy-lock.json           pinned plugin versions

`~/.config/nvim` is a symlink to this directory. Indentation is four
spaces everywhere (`.editorconfig`, `.stylua.toml`).
