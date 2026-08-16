# neonpm.nvim

Hierarchical Neovim commands for the Node.js package manager. The manager is
detected automatically: npm, pnpm, yarn or bun.

## Requirements

- Neovim 0.12+
- One of: npm, pnpm, yarn, bun

No plugin dependencies are required. If telescope, snacks, fzf-lua or mini.pick
is installed, it is used for selection; otherwise `vim.ui.select` is.

## Installation

lazy.nvim:

```lua
{ "f3nrir92/neonpm.nvim", cmd = "NeoNpm" }
```

`setup()` is optional, so the plugin can stay lazy until `:NeoNpm` is used. Add
`opts = { ... }` only when you want to change the defaults.

## Commands

| Command | What it does |
| --- | --- |
| `:NeoNpm` | Picker listing the available commands |
| `:NeoNpm install` | Install every dependency from the lockfile |
| `:NeoNpm install <pkg> [-D] [-g] [-E]` | Add a package |
| `:NeoNpm uninstall [<pkg>]` | Remove a package; without an argument, a picker |
| `:NeoNpm update` | Update dependencies |
| `:NeoNpm run [<script>] [args…]` | Run a script; without an argument, a picker |

`install`, `uninstall` and `update` run asynchronously: the result arrives as a
notification and the full output accumulates in the `neonpm://log` buffer. `run`
opens a terminal buffer, so colours, progress bars and Ctrl-C all work.

## Configuration

```lua
require("neonpm").setup({
  manager = nil,               -- "npm"|"pnpm"|"yarn"|"bun" — hard override
  root = { patterns = { "package.json" } },
  ui = {
    picker = nil,              -- nil = autodetect
    picker_order = { "telescope", "snacks", "fzf_lua", "mini", "select" },
  },
  log = { auto_open = "error" }, -- "error"|"always"|"never"
  run = { win = "split" },       -- "split"|"vsplit"|"tab"|"float"
  progress = {
    backend = nil,               -- nil = use fidget.nvim if installed; "fidget"; "off"
    detail = "spinner",          -- "spinner"|"output"
  },
  notify = true,
})
```

## Progress indicator

If [fidget.nvim](https://github.com/j-hui/fidget.nvim) is installed, `install`,
`uninstall` and `update` show a progress item while they run — the command line
as the title, then a tick or the exit code when it finishes. Nothing is required
to enable it, and nothing breaks without it: the indicator falls back to a no-op
and the ordinary notifications take over.

`detail = "output"` additionally streams the package manager's output into the
item, so the caption follows along (`resolving`, `added 42 packages`). Note that
the manager runs without a TTY, so it prints no progress bars or percentages of
its own — the caption is the last line it wrote, not a completion figure.

While an indicator is on screen the plain start/finish notifications stand down
to avoid saying the same thing twice. Failures are still reported through
`vim.notify`, indicator or not.

## How the manager is chosen

1. `manager` from the configuration.
2. The `packageManager` field in `package.json`.
3. Lockfile — searched upward from the directory holding `package.json`:
   `bun.lock`, `bun.lockb`, `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`.
4. Otherwise npm.

The project root is searched upward from the file in the current buffer, so in a
monorepo the command runs in the directory of the package you are editing.

## Development

```bash
luarocks --lua-version=5.1 install --local busted
luarocks --lua-version=5.1 install --local nlua
make test
make lint
make fmt-check
```

`--lua-version=5.1` is required: the system default luarocks tree targets Lua
5.4, which is ABI-incompatible with the LuaJIT that `nlua` embeds, and `busted`
then fails to load. `make test` itself sources the luarocks 5.1 path, so once
the rocks are installed you can run it directly, with no `eval` beforehand.
