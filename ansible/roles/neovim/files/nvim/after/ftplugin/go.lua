-- Go is formatted with tabs by gofmt; spaces here would be reformatted on save.
vim.bo.expandtab = false
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4

-- gofmt enforces no line-length limit, so the 88-column guide is noise here.
vim.opt_local.colorcolumn = ''

-- Every indent level in Go is a tab, and marking each one with a glyph turns
-- the whole file into arrows. Keep trailing-space marking, drop the tab glyph.
vim.opt_local.listchars:remove('tab')
vim.opt_local.listchars:append({ tab = '  ' })
