--- Progress backend backed by fidget.nvim. Optional: `is_available` is the only
--- entry point that touches the plugin, and it never raises when fidget is absent.
local M = { name = "fidget" }

function M.is_available()
  local ok, fidget_progress = pcall(require, "fidget.progress")
  return ok and type(fidget_progress) == "table" and fidget_progress.handle ~= nil
end

--- @param opts table { title = string }
--- @return table handle
function M.start(opts)
  local fidget_progress = require("fidget.progress")
  local handle = {
    _inner = fidget_progress.handle.create({
      title = opts.title or "neonpm",
      lsp_client = { name = "neonpm" },
    }),
    _done = false,
  }

  --- @param line string latest line of command output
  function handle:report(line)
    if self._done or type(line) ~= "string" or line == "" then
      return
    end
    self._inner:report({ message = line })
  end

  --- @param ok boolean whether the command succeeded
  --- @param message string|nil final message
  function handle:finish(ok, message)
    if self._done then
      return
    end
    self._done = true
    self._inner.message = message or (ok and "done" or "failed")
    self._inner:finish()
  end

  return handle
end

return M
