-- Ruff: linting, quick-fixes, import sorting and formatting.
-- Runs alongside pyright; hover is disabled here so the two don't both answer K.
return {
  cmd = { vim.fn.exepath('ruff') ~= '' and 'ruff' or vim.fn.expand('~/.local/bin/ruff'), 'server' },
  filetypes = { 'python' },
  root_markers = { 'ruff.toml', '.ruff.toml', 'pyproject.toml', '.git' },
  -- Ruff defaults to UTF-8 while pyright uses UTF-16. Two clients on one buffer
  -- with different position encodings means wrong columns on any line holding
  -- non-ASCII text, so pin ruff to match.
  capabilities = {
    general = { positionEncodings = { 'utf-16' } },
  },
  on_attach = function(client, _)
    client.server_capabilities.hoverProvider = false
  end,
}
