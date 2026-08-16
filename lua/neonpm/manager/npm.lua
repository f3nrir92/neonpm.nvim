local M = {
  name = "npm",
  bin = "npm",
  lockfiles = { "package-lock.json" },
}

local function append(argv, list)
  for _, item in ipairs(list or {}) do
    table.insert(argv, item)
  end
end

function M.build(req, _)
  local op = req.op
  local pkgs = req.pkgs or {}
  local argv = { M.bin }

  if op == "install" then
    table.insert(argv, "install")
  elseif op == "add" then
    if #pkgs == 0 then
      return nil, "npm: no package given"
    end
    table.insert(argv, "install")
    if req.global then
      table.insert(argv, "--global")
    end
    if req.dev then
      table.insert(argv, "--save-dev")
    end
    if req.exact then
      table.insert(argv, "--save-exact")
    end
    append(argv, pkgs)
  elseif op == "remove" then
    if #pkgs == 0 then
      return nil, "npm: no package given"
    end
    table.insert(argv, "uninstall")
    if req.global then
      table.insert(argv, "--global")
    end
    append(argv, pkgs)
  elseif op == "update" then
    table.insert(argv, "update")
  elseif op == "run" then
    if not req.script or req.script == "" then
      return nil, "npm: no script name given"
    end
    table.insert(argv, "run")
    table.insert(argv, req.script)
    if req.args and #req.args > 0 then
      table.insert(argv, "--")
      append(argv, req.args)
    end
  else
    return nil, string.format("npm: operation %q is not supported", tostring(op))
  end

  return argv
end

return M
