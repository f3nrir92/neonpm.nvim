local M = {}

local BUF_NAME = "neonpm://log"
local bufnr = nil

--- @param s string
--- @return string
function M.strip_ansi(s)
  if not s or s == "" then
    return ""
  end
  -- CSI sequences: ESC [ followed by optional params (digits, semicolons, or ?) then a letter
  s = s:gsub("\27%[[?%d;]*[%a]", "")
  -- OSC sequences: ESC ] followed by content terminated by BEL (^G)
  s = s:gsub("\27%][^\7]*\7", "")
  -- OSC sequences: ESC ] followed by content terminated by ST (ESC \)
  s = s:gsub("\27%].-\27\\", "")
  -- Carriage returns
  s = s:gsub("\r", "")
  return s
end

--- @param mode string "error"|"always"|"never"
--- @param code integer
--- @return boolean
function M.should_open(mode, code)
  if mode == "always" then
    return true
  end
  if mode == "error" then
    return code ~= 0
  end
  return false
end

--- @return integer
function M.bufnr()
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    return bufnr
  end
  -- Try to find an existing buffer with our name
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) == BUF_NAME then
      bufnr = buf
      return bufnr
    end
  end
  bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, BUF_NAME)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].modifiable = false
  return bufnr
end

local function split_lines(text)
  local lines = {}
  for line in (M.strip_ansi(text) .. "\n"):gmatch("([^\n]*)\n") do
    table.insert(lines, line)
  end
  -- the gmatch above yields a trailing empty line — drop it
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

--- @param entry table { argv, cwd, code, stdout, stderr }
function M.append(entry)
  local buf = M.bufnr()
  local lines = {
    string.format("── %s  %s", os.date("%H:%M:%S"), table.concat(entry.argv or {}, " ")),
    string.format("   cwd: %s", entry.cwd or "?"),
  }
  if entry.code ~= nil then
    table.insert(lines, string.format("   exit: %d", entry.code))
  end
  for _, line in ipairs(split_lines(entry.stdout or "")) do
    table.insert(lines, line)
  end
  for _, line in ipairs(split_lines(entry.stderr or "")) do
    table.insert(lines, line)
  end
  table.insert(lines, "")

  vim.bo[buf].modifiable = true
  local ok, err = pcall(function()
    local existing = vim.api.nvim_buf_line_count(buf)
    local start = (existing == 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "") and 0 or existing
    vim.api.nvim_buf_set_lines(buf, start, -1, false, lines)
  end)
  vim.bo[buf].modifiable = false
  if not ok then
    error(err, 2)
  end
end

function M.open()
  local buf = M.bufnr()
  local win = vim.fn.bufwinid(buf)
  if win ~= -1 then
    vim.api.nvim_set_current_win(win)
    return
  end
  vim.cmd.split()
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(buf), 0 })
end

return M
