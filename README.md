# iVim

A Neovim configuration built around
[island-shell](../island-shell) — the Dynamic Island at the top of the
screen is the editor's status line, notification area and buffer switcher.
Commands and their output use Neovim's native display.

What the editor *does* comes from
[dotfiles.nvim](https://github.com/grannev/dotfiles.nvim): native tabs, LSP
with delayed popups, Telescope, Oil, Trouble, Spectre, a floating terminal
with LazyGit, a file runner, sessions, C/C++ body folds, LaTeX through
VimTeX, ru/en spellcheck and a config health check. What it *looks like* is
iVim's own: the graphite palette, transparent panels, quiet gutter marks and
no status line. On top of both sits iVim's Rust layer (rustaceanvim,
crates.nvim, nvim-dap with codelldb) and conform for formatters.

## Appearance

The theme is [tokyonight](https://github.com/folke/tokyonight.nvim) in its
night style — deep navy with blue, azure and cyan accents, italic comments
and keywords — set up in `lua/plugins/colorscheme.lua`. It colours every
installed plugin on its own; the groups only this config has (TODO
keywords, the start screen, the tab line, the code-action mark) are added
there too. In a terminal the editor and its panels stay transparent, so the
wallpaper shows through. `colors/ivim.lua`, the previous graphite palette,
is still available: `:colorscheme ivim`. Diagnostics use underlines and
letters in the gutter (E W I H), as do TODO comments (T F H W N P) and code
actions (A); TODO keywords keep vivid colours so they stand out, and the
whole comment — its /* or // included — takes the keyword's colour. The
command line appears when needed, and the island owns mode, file state and
editor actions.

A bare `nvim` opens on iVim's own start screen (`lua/config/intro.lua`): the
name in block letters and the few keys worth knowing in an empty editor; it
goes away as soon as you type or open something.

Motion is animated (`lua/plugins/animate.lua`): neoscroll glides
`Ctrl-d/u/f/b/e/y`, `zz/zt/zb` and the mouse wheel line by line, slowing
down as it arrives, and `Ctrl-d/u` and `n/N` end with the cursor line in
the middle of the window; mini.animate draws the cursor's jumps and
windows resizing, opening and closing. It works in any terminal.

## Island

`lua/plugins/island.lua` loads island.nvim and keeps lualine off; see
CLAUDE.md for the contract. `:NvimConfigHealth` (`<leader>ch`) has an
*Island* section that says whether the token is there, the plugin is
loaded and the status line is hidden. `:IslandTask <cmd>` runs a command
with a progress pill, `:IslandPing` checks the connection. Oil, terminal
and Trouble buffers are unlisted, so the island's buffer list shows files
only.

## Keys

Leader is `Space`.

    Files and search
    <leader>e   Oil, floating          -        Oil, parent directory
    <leader>ff  find files             <leader>fg  live grep
    <leader>fb  buffers                <leader>fh  help
    <leader>ft  TODOs                  <leader>sr  project search/replace
    <leader>sR  replace word           <leader>sF  replace in file

    Buffers, windows, tabs
    <leader>w / q   write / quit       <leader>sv / sh  vertical / horizontal split
    <leader>bn/bp/bd/bl  buffers       Ctrl-h/j/k/l  move between windows
    Ctrl-Up/Down, Ctrl-Alt-Left/Right  resize
    <leader>tt/tc/to  new / close / only tab
    Alt-Left/Right  previous / next tab, Alt-1..9 jump, Alt-Shift-Left/Right move

    LSP
    gd gD gi gr  definition, declaration, implementation, references
    K            hover (Rust: hover actions)
    <leader>gt   implementation in a new tab
    <leader>rn   rename                <leader>ca  code action
    <leader>lf   format (conform, LSP fallback)
    <leader>ld   line diagnostics      [d / ]d  previous / next diagnostic
    <leader>ih   inlay hints           <leader>uh  popup hints
    The diagnostic under the cursor opens after 0.5 s; with popup hints on,
    hover follows after 3 s and completion opens by itself.

    Completion
    Tab opens the menu after a word and moves down, Shift-Tab up, Enter
    accepts. With the menu closed, Enter between a typed pair — (|) {|} "|"
    — opens a line between the halves. Nothing inserts pairs on its own.

    Git, terminal, run
    ]c / [c      next / previous hunk  <leader>gp/gr/gb  preview, reset, blame
    <leader>gg   LazyGit               Ctrl-\  floating terminal, Esc leaves it
    <leader>rr   run the current file (cargo run in a Cargo project)
    <leader>mm   :make, <leader>mo/mc/mn/mp  quickfix

    Rust (in .rs buffers)
    <leader>rR runnables, rt testables, rd debuggables, rm expand macro,
    ro Cargo.toml, re explain error

    Debug
    <leader>Db / DB  breakpoint / conditional   F5 / <leader>Dc  continue
    F10 / F11, <leader>Do/Di/DO  step over / into / out
    <leader>Dr REPL, Dt terminate, Du UI, F9 breakpoint

    Diagnostics and problems
    <leader>xx project, xb buffer, xr references, xq quickfix, xt TODOs
    ]t / [t  next / previous TODO

    Folds (C/C++ fold only function bodies)
    za / <leader>z  toggle     zM  fold all bodies     zR  open all

    Sessions (per working directory)
    <leader>ss / sl / sd  save / load / delete, :SessionInfo

    Spell (on for tex, markdown, text, gitcommit)
    <leader>sp toggle, sa / sA add, su undo add, sf suggestions

    LaTeX (in .tex buffers)
    <leader>ll compile, lv view in Evince, le errors, lt TOC, lk stop,
    lc clean, li info

    Comments
    gcc / gc  line comment, gbc / gb  block comment (C/C++: /* */)

## Layout

    init.lua                 options, colours, config modules, then lazy
    lua/plugins/colorscheme.lua  tokyonight and this config's own groups
    colors/ivim.lua          the previous graphite palette (:colorscheme ivim)
    lua/config/              options, keymaps, lazy bootstrap and the
                             behaviour modules (folds, sessions, runner,
                             spell, popup hints, health, ...)
    lua/config/tools.lua     every mason package, in one list: installed
                             at startup, checked by :NvimConfigHealth
    lua/plugins/*.lua        one spec file per concern
    lua/plugins/island.lua   the island layer (see CLAUDE.md)
    lua/plugins/rust.lua     rustaceanvim, crates.nvim
    lua/plugins/dap.lua      debugging (nvim-dap); rust.lua wires it up
    lazy-lock.json           pinned plugin versions

## Tests

    ./tests/run.sh

runs `tests/smoke.lua` in a headless Neovim against the installed plugins
and mason packages, in throwaway config and state directories with a copy
of `tests/fixtures`: startup without messages, the island contract, the
keymaps, a language server per language (C, C++, Lua, Rust), the Telescope
previewer, TODO colours and gutter letters, C folds, the tab line, the
start screen, the scroll animation and the health check. It prints a line
per check and exits non-zero on a failure; run it after `:Lazy update`.

`~/.config/nvim` is a symlink to this directory. Indentation is four
spaces everywhere (`.editorconfig`, `.stylua.toml`). `:NvimConfigRepair`
(`<leader>cr`) installs missing mason packages and system tools (apt or
pacman); LazyGit has to be installed separately for `<leader>gg`.
