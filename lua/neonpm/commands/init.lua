local registry = require("neonpm.registry")

local M = {}

local registered = false

local BUILTIN = { "install", "uninstall", "update", "run" }

function M.ensure()
  if registered then
    return
  end
  for _, name in ipairs(BUILTIN) do
    local ok, node = pcall(require, "neonpm.commands." .. name)
    if ok then
      registry.register(node)
    end
  end
  registered = true
end

function M.reset()
  registered = false
  registry.reset()
end

return M
