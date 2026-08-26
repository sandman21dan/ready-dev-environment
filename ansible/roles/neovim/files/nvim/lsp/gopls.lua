-- gopls: types, completion, navigation, formatting and import management.
-- One server does everything for Go, unlike the pyright + ruff split.
return {
  cmd = { 'gopls' },
  -- Only filetypes nvim actually registers. 'gotmpl' is NOT one of them, and
  -- listing it makes `:checkhealth vim.lsp` warn; Go templates need a
  -- vim.filetype.add() rule of your own before gopls can be pointed at them.
  filetypes = { 'go', 'gomod', 'gowork' },
  -- go.work first so a multi-module workspace attaches one server, not one per
  -- module. `.git` last: it is the weakest signal of a Go project root.
  root_markers = { 'go.work', 'go.mod', '.git' },
  settings = {
    gopls = {
      -- Analyses beyond the default set. These are the cheap, high-signal ones.
      staticcheck = true,
      analyses = {
        unusedparams = true,
        unusedwrite = true,
        nilness = true,
        useany = true,
        shadow = false,      -- noisy on idiomatic `err :=` shadowing
      },
      -- Show the reason a symbol is unused/deprecated inline.
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
      -- Complete unimported packages and add the import automatically.
      completeUnimported = true,
      usePlaceholders = true,
      -- gofumpt is stricter than gofmt; leave it off so formatting matches
      -- what `go fmt` and CI produce.
      gofumpt = false,
      -- Surface build/vet problems for the whole module, not just open files.
      directoryFilters = { '-.git', '-node_modules', '-bin' },
      semanticTokens = true,
    },
  },
}
