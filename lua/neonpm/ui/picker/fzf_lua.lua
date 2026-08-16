local M = { name = "fzf_lua" }

function M.is_available()
  return pcall(require, "fzf-lua")
end

function M.pick(items, opts, on_choice)
  local fzf = require("fzf-lua")
  local by_label = {}
  local labels = {}
  for _, item in ipairs(items) do
    by_label[item.label] = item.value
    table.insert(labels, item.label)
  end

  fzf.fzf_exec(labels, {
    prompt = (opts.prompt or "NeoNpm") .. "> ",
    actions = {
      ["default"] = function(selected)
        local label = selected and selected[1]
        on_choice(label and by_label[label] or nil)
      end,
    },
  })
end

return M
