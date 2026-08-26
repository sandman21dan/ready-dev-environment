# nvim config

Native LSP (no nvim-lspconfig), plugins via nvim 0.12's built-in `vim.pack`.
Leader is `<Space>`.

## Layout

    init.lua              entry point
    lua/options.lua       editor settings
    lua/plugins.lua       vim.pack specs + setup calls
    lua/lsp.lua           diagnostics, LSP keymaps, format-on-save
    lua/keymaps.lua       general + plugin keymaps
    lua/util/python.lua   resolves which python interpreter LSP should use
    lua/util/node.lua     resolves TypeScript for typescript-language-server
    after/ftplugin/go.lua go uses tabs, not spaces
    lsp/pyright.lua       server definition, auto-discovered by vim.lsp.enable
    lsp/ruff.lua
    lsp/gopls.lua
    lsp/lua_ls.lua
    lsp/ts_ls.lua
    lsp/svelte.lua

## External tools

| Tool | Provides | Install |
| --- | --- | --- |
| `pyright-langserver` | Python types, completion, navigation | `npm i -g pyright` |
| `ruff` | Python lint, format, import sort | `uv tool install ruff` |
| `gopls` | Go types, navigation, gofmt, imports | `go install golang.org/x/tools/gopls@latest` |
| `lua-language-server` | Lua LSP (for editing this config) | `brew install lua-language-server` |
| `typescript-language-server` | TS/JS/JSX | `npm i -g typescript-language-server typescript@5` |
| `svelteserver` | Svelte (binary name, not `svelte-language-server`) | `npm i -g svelte-language-server` |
| `tree-sitter` | compiles treesitter parsers | `brew install tree-sitter-cli` |
| `fzf`, `rg` | fuzzy finder + live grep | `brew install fzf ripgrep` |

Servers are only enabled when their binary is present, so a missing one is
skipped rather than erroring on every file. `:LspServers` shows which.

`typescript@5` is deliberate: TypeScript 7 is the Go rewrite and ships no
`tsserver.js`, which `typescript-language-server` requires.

## Plugin management

    :lua vim.pack.update()              review updates in a buffer, :w to apply
    :lua vim.pack.del({ 'name' })       delete from disk
    :lua =vim.pack.get()                list what's installed

## LSP

    :checkhealth vim.lsp    what's attached, root dir, capabilities
    :LspRestart             restart servers for this buffer
    :LspServers             which servers are enabled, and which are missing
    :PythonInterpreter      show the interpreter pyright was handed
    :AutoFormatToggle       turn format-on-save off/on

### Formatting

`format_rules` in `lua/lsp.lua` maps filetype to the server that owns
formatting, plus code actions to run first:

| Filetype | Formatter | Before formatting |
| --- | --- | --- |
| `python` | ruff | `source.organizeImports.ruff` |
| `go` | gopls | `source.organizeImports` (goimports) |
| `lua` | lua_ls | — |
| `svelte` | svelte | — (runs Prettier internally) |
| `typescript`, `javascript`, and their `react` variants | ts_ls, **on demand only** | — |

TS/JS set `on_save = false`: tsserver's formatter is not Prettier, and most
JS/TS projects use Prettier, so formatting on write would fight the project's
own config. `<leader>f` still formats when you ask.

Anything not listed uses whichever attached client advertises formatting.
Adding a language means adding a row, not writing new logic.

### Unresolved imports

If Python imports show as unresolved, it's almost always the interpreter.
`lua/util/python.lua` picks, in order: `$VIRTUAL_ENV`, then `.venv`/`venv`/
`.env`/`env` in the project root, then `poetry env info --path`, then
`python3` on `PATH`. Create a venv in the project and restart nvim.

For Go, unresolved imports mean the module cache is cold: run `go mod download`
in the project. gopls resolves dependencies from `$GOMODCACHE`, not from the
network, so a dependency that was never downloaded simply doesn't exist to it.

## Adding a language

1. Write `lsp/<server>.lua` returning `{ cmd, filetypes, root_markers, settings }`.
2. Add the name to `servers` in `lua/lsp.lua`.
3. If it formats, add a `format_rules` row.
4. Add its treesitter parsers to `ts_langs` in `lua/plugins.lua`.
5. Add a `runners` entry in `lua/keymaps.lua` if `<leader>rr` should run it.

Only use filetypes nvim actually registers — `:checkhealth vim.lsp` warns about
unknown ones (`gotmpl`, for instance, is not a real nvim filetype).
