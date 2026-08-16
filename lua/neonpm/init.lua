local commands = require("neonpm.commands")
local config = require("neonpm.config")

local M = {}

--- @param opts table|nil
function M.setup(opts)
  config.setup(opts)
  commands.ensure()
end

return M
