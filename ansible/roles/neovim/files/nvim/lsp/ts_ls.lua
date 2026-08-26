-- typescript-language-server: TypeScript and JavaScript, including JSX/TSX.
--
-- Formatting is deliberately NOT applied on save (see `format_rules` in
-- lua/lsp.lua). tsserver's formatter is not Prettier, and most JS/TS projects
-- use Prettier, so formatting on save would fight the project's own config.
-- <leader>f still formats on demand.
return {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  -- tsconfig/jsconfig identify the actual project; package.json is the fallback
  -- for plain JS with no config, and .git the last resort.
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
  init_options = {
    -- tsserver tailors a few diagnostics and completions to the host editor.
    hostInfo = 'neovim',
  },
  before_init = function(params, config)
    local node = require('util.node')

    -- Prefer the project's own TypeScript: version differences are meaningful.
    if node.project_has_typescript(config.root_dir) then return end

    -- typescript-language-server only searches the workspace for TypeScript, so
    -- without this a bare .ts file (or a project with no typescript dependency)
    -- refuses to start: "Could not find a valid TypeScript installation".
    local lib = node.global_typescript_lib()
    if not lib then return end

    -- Mutate `params`, not `config.init_options`. init_options is copied into
    -- these params before before_init runs, so assigning to config would be
    -- silently discarded -- the same trap as `settings` in lsp/pyright.lua.
    params.initializationOptions = vim.tbl_deep_extend('force',
      params.initializationOptions or {}, { tsserver = { path = lib } })
  end,
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = 'literals',
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = false,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
      },
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = 'literals',
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = false,
        includeInlayFunctionLikeReturnTypeHints = true,
      },
    },
  },
}
