local M = {
  name = "yarn",
  bin = "yarn",
  lockfiles = { "yarn.lock" },
}

local function append(argv, list)
  for _, item in ipairs(list or {}) do
    table.insert(argv, item)
  end
end

function M.build(req, opts)
  opts = opts or {}
  local berry = opts.berry == true
  local op = req.op
  local pkgs = req.pkgs or {}
  local argv = { M.bin }

  if req.global and berry then
    return nil, "yarn berry: global operations are not supported, use yarn dlx"
  end

  if op == "install" then
    table.insert(argv, "install")
  elseif op == "add" then
    if #pkgs == 0 then
      return nil, "yarn: no package given"
    end
    if req.global then
      table.insert(argv, "global")
    end
    table.insert(argv, "add")
    if req.dev then
      table.insert(argv, "-D")
    end
    if req.exact then
      table.insert(argv, "-E")
    end
    append(argv, pkgs)
  elseif op == "remove" then
    if #pkgs == 0 then
      return nil, "yarn: no package given"
    end
    if req.global then
      table.insert(argv, "global")
    end
    table.insert(argv, "remove")
    append(argv, pkgs)
  elseif op == "update" then
    table.insert(argv, berry and "up" or "upgrade")
  elseif op == "run" then
    if not req.script or req.script == "" then
      return nil, "yarn: no script name given"
    end
    table.insert(argv, "run")
    table.insert(argv, req.script)
    append(argv, req.args)
  else
    return nil, string.format("yarn: operation %q is not supported", tostring(op))
  end

  return argv
end

return M
