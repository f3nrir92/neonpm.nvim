local config = require("neonpm.config")

local M = {}

local function emit(msg, level, force)
  if not force and not config.get().notify then
    return
  end
  vim.notify("neonpm: " .. msg, level)
end

function M.info(msg)
  emit(msg, vim.log.levels.INFO, false)
end

function M.warn(msg)
  emit(msg, vim.log.levels.WARN, false)
end

function M.error(msg)
  emit(msg, vim.log.levels.ERROR, true)
end

return M
