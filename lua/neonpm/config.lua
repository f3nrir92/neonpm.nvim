local M = {}

M.defaults = {
  manager = nil,
  root = { patterns = { "package.json" } },
  ui = {
    picker = nil,
    picker_order = { "telescope", "snacks", "fzf_lua", "mini", "select" },
  },
  log = { auto_open = "error" },
  run = { win = "split" },
  notify = true,
}

local MANAGERS = { npm = true, pnpm = true, yarn = true, bun = true }
local AUTO_OPEN = { error = true, always = true, never = true }
local WINS = { split = true, vsplit = true, tab = true, float = true }

local options = vim.deepcopy(M.defaults)
local gen = 0

local function err(msg)
  error("neonpm: " .. msg, 2)
end

local function validate(opts)
  for key in pairs(opts) do
    if M.defaults[key] == nil and key ~= "manager" then
      err(string.format("unknown option %q", tostring(key)))
    end
  end
  if opts.manager ~= nil and not MANAGERS[opts.manager] then
    err(string.format("manager: expected npm|pnpm|yarn|bun, got %q", tostring(opts.manager)))
  end
  if opts.log and opts.log.auto_open ~= nil and not AUTO_OPEN[opts.log.auto_open] then
    err(string.format("log.auto_open: expected error|always|never, got %q", tostring(opts.log.auto_open)))
  end
  if opts.run and opts.run.win ~= nil and not WINS[opts.run.win] then
    err(string.format("run.win: expected split|vsplit|tab|float, got %q", tostring(opts.run.win)))
  end
  if opts.ui and opts.ui.picker ~= nil and type(opts.ui.picker) ~= "string" then
    err("ui.picker: expected a string or nil")
  end
end

function M.setup(opts)
  opts = opts or {}
  if type(opts) ~= "table" then
    err("setup() expects a table")
  end
  validate(opts)
  options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)
  gen = gen + 1
end

function M.get()
  return options
end

function M.reset()
  options = vim.deepcopy(M.defaults)
  gen = gen + 1
end

--- Increments on every setup() or reset(); callers can use this to invalidate
--- caches that depend on configuration without config requiring them back.
--- @return integer
function M.generation()
  return gen
end

return M
