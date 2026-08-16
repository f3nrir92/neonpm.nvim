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

--- Builds a stdout/stderr sink that accumulates raw chunks and hands whole lines
--- to `on_line`. Chunks arrive on read boundaries, not line boundaries, so the
--- tail of an unfinished line is carried over to the next chunk.
--- @param chunks string[] accumulator for the complete output
--- @param on_line function(line: string)
--- @return function(err: string|nil, data: string|nil)
local function line_sink(chunks, on_line)
  local partial = ""
  return function(_, data)
    if data == nil then
      return
    end
    table.insert(chunks, data)
    partial = partial .. data

    local from = 1
    while true do
      local newline = partial:find("\n", from, true)
      if not newline then
        break
      end
      local line = (partial:sub(from, newline - 1):gsub("\r$", ""))
      from = newline + 1
      if line ~= "" then
        vim.schedule(function()
          on_line(line)
        end)
      end
    end
    partial = partial:sub(from)
  end
end

--- @param argv string[]
--- @param opts table { cwd, root, on_output = function(line)|nil, quiet = boolean|nil }
--- @param on_done function|nil
--- @return boolean, string|nil
function M.run_async(argv, opts, on_done)
  local root = opts.root or opts.cwd
  if busy[root] then
    return false, string.format("already running in this project: %s", table.concat(busy[root], " "))
  end
  busy[root] = argv

  -- Streaming and buffering are mutually exclusive in vim.system: passing stdout
  -- and stderr callbacks means `result` carries no output, so we accumulate it here
  -- to keep the log buffer complete either way.
  local streaming = type(opts.on_output) == "function"
  local out_chunks, err_chunks = {}, {}
  local system_opts = { cwd = opts.cwd }

  if streaming then
    system_opts.stdout = line_sink(out_chunks, opts.on_output)
    system_opts.stderr = line_sink(err_chunks, opts.on_output)
  else
    system_opts.text = true
  end

  local ok, err = pcall(M.system, argv, system_opts, function(result)
    vim.schedule(function()
      busy[root] = nil
      local stdout = streaming and table.concat(out_chunks) or result.stdout
      local stderr = streaming and table.concat(err_chunks) or result.stderr
      log.append({
        argv = argv,
        cwd = opts.cwd,
        code = result.code,
        stdout = stdout,
        stderr = stderr,
      })
      if log.should_open(config.get().log.auto_open, result.code) then
        log.open()
      end
      if result.code == 0 then
        if not opts.quiet then
          notify.info(string.format("%s — done", table.concat(argv, " ")))
        end
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
