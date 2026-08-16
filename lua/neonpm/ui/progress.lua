local config = require("neonpm.config")

local M = {}

--- Backends tried when `progress.backend` is nil. `off` is the floor and is
--- appended implicitly — it is always available.
local ORDER = { "fidget" }

local function load_backend(name)
  local ok, backend = pcall(require, "neonpm.ui.progress." .. name)
  if not ok or type(backend) ~= "table" then
    return nil
  end
  return backend
end

--- @return table backend
function M.select_backend()
  local configured = config.get().progress.backend

  if configured then
    local backend = load_backend(configured)
    if backend and backend.is_available() then
      return backend
    end
    return load_backend("off")
  end

  for _, name in ipairs(ORDER) do
    local backend = load_backend(name)
    if backend and backend.is_available() then
      return backend
    end
  end

  return load_backend("off")
end

--- Whether a real indicator will be shown. Callers use this to stand down their
--- own notifications rather than saying the same thing twice.
--- @return boolean
function M.is_active()
  return M.select_backend().name ~= "off"
end

--- Whether the caller should stream command output into the handle.
--- @return boolean
function M.wants_output()
  return config.get().progress.detail == "output"
end

--- @param opts table { title = string }
--- @return table handle with `report(line)` and `finish(ok, message)`
function M.start(opts)
  return M.select_backend().start(opts or {})
end

return M
