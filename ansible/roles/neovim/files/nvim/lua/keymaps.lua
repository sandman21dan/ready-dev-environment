-- General and plugin keymaps. Leader is <Space>.
local map = vim.keymap.set

-- Quality of life
map('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })
map('n', '<leader>w', '<cmd>write<cr>', { desc = 'Write' })
map('n', '<leader>Q', '<cmd>qall<cr>', { desc = 'Quit all' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Leave terminal mode' })

-- Window navigation
map('n', '<C-h>', '<C-w>h', { desc = 'Window left' })
map('n', '<C-j>', '<C-w>j', { desc = 'Window down' })
map('n', '<C-k>', '<C-w>k', { desc = 'Window up' })
map('n', '<C-l>', '<C-w>l', { desc = 'Window right' })

-- Keep the cursor centred when jumping around
map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')
map('n', 'n', 'nzzzv')
map('n', 'N', 'Nzzzv')

-- Move the selected lines up/down
map('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
map('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

-- Paste over a selection without clobbering the unnamed register
map('x', '<leader>p', [["_dP]], { desc = 'Paste without yanking' })

------------------------------------------------------------------- file tree
map('n', '<leader>n', '<cmd>NvimTreeToggle<cr>', { desc = 'Toggle file tree' })
map('n', '<leader>N', '<cmd>NvimTreeFindFile<cr>', { desc = 'Reveal file in tree' })

---------------------------------------------------------------- fuzzy finder
local fzf = require('fzf-lua')
map('n', '<leader><leader>', fzf.files, { desc = 'Find files' })
map('n', '<leader>ff', fzf.files, { desc = 'Find files' })
map('n', '<leader>fg', fzf.live_grep, { desc = 'Live grep (ripgrep)' })
map('n', '<leader>fw', fzf.grep_cword, { desc = 'Grep word under cursor' })
map('n', '<leader>fb', fzf.buffers, { desc = 'Buffers' })
map('n', '<leader>fh', fzf.helptags, { desc = 'Help tags' })
map('n', '<leader>fk', fzf.keymaps, { desc = 'Keymaps' })
map('n', '<leader>fr', fzf.resume, { desc = 'Resume last picker' })
map('n', '<leader>fd', fzf.diagnostics_workspace, { desc = 'Workspace diagnostics' })
map('n', '<leader>fs', fzf.lsp_document_symbols, { desc = 'Document symbols' })
map('n', '<leader>fS', fzf.lsp_live_workspace_symbols, { desc = 'Workspace symbols' })
-- LSP navigation through the picker (nicer than the quickfix list)
map('n', 'grr', fzf.lsp_references, { desc = 'LSP references' })
map('n', '<leader>fi', fzf.lsp_implementations, { desc = 'LSP implementations' })

------------------------------------------------------------------------ git
map('n', '<leader>gs', '<cmd>Gitsigns stage_hunk<cr>', { desc = 'Stage hunk' })
map('n', '<leader>gr', '<cmd>Gitsigns reset_hunk<cr>', { desc = 'Reset hunk' })
map('n', '<leader>gp', '<cmd>Gitsigns preview_hunk<cr>', { desc = 'Preview hunk' })
map('n', '<leader>gb', '<cmd>Gitsigns blame_line<cr>', { desc = 'Blame line' })
map('n', ']c', '<cmd>Gitsigns next_hunk<cr>', { desc = 'Next hunk' })
map('n', '[c', '<cmd>Gitsigns prev_hunk<cr>', { desc = 'Previous hunk' })

----------------------------------------------------------------------- run
-- <leader>rr runs the current file the way its language expects.
local runners = {
  python = function()
    -- The project's interpreter, not whatever python3 is on PATH.
    return { require('util.python').find_python(vim.fn.getcwd()), vim.fn.expand('%:p') }
  end,
  go = function()
    -- `go run .` builds the whole package; `go run main.go` breaks as soon as
    -- the package has a second file.
    return { 'go', 'run', '.' }
  end,
  lua = function()
    return { 'nvim', '-l', vim.fn.expand('%:p') }
  end,
  javascript = function()
    return { 'node', vim.fn.expand('%:p') }
  end,
}

vim.keymap.set('n', '<leader>rr', function()
  local runner = runners[vim.bo.filetype]
  if not runner then
    vim.notify('No runner for filetype: ' .. (vim.bo.filetype == '' and '(none)' or vim.bo.filetype),
      vim.log.levels.WARN)
    return
  end
  vim.cmd('write')
  local dir = vim.fn.expand('%:p:h')
  vim.cmd('botright split | resize 15')
  vim.fn.jobstart(runner(), { term = true, cwd = dir })
  vim.cmd('startinsert')
end, { desc = 'Run current file' })

vim.keymap.set('n', '<leader>rt', function()
  local cmds = { go = 'go test ./...', python = 'pytest' }
  local cmd = cmds[vim.bo.filetype]
  if not cmd then
    vim.notify('No test command for ' .. vim.bo.filetype, vim.log.levels.WARN)
    return
  end
  vim.cmd('botright split | resize 15')
  vim.fn.jobstart(cmd, { term = true, cwd = vim.fn.getcwd() })
end, { desc = 'Run tests' })
