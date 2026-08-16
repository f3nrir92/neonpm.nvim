local notify = require("neonpm.ui.notify")
local registry = require("neonpm.registry")

local M = {}

local BUILTIN = { "install", "uninstall", "update", "run" }

--- Registers the built-in commands, at most once.
--- Registration state lives in the registry tree alone: a separate boolean here could
--- disagree with it after `registry.reset()` or after this module is reloaded on its own.
function M.ensure()
  local root = registry.root()
  if root.children and #root.children > 0 then
    return
  end
  for _, name in ipairs(BUILTIN) do
    local ok, node = pcall(require, "neonpm.commands." .. name)
    if ok then
      registry.register(node)
    else
      notify.error(string.format("failed to load command %q: %s", name, tostring(node)))
    end
  end
end

return M
