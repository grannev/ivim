# iVim — project brief

Reply to the user in Russian. Code, comments and commit messages in English.
Four-space indentation in every file (see `.editorconfig` / `.stylua.toml`).
Commits end with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`
and a `Claude-Session: <url>` trailer.

## What this is

The Neovim configuration for a desktop whose top bar is *island-shell*
(`~/it/coding/island-shell`), a Dynamic-Island-style notch. With the
island's companion plugin loaded, the island **is** Neovim's status line:
mode, file, cursor position, git and diagnostics are shown there, saves
and LSP progress arrive as pills, and the pointer on the island opens a
panel with the buffer list and Save / Format / Close.

## Who owns what

- **The look of the editor itself** — everything inside the terminal:
  colours, keymaps, plugins, completion, LSP, treesitter, windows, the
  command line — belongs to the agent working in this repository.
- **The island layer** — `lua/plugins/island.lua` here, plus the plugin
  `island-shell/nvim/lua/island.lua` and the island's Rust side — belongs
  to the agent working in `island-shell`. Change it there, not here.

## The island contract (do not break)

- `lua/plugins/island.lua` must stay: it loads `island.nvim` with
  `lazy = false` and disables lualine. Do not re-enable a status line
  plugin or set `laststatus` elsewhere; the island sets `laststatus = 0`.
- `require("island").setup()` leaves `vim.notify` alone: messages stay in
  Neovim's command line, the island only flashes its chip on a write.
- The plugin reads `vim.b.gitsigns_status_dict` for the branch and the
  diff — keep gitsigns.
- Diagnostics come from `vim.diagnostic`; any LSP setup works.
- `:IslandTask <cmd>` and `:IslandPing` are the island's user commands.
- The token in `~/.config/island-shell/nvim-token` is what lets this
  configuration into the island; without it the plugin stays silent.
