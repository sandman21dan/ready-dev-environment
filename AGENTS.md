# AGENTS.md

Guidance for AI coding agents working in this repository.

## Repository Purpose

This is a development environment setup repository that creates Docker containers and Ansible playbooks for installing common development tools and configurations. It provides both containerized and local installation methods for a pre-configured development environment.

## Core Architecture

- **Dockerfile**: Creates Ubuntu 24.04 container with Ansible, adds `docker` user with sudo privileges
- **docker-compose.yaml**: Orchestrates dev container with volume mounts (`~/development`, `~/.ssh`) and port 1234 forwarding
- **ansible/index.yaml**: Main playbook that detects OS/platform and installs tools via apt/brew
- **ansible/roles/**: Modular roles for asdf (language management), git plugins, neovim, and language servers
- **ansible/templates/**: Shell and editor configuration files (zshrc, vimrc, tmux.conf)
- **ansible/scripts/**: Helper scripts synced to `~/.local/scripts/` and exposed through the `my-scripts` CLI (see Scripts)

## Commands

Docker usage, multi-platform builds and the local `ansible-playbook` run are documented in `README.md`.
Lint and format YAML with `make lint` / `make format` (or the `-with-docker` variants).

## Key Configuration Details

### NeoVim (native LSP)

NeoVim is configured in Lua using its built-in LSP client and built-in `vim.pack`
plugin manager. There is no nvim-lspconfig, no Mason and no vim-plug/coc.nvim.

- `ansible/roles/neovim/files/nvim/` is the config tree, copied verbatim to
  `~/.config/nvim`. It uses `copy`, not `template`, because none of it needs
  substitution and Lua's nested tables produce `{{` that Jinja would evaluate.
- Server definitions are one file each in `lsp/<name>.lua`, discovered by
  `vim.lsp.enable()` in `lua/lsp.lua`.
- Servers are only enabled when their binary exists (`candidates` in
  `lua/lsp.lua`), because provisioning can legitimately skip one -- gopls needs
  a Go toolchain. `:LspServers` reports what is enabled and what is missing.
- Adding a language: write `lsp/<server>.lua`, add it to `candidates` in
  `lua/lsp.lua`, add a `format_rules` row if it formats, and add its parsers to
  `ts_langs` in `lua/plugins.lua`. See `files/nvim/README.md`.
- Formatting on save is per filetype. `format_rules` entries can set
  `on_save = false` to format only on demand: TS/JS do, because tsserver's
  formatter is not Prettier and would fight a project's own config. Svelte does
  format on save, since svelte-language-server runs Prettier internally.

**NeoVim version is the one unavoidable platform split.** The config needs
>= 0.12 (`vim.pack`; `vim.lsp.config` needs 0.11), and Ubuntu 24.04 apt ships
0.9.5. So `neovim` is in `brew_dependencies` for macOS, while Linux installs the
upstream static tarball in `roles/neovim/tasks/install-linux.yaml`. Bump
`neovim_version` in the role defaults to upgrade Linux; the role reinstalls when
the running version differs and fails with a clear message if the binary is too
old on either platform.

Migration is handled: an existing `~/.config/nvim/init.vim` is renamed to
`init.vim.bak`, because NeoVim refuses to start with both `init.vim` and
`init.lua` present. vim-plug and its plugins (including coc.nvim) are removed
unless `neovim_remove_legacy_plugins` is false.

### Language servers

Each server is installed the way it actually ships, which is why there are four
mechanisms rather than one:

| Server | Language | Mechanism | Where |
| --- | --- | --- | --- |
| `pyright` | Python types | npm | `roles/asdf/templates/default-npm-packages` |
| `ruff` | Python lint/format | Astral standalone installer | `roles/language-servers/tasks/ruff.yaml` |
| `gopls` | Go | `go install` (no prebuilt binaries exist) | `roles/language-servers/tasks/gopls.yaml` |
| `lua-language-server` | Lua | prebuilt tarball, darwin + linux | `roles/language-servers/tasks/lua-language-server.yaml` |
| `typescript-language-server` | TS/JS/JSX | npm | `default-npm-packages` |
| `svelte-language-server` | Svelte | npm | `default-npm-packages` |

`tree-sitter-cli` also comes from npm; nvim-treesitter's `main` branch shells out
to it to compile parsers.

**`default-npm-packages` supports no comments.** asdf-nodejs feeds each line
straight to `npm install -g`, so a `#` line would be passed through as a package
name. Any rationale belongs here instead.

**`typescript` is pinned to `typescript@5` on purpose.** TypeScript 7 is the Go
rewrite and ships no `tsserver.js`, while `typescript-language-server` hardcodes
it -- so an unpinned `typescript` silently breaks TS/JS support on every fresh
provision. Two related notes:

- The binary that `svelte-language-server` installs is **`svelteserver`**, which
  is what `lsp/svelte.lua` invokes.
- `typescript-language-server` only searches the *workspace* for TypeScript, so
  a global install alone does not help. `lsp/ts_ls.lua` prefers the project's
  own `node_modules/typescript` and falls back to the global one, which is what
  makes a bare `.ts` file work instead of erroring.

gopls is **conditional on a Go toolchain being present**. The playbook adds the
asdf `golang` plugin but never installs a Go version, so a fresh machine has no
`go`; the role reports that it skipped gopls rather than failing. Install Go and
re-run to add it. Note `go install` requires `asdf reshim golang` afterwards or
the binary stays invisible, which the role does.

### Language Management (asdf)
- Downloads platform-specific asdf binary (Linux AMD64/ARM64)
- Installs plugins for Python, Node.js, Java, Go, Terraform, AWS CLI
- Auto-detects latest stable Python version when `python_version: "latest"`
- Uses `.default-npm-packages` template for global npm packages

### Platform Detection
- `wsl` variable: Detects WSL by checking for "microsoft" in kernel name
- `shorthand_arch`: Maps `x86_64` to `amd64`, `aarch64`/`arm64` to `arm64`
- Separate dependency lists for apt vs brew package managers

### Git Enhancements
- Installs git-fire and git-open utilities to `~/.local/bin/`
- Configures diff-so-fancy for enhanced git diff output
- Sets up color schemes and pager configuration globally

### Variables
- `python_version`: default "latest" (auto-detects stable release)
- `skip_install_python`: default false
- `node_version`: default "latest"
- `skip_install_node`: default false
- `sql_server_deps`: default false
- `neovim_version`: pinned NeoVim tag installed on Linux (role default)
- `neovim_minimum_version`: refuse to configure an older NeoVim (role default)
- `neovim_remove_legacy_plugins`: default true (removes vim-plug and coc.nvim)
- `install_ruff` / `install_gopls` / `install_lua_language_server`: default true
- `lua_ls_version`: pinned lua-language-server release

## Scripts and the `my-scripts` CLI

- `ansible/scripts/` is the single source of truth for helper scripts. The playbook rsyncs it to
  `~/.local/scripts/`. Edit scripts in the repo and re-run the playbook; do not edit the deployed copies.
- `roles/my-scripts/` builds a small Go (cobra) CLI from `files/my-scripts-cli/` into `~/.local/bin/my-scripts`.
  At runtime it scans `~/.local/scripts/` and turns each `.py`/`.sh`/`.js` or executable file into a subcommand named
  after the file without its extension (`my-scripts join_lines`). Nothing is registered per script, so adding a script
  needs no CLI change. The binary is only rebuilt when the playbook runs, so changes to `main.go` need a re-run.
- The text shown in `my-scripts --help` comes from a `# @description: ...` comment (`//` for JS) on its own line near
  the top of each script. Without it the command shows "No description available.", so every script should have one.
- Do not add shell aliases or functions in `templates/zshrc` that wrap a script; the CLI already exposes it.
- **`update.sh` is a template**, not a plain script: `templates/update.sh.j2` is rendered to
  `~/.local/scripts/update.sh` because the package manager differs per OS (brew on macOS, apt with an up-front
  `sudo -v` on Debian/Ubuntu/WSL). It must not also live in `scripts/`, or rsync would deploy the raw file.
