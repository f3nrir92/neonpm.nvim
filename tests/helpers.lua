local M = {}

--- Absolute path to a fixture directory.
--- @param name string directory name inside tests/fixtures
--- @return string
function M.fixture(name)
  local cwd = vim.uv.cwd()
  return vim.fs.joinpath(cwd, "tests", "fixtures", name)
end

--- Unloads the plugin modules so each test starts from a clean state.
function M.reload()
  for key in pairs(package.loaded) do
    if key:match("^neonpm") then
      package.loaded[key] = nil
    end
  end
end

return M
