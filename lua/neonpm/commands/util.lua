local notify = require("neonpm.ui.notify")
local progress = require("neonpm.ui.progress")
local runner = require("neonpm.runner")

local M = {}

local FLAGS = {
  ["-D"] = "dev",
  ["--dev"] = "dev",
  ["--save-dev"] = "dev",
  ["-g"] = "global",
  ["--global"] = "global",
  ["-E"] = "exact",
  ["--exact"] = "exact",
  ["--save-exact"] = "exact",
}

--- @param args string[]
--- @return string[] positional arguments, table flags
function M.parse_args(args)
  local positional = {}
  local flags = { dev = false, global = false, exact = false }
  for _, arg in ipairs(args or {}) do
    local flag = FLAGS[arg]
    if flag then
      flags[flag] = true
    else
      table.insert(positional, arg)
    end
  end
  return positional, flags
end

local function sorted_keys(tbl)
  local keys = {}
  for key in pairs(tbl or {}) do
    table.insert(keys, key)
  end
  table.sort(keys)
  return keys
end

--- @param pkg table
--- @return string[]
function M.dependencies(pkg)
  local merged = {}
  for _, section in ipairs({ pkg.dependencies, pkg.devDependencies }) do
    for name in pairs(section or {}) do
      merged[name] = true
    end
  end
  return sorted_keys(merged)
end

--- @param pkg table
--- @return string[]
function M.scripts(pkg)
  return sorted_keys(pkg.scripts)
end

--- @param ctx table { root, pkg, manager, bufnr }
--- @param req table
--- @return boolean, string|nil
function M.exec(ctx, req)
  local argv, build_err = ctx.manager.build(req)
  if not argv then
    notify.error(build_err)
    return false, build_err
  end

  if vim.fn.executable(argv[1]) ~= 1 then
    local err = string.format("%s not found in $PATH", argv[1])
    notify.error(err)
    return false, err
  end

  local title = table.concat(argv, " ")
  local handle = progress.start({ title = title })
  -- With an indicator on screen the notifications would say the same thing twice,
  -- so they stand down — except for failures, which the runner still reports.
  local indicated = progress.is_active()

  local run_opts = { cwd = ctx.root, root = ctx.root, quiet = indicated }
  if indicated and progress.wants_output() then
    run_opts.on_output = function(line)
      handle:report(line)
    end
  end

  -- A successful command rewrites package.json and/or the lockfile from a subprocess,
  -- which fires no BufWritePost — so the caches must be dropped here.
  local ok, run_err = runner.run_async(argv, run_opts, function(result)
    local succeeded = result.code == 0
    handle:finish(succeeded, succeeded and "done" or string.format("exit code %d", result.code))
    if succeeded then
      require("neonpm.project").clear_cache()
      require("neonpm.manager").clear_cache()
    end
  end)
  if not ok then
    handle:finish(false, run_err)
    notify.error(run_err)
    return false, run_err
  end

  if not indicated then
    notify.info(title .. " …")
  end
  return true
end

return M
