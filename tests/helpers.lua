local M = {}

--- Absolute path to a fixture directory.
--- @param name string directory name inside tests/fixtures
--- @return string
function M.fixture(name)
  local cwd = vim.uv.cwd()
  return vim.fs.joinpath(cwd, "tests", "fixtures", name)
end

--- Replaces `vim.notify` with a collector so notifications do not leak into the
--- suite output. Returns the collected list plus a restore function; specs call
--- this from `before_each` and the restore function from `after_each`.
--- @return table[] notifications { { msg = string, level = integer } }, function restore
function M.capture_notify()
  local collected = {}
  local original = vim.notify
  vim.notify = function(msg, level)
    table.insert(collected, { msg = msg, level = level })
  end
  return collected, function()
    vim.notify = original
  end
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
