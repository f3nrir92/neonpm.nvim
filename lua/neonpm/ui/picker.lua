local config = require("neonpm.config")

local M = {}

local function load_backend(name)
  local ok, backend = pcall(require, "neonpm.ui.picker." .. name)
  if not ok or type(backend) ~= "table" then
    return nil
  end
  return backend
end

--- @return table
function M.select_backend()
  local ui = config.get().ui

  if ui.picker then
    local backend = load_backend(ui.picker)
    if backend and backend.is_available() then
      return backend
    end
  end

  for _, name in ipairs(ui.picker_order) do
    local backend = load_backend(name)
    if backend and backend.is_available() then
      return backend
    end
  end

  return load_backend("select")
end

--- @param items table[] { { label = string, value = any } }
--- @param opts table { prompt = string }
--- @param on_choice function(value|nil)
function M.pick(items, opts, on_choice)
  if not items or #items == 0 then
    on_choice(nil)
    return
  end
  M.select_backend().pick(items, opts or {}, on_choice)
end

return M
