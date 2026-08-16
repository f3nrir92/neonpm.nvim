local cmdutil = require("neonpm.commands.util")

return {
  name = "update",
  desc = "Update project dependencies",
  run = function(ctx, _)
    cmdutil.exec(ctx, { op = "update" })
  end,
}
