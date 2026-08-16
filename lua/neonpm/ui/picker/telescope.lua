local M = { name = "telescope" }

function M.is_available()
  return pcall(require, "telescope")
end

function M.pick(items, opts, on_choice)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local state = require("telescope.actions.state")

  pickers
    .new({}, {
      prompt_title = opts.prompt or "NeoNpm",
      finder = finders.new_table({
        results = items,
        entry_maker = function(item)
          return { value = item.value, display = item.label, ordinal = item.label }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(bufnr)
        actions.select_default:replace(function()
          local entry = state.get_selected_entry()
          actions.close(bufnr)
          on_choice(entry and entry.value or nil)
        end)
        return true
      end,
    })
    :find()
end

return M
