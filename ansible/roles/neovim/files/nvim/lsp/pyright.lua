-- Pyright: types, completion, go-to-definition, hover.
-- Dropped in ~/.config/nvim/lsp/, so `vim.lsp.enable('pyright')` finds it.
return {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyrightconfig.json', 'pyproject.toml', 'setup.py',
    'setup.cfg', 'requirements.txt', 'Pipfile', '.git',
  },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        -- 'workspace' type-checks the whole project (slower on big repos).
        diagnosticMode = 'openFilesOnly',
        -- 'off' | 'basic' | 'standard' | 'strict'
        typeCheckingMode = 'standard',
        inlayHints = {
          variableTypes = true,
          functionReturnTypes = true,
          callArgumentNames = true,
        },
      },
    },
  },
  before_init = function(_, config)
    -- Point pyright at this project's venv, resolved per root_dir.
    -- NOTE: mutate `config.settings` in place. The client captures a reference
    -- to this table before before_init runs (see vim/lsp/client.lua), so
    -- reassigning config.settings would be silently discarded.
    config.settings.python.pythonPath = require('util.python').find_python(config.root_dir)
  end,
}
