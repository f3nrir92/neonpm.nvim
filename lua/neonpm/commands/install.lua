local cmdutil = require("neonpm.commands.util")

return {
  name = "install",
  desc = "Install project dependencies or add a package",
  run = function(ctx, args)
    local pkgs, flags = cmdutil.parse_args(args)
    local req
    if #pkgs == 0 then
      req = { op = "install" }
    else
      req = { op = "add", pkgs = pkgs, dev = flags.dev, global = flags.global, exact = flags.exact }
    end
    cmdutil.exec(ctx, req)
  end,
}
