--- Null progress backend: the floor of the fallback chain, always available.
--- Its handle satisfies the same contract as a real one, so callers never
--- branch on whether a progress indicator exists.
local M = { name = "off" }

function M.is_available()
  return true
end

--- @param _opts table { title = string }
--- @return table handle
function M.start(_opts)
  return {
    report = function() end,
    finish = function() end,
  }
end

return M
