local M = { name = "select" }

function M.is_available()
  return true
end

function M.pick(items, opts, on_choice)
  vim.ui.select(items, {
    prompt = opts.prompt or "NeoNpm",
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    on_choice(item and item.value or nil)
  end)
end

return M
