local config = require("neonpm.config")
local project = require("neonpm.project")

local M = {}

M.order = { "bun", "pnpm", "yarn", "npm" }

local cache = {}

function M.clear_cache()
  cache = {}
end

--- @param name string
--- @return table|nil
function M.get(name)
  local ok, spec = pcall(require, "neonpm.manager." .. name)
  if not ok then
    return nil
  end
  return spec
end

--- @param spec table
--- @param opts table
--- @param source string
--- @return table
function M.bind(spec, opts, source)
  opts = opts or {}
  return {
    name = spec.name,
    bin = spec.bin,
    source = source,
    opts = opts,
    build = function(req)
      return spec.build(req, opts)
    end,
  }
end

local function is_berry(dir)
  return vim.uv.fs_stat(vim.fs.joinpath(dir, ".yarnrc.yml")) ~= nil
end

--- Walks upward from `dir` looking for a `.yarnrc.yml`, the same way
--- `detect_by_lockfile` walks upward looking for a lockfile.
--- @param dir string
--- @return boolean
local function is_berry_upward(dir)
  while dir and dir ~= "" do
    if is_berry(dir) then
      return true
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
  return false
end

--- Parses a packageManager field such as "pnpm@9.1.0".
--- @param value any
--- @return string|nil name, number|nil major
local function parse_package_manager(value)
  if type(value) ~= "string" then
    return nil
  end
  local name, version = value:match("^([%a]+)@?([%d%.]*)")
  if not name then
    return nil
  end
  local major = tonumber(version:match("^(%d+)") or "")
  return name, major
end

--- Searches upward from the package directory for a lockfile.
--- @param root string
--- @return string|nil manager name, string|nil directory holding the lockfile
local function detect_by_lockfile(root)
  local dir = root
  while dir and dir ~= "" do
    for _, name in ipairs(M.order) do
      local spec = M.get(name)
      for _, lockfile in ipairs(spec and spec.lockfiles or {}) do
        if vim.uv.fs_stat(vim.fs.joinpath(dir, lockfile)) then
          return name, dir
        end
      end
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
  return nil
end

--- @param root string
--- @return table|nil bound manager, string|nil error message (present only when detection fails)
function M.detect(root)
  local hit = cache[root]
  if hit and hit.gen == config.generation() then
    return hit.value
  end

  local override = config.get().manager
  if override then
    local spec = M.get(override)
    if not spec then
      return nil, string.format("unknown manager %q in configuration", override)
    end
    local bound = M.bind(spec, { berry = override == "yarn" and is_berry_upward(root) or false }, "config")
    cache[root] = { value = bound, gen = config.generation() }
    return bound
  end

  local pkg = project.read_package(root)
  if pkg then
    local name, major = parse_package_manager(pkg.packageManager)
    local spec = name and M.get(name)
    if spec then
      local berry = name == "yarn" and ((major or 1) >= 2 or is_berry_upward(root))
      local bound = M.bind(spec, { berry = berry }, "packageManager")
      cache[root] = { value = bound, gen = config.generation() }
      return bound
    end
  end

  local name, dir = detect_by_lockfile(root)
  if name then
    local spec = M.get(name)
    local bound = M.bind(spec, { berry = name == "yarn" and is_berry(dir) or false }, "lockfile")
    cache[root] = { value = bound, gen = config.generation() }
    return bound
  end

  local bound = M.bind(M.get("npm"), {}, "fallback")
  cache[root] = { value = bound, gen = config.generation() }
  return bound
end

local group = vim.api.nvim_create_augroup("NeonpmManagerCache", { clear = true })

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  group = group,
  pattern = { "package.json", "package-lock.json", "pnpm-lock.yaml", "yarn.lock", "bun.lock", "bun.lockb" },
  callback = function()
    M.clear_cache()
    project.clear_cache()
  end,
})

vim.api.nvim_create_autocmd({ "DirChanged" }, {
  group = group,
  callback = function()
    M.clear_cache()
    project.clear_cache()
  end,
})

return M
