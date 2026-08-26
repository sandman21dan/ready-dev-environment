-- Plugins, managed by nvim 0.12's built-in `vim.pack`.
--   :lua vim.pack.update()          review + apply updates
--   :lua vim.pack.del({ 'name' })   remove one from disk
-- Plugins live in ~/.local/share/nvim/site/pack/core/opt/

-- nvim-tree replaces netrw, so disable netrw before it loads.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.pack.add({
  -- Colourscheme: the Lua port of Dracula, which knows about treesitter
  -- and LSP highlight groups (the old dracula/vim did not).
  { src = 'https://github.com/Mofiqul/dracula.nvim' },

  -- Syntax, indent and text objects from real parsers.
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },

  -- Completion engine. `version` pins the 1.x release line, whose tags ship
  -- prebuilt fuzzy-matcher binaries (we fall back to Lua anyway, see below).
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1') },

  -- Fuzzy finder, driven by the fzf + ripgrep you already have installed.
  { src = 'https://github.com/ibhagwan/fzf-lua' },

  -- File tree (the nerdtree replacement) and the icons it and lualine use.
  { src = 'https://github.com/nvim-tree/nvim-tree.lua' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },

  -- Statusline and git gutter/hunk actions.
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },

  -- Auto-close brackets/quotes.
  { src = 'https://github.com/windwp/nvim-autopairs' },
}, { confirm = false })

--------------------------------------------------------------------- colours
require('dracula').setup({ transparent_bg = false, italic_comment = true })
vim.cmd.colorscheme('dracula')

----------------------------------------------------------------- treesitter
-- The `main` branch installs parsers on demand and expects you to start the
-- highlighter yourself per filetype.
local ts_langs = {
  'python', 'go', 'gomod', 'gosum', 'gowork',
  -- jsdoc is required by the javascript/typescript highlight queries.
  'typescript', 'tsx', 'javascript', 'jsdoc', 'svelte', 'css', 'html',
  'lua', 'toml', 'json', 'yaml', 'bash',
  'markdown', 'markdown_inline', 'diff', 'gitcommit', 'gitignore',
}
-- The main branch shells out to the `tree-sitter` CLI to build parsers. Without
-- it this call fails once per language on every single startup, so only ask for
-- installs when the CLI is actually there. Highlighting then falls back to Vim
-- regex syntax, which is degraded but silent.
if vim.fn.executable('tree-sitter') == 1 then
  require('nvim-treesitter').install(ts_langs)
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter_start', { clear = true }),
  callback = function(ev)
    -- get_lang() falls back to returning the filetype unchanged when nothing is
    -- registered, so plugin-owned filetypes ("NvimTree") arrive here looking
    -- like real languages. get_parser() then returns nil *without* raising, so
    -- the pcall succeeds and only the returned value tells you the truth --
    -- test the parser itself, or vim.treesitter.start() asserts.
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang then return end
    local ok, parser = pcall(vim.treesitter.get_parser, ev.buf, lang)
    if ok and parser then
      vim.treesitter.start(ev.buf, lang)
    end
  end,
})

----------------------------------------------------------------- completion
require('blink.cmp').setup({
  -- <Tab> accepts, <Tab>/<S-Tab> also jump through snippet placeholders,
  -- <C-n>/<C-p> move in the menu, <C-e> dismisses.
  keymap = { preset = 'super-tab' },

  -- Pure-Lua matcher: no Rust toolchain or binary download needed.
  fuzzy = { implementation = 'lua' },

  sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
  signature = { enabled = true },
  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
    menu = { border = 'rounded' },
  },
})

--------------------------------------------------------------------- finder
require('fzf-lua').setup({
  winopts = { height = 0.85, width = 0.85, preview = { layout = 'vertical' } },
})

------------------------------------------------------------------ file tree
require('nvim-tree').setup({
  view = { width = 36 },
  renderer = { group_empty = true, indent_markers = { enable = true } },
  filters = { dotfiles = false, custom = { '__pycache__', '.pytest_cache', '.ruff_cache' } },
  actions = { open_file = { quit_on_open = false } },
})

----------------------------------------------------------------- statusline
require('lualine').setup({
  options = { theme = 'auto', globalstatus = true, section_separators = '', component_separators = '|' },
  sections = {
    lualine_c = { { 'filename', path = 1 } },
    lualine_x = { 'diagnostics', 'encoding', 'filetype' },
  },
})

------------------------------------------------------------------------ git
require('gitsigns').setup({ current_line_blame = false })

------------------------------------------------------------------ autopairs
require('nvim-autopairs').setup({ check_ts = true })
