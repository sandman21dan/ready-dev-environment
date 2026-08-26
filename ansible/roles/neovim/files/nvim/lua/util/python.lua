-- Work out which Python interpreter an LSP server should use for a project.
-- Pyright resolves imports against this, so getting it right is the difference
-- between "works" and a buffer full of reportMissingImports.
local M = {}

local cache = {}   -- root_dir -> interpreter path

local function is_file(path)
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil and stat.type == 'file'
end

---@param root string|nil Project root; defaults to the cwd.
---@return string Absolute path to a python interpreter.
function M.find_python(root)
  root = root or vim.fn.getcwd()
  if cache[root] then return cache[root] end

  local found

  -- 1. An activated venv wins: you chose it explicitly.
  local active = vim.env.VIRTUAL_ENV
  if active and active ~= '' and is_file(active .. '/bin/python') then
    found = active .. '/bin/python'
  end

  -- 2. A venv sitting in the project (poetry's virtualenvs.in-project, uv, manual).
  if not found then
    for _, dir in ipairs({ '.venv', 'venv', '.env', 'env' }) do
      local candidate = root .. '/' .. dir .. '/bin/python'
      if is_file(candidate) then
        found = candidate
        break
      end
    end
  end

  -- 3. Ask poetry where it put the venv (only if this looks like a poetry project).
  if not found and is_file(root .. '/pyproject.toml') and vim.fn.executable('poetry') == 1 then
    local res = vim.system({ 'poetry', 'env', 'info', '--path' }, { cwd = root, text = true }):wait(3000)
    if res.code == 0 then
      local path = vim.trim(res.stdout or '')
      if path ~= '' and is_file(path .. '/bin/python') then
        found = path .. '/bin/python'
      end
    end
  end

  -- 4. Give up and use whatever python3 is on PATH.
  found = found or vim.fn.exepath('python3')

  cache[root] = found
  return found
end

--- Forget cached lookups, e.g. after creating a venv without restarting nvim.
function M.clear_cache()
  cache = {}
end

return M
