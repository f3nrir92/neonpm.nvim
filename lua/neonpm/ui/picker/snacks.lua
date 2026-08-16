local M = { name = "snacks" }

function M.is_available()
  local ok, snacks = pcall(require, "snacks")
  return ok and snacks.picker ~= nil
end

function M.pick(items, opts, on_choice)
  local snacks = require("snacks")
  local entries = {}
  for index, item in ipairs(items) do
    table.insert(entries, { idx = index, text = item.label, value = item.value })
  end

  snacks.picker.pick({
    title = opts.prompt or "NeoNpm",
    items = entries,
    format = "text",
    confirm = function(picker, item)
      picker:close()
      on_choice(item and item.value or nil)
    end,
  })
end

return M
