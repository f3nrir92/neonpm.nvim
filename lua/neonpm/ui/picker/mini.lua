local M = { name = "mini" }

function M.is_available()
  return pcall(require, "mini.pick")
end

function M.pick(items, opts, on_choice)
  local mini = require("mini.pick")
  local by_label = {}
  local labels = {}
  for _, item in ipairs(items) do
    by_label[item.label] = item.value
    table.insert(labels, item.label)
  end

  local chosen = mini.start({
    source = { items = labels, name = opts.prompt or "NeoNpm" },
  })
  on_choice(chosen and by_label[chosen] or nil)
end

return M
