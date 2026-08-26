-- Editor options. Everything here is a direct port of the old init.vim,
-- plus the handful of settings an LSP setup wants.
local o = vim.opt

-- Search
o.ignorecase = true
o.smartcase = true          -- ...but an explicit capital makes it case-sensitive
o.hlsearch = true
o.incsearch = true
o.showmatch = true

-- Indentation (4 spaces, as before)
o.expandtab = true
o.tabstop = 4
o.softtabstop = 4
o.shiftwidth = 4
o.autoindent = true

-- UI
o.number = true
o.relativenumber = true     -- the numbertoggle augroup below flips this
o.cursorline = true
o.colorcolumn = '88'        -- ruff's default line length (was 80)
o.signcolumn = 'yes'        -- always reserve the gutter so it never jitters
o.termguicolors = true
o.scrolloff = 8
o.splitright = true
o.splitbelow = true
o.winborder = 'rounded'     -- nvim 0.11+: default border for hover/signature floats
o.list = true
o.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Behaviour
o.mouse = 'a'
o.clipboard = 'unnamedplus'
o.wildmode = { 'longest', 'list' }
o.undofile = true           -- persistent undo across sessions
o.updatetime = 250          -- faster CursorHold -> quicker diagnostics/git signs
o.timeoutlen = 400
o.completeopt = { 'menu', 'menuone', 'noselect' }
o.confirm = true            -- prompt instead of failing on unsaved :q

-- Web files conventionally use two spaces. This matters beyond taste: LSP
-- formatters take their indent width from the editor, so svelte-language-server
-- would otherwise emit 4-space Prettier output.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('web_indent', { clear = true }),
  pattern = {
    'typescript', 'typescriptreact', 'javascript', 'javascriptreact',
    'svelte', 'css', 'scss', 'html', 'json', 'jsonc', 'yaml',
  },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
    vim.bo.shiftwidth = 2
  end,
})

-- Relative numbers only in the focused window, and never in insert mode.
local numbertoggle = vim.api.nvim_create_augroup('numbertoggle', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'FocusGained', 'InsertLeave', 'WinEnter' }, {
  group = numbertoggle,
  callback = function()
    if vim.wo.number and vim.fn.mode() ~= 'i' then vim.wo.relativenumber = true end
  end,
})
vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost', 'InsertEnter', 'WinLeave' }, {
  group = numbertoggle,
  callback = function()
    if vim.wo.number then vim.wo.relativenumber = false end
  end,
})

-- Briefly highlight whatever was just yanked.
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})
