local cmdutil = require("neonpm.commands.util")
local notify = require("neonpm.ui.notify")
local picker = require("neonpm.ui.picker")
local runner = require("neonpm.runner")

local function candidates(ctx, lead)
  local names = cmdutil.scripts(ctx.pkg)
  if not lead or lead == "" then
    return names
  end
  return vim.tbl_filter(function(name)
    return name:sub(1, #lead) == lead
  end, names)
end

local function launch(ctx, script, args)
  local argv, err = ctx.manager.build({ op = "run", script = script, args = args })
  if not argv then
    notify.error(err)
    return
  end
  if vim.fn.executable(argv[1]) ~= 1 then
    notify.error(string.format("%s not found in $PATH", argv[1]))
    return
  end
  runner.run_terminal(argv, { cwd = ctx.root, root = ctx.root, script = script })
end

return {
  name = "run",
  desc = "Run a script from package.json",
  complete = candidates,
  run = function(ctx, args)
    args = args or {}
    local script = args[1]

    if script then
      local tail = {}
      for i = 2, #args do
        table.insert(tail, args[i])
      end
      launch(ctx, script, tail)
      return
    end

    local names = cmdutil.scripts(ctx.pkg)
    if #names == 0 then
      notify.warn("package.json has no scripts section")
      return
    end

    local items = {}
    for _, name in ipairs(names) do
      table.insert(items, { label = string.format("%s — %s", name, ctx.pkg.scripts[name]), value = name })
    end

    picker.pick(items, { prompt = "Run script" }, function(value)
      if not value then
        return
      end
      launch(ctx, value, {})
    end)
  end,
}
