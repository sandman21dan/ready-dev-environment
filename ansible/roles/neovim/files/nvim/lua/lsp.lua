-- Native LSP wiring. No nvim-lspconfig: nvim 0.11+ reads server definitions
-- straight out of ~/.config/nvim/lsp/<name>.lua.

------------------------------------------------------------------ diagnostics
vim.diagnostic.config({
  virtual_text = { prefix = '●', spacing = 2 },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = 'E',
      [vim.diagnostic.severity.WARN]  = 'W',
      [vim.diagnostic.severity.INFO]  = 'I',
      [vim.diagnostic.severity.HINT]  = 'H',
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = true },
})

--------------------------------------------------------------- enable servers
-- server name (matching lsp/<name>.lua) -> the binary it needs
local candidates = {
  pyright = 'pyright-langserver',
  ruff    = 'ruff',
  gopls   = 'gopls',
  lua_ls  = 'lua-language-server',
  ts_ls   = 'typescript-language-server',
  -- The npm package is svelte-language-server; the binary it ships is not.
  svelte  = 'svelteserver',
}

-- Only enable servers whose binary is actually present. Provisioning can
-- legitimately skip one (gopls needs a Go toolchain to build at all), and
-- enabling a missing server means an error every time you open that filetype.
local servers, missing = {}, {}
for name, binary in pairs(candidates) do
  if vim.fn.executable(binary) == 1 then
    table.insert(servers, name)
  else
    table.insert(missing, ('%s (%s)'):format(name, binary))
  end
end
vim.lsp.enable(servers)

vim.api.nvim_create_user_command('LspServers', function()
  table.sort(servers)
  table.sort(missing)
  local lines = { 'enabled: ' .. (next(servers) and table.concat(servers, ', ') or 'none') }
  if next(missing) then
    table.insert(lines, 'not installed: ' .. table.concat(missing, ', '))
  end
  vim.notify(table.concat(lines, '\n'))
end, { desc = 'Which language servers are enabled here' })

------------------------------------------------------- per-buffer LSP keymaps
-- nvim 0.11 already ships defaults: K hover, grn rename, gra code action,
-- grr references, gri implementation, gO document symbols, ]d/[d diagnostics.
-- These fill the remaining gaps.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp_attach', { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then return end

    local function map(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = 'LSP: ' .. desc })
    end

    map('gd', vim.lsp.buf.definition, 'goto definition')
    map('gD', vim.lsp.buf.declaration, 'goto declaration')
    map('gy', vim.lsp.buf.type_definition, 'goto type definition')
    map('<leader>e', vim.diagnostic.open_float, 'line diagnostics')
    map('<leader>q', vim.diagnostic.setloclist, 'diagnostics to loclist')
    map('<leader>lr', function() vim.cmd('LspRestart') end, 'restart servers')
    map('<leader>li', function() vim.cmd('checkhealth vim.lsp') end, 'LSP info')

    -- Inlay hints, off by default; <leader>th toggles them.
    if client:supports_method('textDocument/inlayHint') then
      map('<leader>th', function()
        local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf })
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = ev.buf })
      end, 'toggle inlay hints')
    end
  end,
})

----------------------------------------------------------------- formatting
-- Which server owns formatting per filetype, and which code actions to run
-- before formatting it. Anything not listed here just uses whichever attached
-- client advertises formatting.
--   formatter: server name that must do the formatting
--   actions:   code action kinds to apply first (import sorting, mostly)
--   on_save:   set false to format only on demand, never on write
local format_rules = {
  python = { formatter = 'ruff',  actions = { 'source.organizeImports.ruff' } },
  go     = { formatter = 'gopls', actions = { 'source.organizeImports' } },
  gomod  = { formatter = 'gopls' },
  lua    = { formatter = 'lua_ls' },
  -- svelte-language-server formats with Prettier internally (it bundles
  -- prettier-plugin-svelte and honours .prettierrc), so saving is safe.
  svelte = { formatter = 'svelte' },
}

