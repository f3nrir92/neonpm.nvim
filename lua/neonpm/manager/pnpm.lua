local M = {
  name = "pnpm",
  bin = "pnpm",
  lockfiles = { "pnpm-lock.yaml" },
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
      return nil, "pnpm: no package given"
    end
    table.insert(argv, "add")
    if req.global then
      table.insert(argv, "-g")
    end
    if req.dev then
      table.insert(argv, "-D")
    end
    if req.exact then
      table.insert(argv, "-E")
    end
    append(argv, pkgs)
  elseif op == "remove" then
    if #pkgs == 0 then
      return nil, "pnpm: no package given"
    end
    table.insert(argv, "remove")
    if req.global then
      table.insert(argv, "-g")
    end
    append(argv, pkgs)
  elseif op == "update" then
    table.insert(argv, "update")
  elseif op == "run" then
    if not req.script or req.script == "" then
      return nil, "pnpm: no script name given"
    end
    table.insert(argv, "run")
    table.insert(argv, req.script)
    append(argv, req.args)
  else
    return nil, string.format("pnpm: operation %q is not supported", tostring(op))
  end

  return argv
end

return M
