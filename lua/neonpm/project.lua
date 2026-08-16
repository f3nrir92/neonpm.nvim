local config = require("neonpm.config")

local M = {}

local cache = {}

function M.clear_cache()
  cache = {}
end

--- @param start_path string path to a file or directory
--- @return string|nil directory containing the project marker
function M.find_root(start_path)
  if not start_path or start_path == "" then
    return nil
  end
  local stat = vim.uv.fs_stat(start_path)
  local start_dir = (stat and stat.type == "directory") and start_path or vim.fs.dirname(start_path)
  local found = vim.fs.find(config.get().root.patterns, { upward = true, path = start_dir, type = "file" })[1]
  if not found then
    return nil
  end
  return vim.fs.dirname(found)
end

--- @param root string
--- @return table|nil, string|nil
function M.read_package(root)
  if cache[root] then
    return cache[root]
  end
  local path = vim.fs.joinpath(root, "package.json")
  local fd = io.open(path, "r")
  if not fd then
    return nil, string.format("cannot open %s", path)
  end
  local raw = fd:read("*a")
  fd:close()

  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok or type(decoded) ~= "table" then
    return nil, string.format("%s: invalid JSON", path)
  end

  cache[root] = decoded
  return decoded
end

--- @param bufnr integer
--- @return table|nil, string|nil
function M.resolve(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  local start_path = (name ~= "" and vim.uv.fs_stat(name)) and name or vim.uv.cwd()

  local root = M.find_root(start_path)
  if not root then
    return nil, "package.json not found — this is not a Node.js project"
  end

  local pkg, err = M.read_package(root)
  if not pkg then
    return nil, err
  end

  return { root = root, pkg = pkg }
end

return M
