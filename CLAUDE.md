# iVim — project brief

Reply to the user in Russian. Code, comments and commit messages in English.
Four-space indentation in every file (see `.editorconfig` / `.stylua.toml`).
Commits end with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`,
and with a `Claude-Session: <url>` trailer when the session has a
claude.ai URL (a terminal session has none).

## What this is

The Neovim configuration for a desktop whose top bar is *island-shell*
(`~/it/coding/island-shell`), a Dynamic-Island-style notch. With the
island's companion plugin loaded, the island shows the mode, file, cursor
position, git and diagnostics, saves and LSP progress arrive as pills, and
the pointer on the island opens a panel with the buffer list and Save /
Format / Close. Neovim also has its own status line at the bottom
(`lua/config/statusline.lua`), at the user's request.

Behaviour (plugins, keymaps, popups, completion flow) follows
`github.com/grannev/dotfiles.nvim`. The theme is tokyonight (night style,
transparent in a terminal); colours only this config has — TODO keywords,
the start screen, the tab line — are set in its `on_highlights` in
`lua/plugins/colorscheme.lua`, plugin specs set none. `colors/ivim.lua` is
the previous graphite palette, kept as an alternative.

## Who owns what

- **The look of the editor itself** — everything inside the terminal:
  colours, keymaps, plugins, completion, LSP, treesitter, windows, the
  command line — belongs to the agent working in this repository.
- **The island layer** — `lua/plugins/island.lua` here, plus the plugin
  `island-shell/nvim/lua/island.lua` and the island's Rust side — belongs
  to the agent working in `island-shell`. Change it there, not here.

## The island contract (do not break)

- `lua/plugins/island.lua` must stay: it loads `island.nvim` with
  `lazy = false` and disables lualine. It passes `statusline = true`, so
  the island leaves `laststatus` alone; the status line is iVim's own
  (`lua/config/statusline.lua`, global, `laststatus = 3`), not a plugin.
- `require("island").setup()` leaves `vim.notify` alone: messages stay in
  Neovim's command line, the island only flashes its chip on a write.
- The plugin reads `vim.b.gitsigns_status_dict` for the branch and the
  diff — keep gitsigns.
- Diagnostics come from `vim.diagnostic`; any LSP setup works.
- `:IslandTask <cmd>` and `:IslandPing` are the island's user commands.
- The token in `~/.config/island-shell/nvim-token` is what lets this
  configuration into the island; without it the plugin stays silent.
