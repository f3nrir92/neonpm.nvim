local config = require("neonpm.config")
local log = require("neonpm.ui.log")
local notify = require("neonpm.ui.notify")

local M = {}

--- Injection point for tests.
M.system = vim.system

local busy = {}

--- @param root string
--- @return boolean
function M.is_busy(root)
  return busy[root] ~= nil
end

--- @param argv string[]
--- @param opts table { cwd, root }
--- @param on_done function|nil
--- @return boolean, string|nil
function M.run_async(argv, opts, on_done)
  local root = opts.root or opts.cwd
  if busy[root] then
    return false, string.format("already running in this project: %s", table.concat(busy[root], " "))
  end
  busy[root] = argv

  local ok, err = pcall(M.system, argv, { cwd = opts.cwd, text = true }, function(result)
    vim.schedule(function()
      busy[root] = nil
      log.append({
        argv = argv,
        cwd = opts.cwd,
        code = result.code,
        stdout = result.stdout,
        stderr = result.stderr,
      })
      if log.should_open(config.get().log.auto_open, result.code) then
        log.open()
      end
      if result.code == 0 then
        notify.info(string.format("%s — done", table.concat(argv, " ")))
      else
        notify.error(string.format("%s — exit code %d", table.concat(argv, " "), result.code))
      end
      if on_done then
        on_done(result)
      end
    end)
  end)

  if not ok then
    busy[root] = nil
    return false, tostring(err)
  end

  return true
end

--- @param root string
--- @param script string
--- @return string
function M.terminal_buf_name(root, script)
  return string.format("neonpm://run%s/%s", root, script)
end

--- @param bufnr integer buffer to show once the window is open (used by the float branch,
--- which must open directly on it rather than creating a scratch buffer of its own)
local function open_window(bufnr)
  local win = config.get().run.win
  if win == "vsplit" then
    vim.cmd.vsplit()
  elseif win == "tab" then
    vim.cmd.tabnew()
  elseif win == "float" then
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    vim.api.nvim_open_win(bufnr, true, {
      relative = "editor",
      width = width,
      height = height,
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      border = "rounded",
    })
  else
    vim.cmd.split()
  end
end

local function job_alive(bufnr)
  local job = vim.b[bufnr].terminal_job_id
  if not job then
    return false
  end
  return pcall(vim.fn.jobpid, job)
end

--- Looks a buffer up by its exact name. `vim.fn.bufnr()` treats its argument as a Vim
--- regex, so it would happily return the "dev:api" terminal when asked for "dev".
--- @param name string
--- @return integer|nil
local function find_buf_by_name(name)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) == name then
      return buf
    end
  end
  return nil
end

local function start_terminal(argv, opts)
  local bufnr = vim.api.nvim_create_buf(true, false)
  open_window(bufnr)
  vim.api.nvim_win_set_buf(0, bufnr)
  vim.api.nvim_buf_call(bufnr, function()
    vim.fn.jobstart(argv, { term = true, cwd = opts.cwd })
  end)
  pcall(vim.api.nvim_buf_set_name, bufnr, M.terminal_buf_name(opts.root, opts.script))
  return bufnr
end

--- @param argv string[]
--- @param opts table { cwd, root, script }
function M.run_terminal(argv, opts)
  local name = M.terminal_buf_name(opts.root, opts.script)
  local existing = find_buf_by_name(name)

  if not existing then
    start_terminal(argv, opts)
    return
  end

  if not job_alive(existing) then
    vim.api.nvim_buf_delete(existing, { force = true })
    start_terminal(argv, opts)
    return
  end

  vim.ui.select({ "Show window", "Restart" }, {
    prompt = string.format("%s is already running", opts.script),
  }, function(choice)
    if choice == "Restart" then
      vim.api.nvim_buf_delete(existing, { force = true })
      start_terminal(argv, opts)
    elseif choice == "Show window" then
      local win = vim.fn.bufwinid(existing)
      if win ~= -1 then
        vim.api.nvim_set_current_win(win)
      else
        open_window(existing)
        vim.api.nvim_win_set_buf(0, existing)
      end
    end
  end)
end

return M
