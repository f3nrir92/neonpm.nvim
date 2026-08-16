local cmdutil = require("neonpm.commands.util")
local notify = require("neonpm.ui.notify")
local picker = require("neonpm.ui.picker")

local function candidates(ctx, lead)
  local names = cmdutil.dependencies(ctx.pkg)
  if not lead or lead == "" then
    return names
  end
  return vim.tbl_filter(function(name)
    return name:sub(1, #lead) == lead
  end, names)
end

return {
  name = "uninstall",
  desc = "Remove a package from dependencies",
  complete = candidates,
  run = function(ctx, args)
    local pkgs, flags = cmdutil.parse_args(args)

    if #pkgs > 0 then
      cmdutil.exec(ctx, { op = "remove", pkgs = pkgs, global = flags.global })
      return
    end

    local names = cmdutil.dependencies(ctx.pkg)
    if #names == 0 then
      notify.warn("package.json has no dependencies")
      return
    end

    local items = {}
    for _, name in ipairs(names) do
      table.insert(items, { label = name, value = name })
    end

    picker.pick(items, { prompt = "Remove package" }, function(value)
      if not value then
        return
      end
      cmdutil.exec(ctx, { op = "remove", pkgs = { value }, global = flags.global })
    end)
  end,
}