-- tsserver's formatter is NOT Prettier, and most JS/TS projects use Prettier.
-- Formatting on save would fight the project's own config and produce diff
-- churn, so it stays manual: <leader>f formats when you actually ask.
for _, ft in ipairs({ 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' }) do
  format_rules[ft] = { formatter = 'ts_ls', on_save = false }
end

--- Request one code action kind from one server and apply it synchronously.
local function code_action_sync(bufnr, client_name, kind)
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = client_name })[1]
  if not client then return end

  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  -- CodeActionParams does carry `context`, but make_range_params is typed more
  -- narrowly than that, so lua_ls flags the assignment as a field injection.
  ---@diagnostic disable-next-line: inject-field
  params.context = { only = { kind }, diagnostics = {} }

  local res = client:request_sync('textDocument/codeAction', params, 2000, bufnr)
  if not res or res.err or not res.result then return end

  for _, action in pairs(res.result) do
    -- Some servers (ruff) advertise actions with no edit attached; you have to
    -- ask for the edit via codeAction/resolve before there is anything to apply.
    if not action.edit then
      local resolved = client:request_sync('codeAction/resolve', action, 2000, bufnr)
      action = (resolved and not resolved.err and resolved.result) or action
    end
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    end
    -- gopls can answer with a command instead of an edit.
    if action.command then
      local cmd = type(action.command) == 'table' and action.command or action
      client:exec_cmd(cmd, { bufnr = bufnr })
    end
  end
end

local function format_buffer(bufnr, opts)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  opts = opts or {}
  local rule = format_rules[vim.bo[bufnr].filetype] or {}

  -- Filetypes that opt out of formatting on write still format on demand.
  if opts.on_save and rule.on_save == false then return end

  local formatters = vim.tbl_filter(function(c)
    return c:supports_method('textDocument/formatting')
      and (rule.formatter == nil or c.name == rule.formatter)
  end, vim.lsp.get_clients({ bufnr = bufnr }))

  -- Nothing attached that can format (scratch buffers, help, checkhealth, ...).
  -- Bail quietly rather than letting vim.lsp.buf.format warn on every save.
  if #formatters == 0 then return end

  for _, kind in ipairs(rule.actions or {}) do
    pcall(code_action_sync, bufnr, rule.formatter, kind)
  end

  vim.lsp.buf.format({
    bufnr = bufnr,
    async = false,
    filter = function(c) return rule.formatter == nil or c.name == rule.formatter end,
  })
end

vim.g.autoformat = true   -- set false to stop formatting on save

vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('lsp_format_on_save', { clear = true }),
  callback = function(ev)
    if vim.g.autoformat then format_buffer(ev.buf, { on_save = true }) end
  end,
})

vim.api.nvim_create_user_command('AutoFormatToggle', function()
  vim.g.autoformat = not vim.g.autoformat
  vim.notify('format on save: ' .. (vim.g.autoformat and 'ON' or 'OFF'))
end, { desc = 'Toggle format on save' })

-- Ruff's safe auto-fixes (unused imports, `exit` -> `sys.exit()`, ...) are NOT
-- applied on save, since they rewrite code rather than just reflow it. Ask
-- for them explicitly.
vim.api.nvim_create_user_command('RuffFixAll', function()
  code_action_sync(vim.api.nvim_get_current_buf(), 'ruff', 'source.fixAll.ruff')
end, { desc = 'Apply all safe ruff fixes' })
vim.keymap.set('n', '<leader>lf', '<cmd>RuffFixAll<cr>', { desc = 'Ruff: fix all' })

vim.keymap.set('n', '<leader>f', function() format_buffer() end, { desc = 'Format buffer' })
vim.keymap.set('n', '<leader>tf', '<cmd>AutoFormatToggle<cr>', { desc = 'Toggle format on save' })

-- Report which interpreter pyright was handed, for when imports look wrong.
vim.api.nvim_create_user_command('PythonInterpreter', function()
  local util = require('util.python')
  util.clear_cache()
  vim.notify('python: ' .. util.find_python(vim.fn.getcwd()))
end, { desc = 'Show the interpreter LSP will use here' })
