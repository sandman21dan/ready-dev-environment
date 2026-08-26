-- ~/.config/nvim/init.lua
-- Leader must be set before any plugin or mapping is defined.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('options')   -- editor settings (migrated from the old init.vim)
require('plugins')   -- vim.pack plugin specs + their setup calls
require('lsp')       -- native LSP: diagnostics, keymaps, format-on-save
require('keymaps')   -- general + plugin keymaps
