-- Node/TypeScript resolution helpers.
local M = {}

-- nil = not looked up yet, false = looked up and absent, string = lib path
local global_lib

--- Does this project ship its own TypeScript?
--- @param root string|nil Project root.
function M.project_has_typescript(root)
  if not root or root == '' then return false end
  return vim.uv.fs_stat(root .. '/node_modules/typescript/lib/tsserver.js') ~= nil
end

--- Path to the globally installed TypeScript's lib directory, or nil.
--- Cached: `npm root -g` spawns node and is slow.
function M.global_typescript_lib()
  if global_lib ~= nil then
    return global_lib or nil
  end
  global_lib = false

  if vim.fn.executable('npm') ~= 1 then return nil end
  local res = vim.system({ 'npm', 'root', '-g' }, { text = true }):wait(5000)
  if res.code ~= 0 then return nil end

  local root = vim.trim(res.stdout or '')
  if root == '' then return nil end

  local lib = root .. '/typescript/lib'
  -- TypeScript 7 is the Go port and ships no tsserver.js, so its presence --
  -- not the package's -- is what decides whether this is usable.
  if vim.uv.fs_stat(lib .. '/tsserver.js') then
    global_lib = lib
    return lib
  end
  return nil
end

return M
