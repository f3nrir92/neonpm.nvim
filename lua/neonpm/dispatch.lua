local commands = require("neonpm.commands")
local manager = require("neonpm.manager")
local notify = require("neonpm.ui.notify")
local picker = require("neonpm.ui.picker")
local project = require("neonpm.project")
local registry = require("neonpm.registry")

local M = {}

--- @param bufnr integer|nil
--- @return table|nil, string|nil
function M.context(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local info, err = project.resolve(bufnr)
  if not info then
    return nil, err
  end

  local bound, detect_err = manager.detect(info.root)
  if not bound then
    return nil, detect_err
  end

  return { root = info.root, pkg = info.pkg, manager = bound, bufnr = bufnr }
end

local function pick_child(node, ctx, argv)
  local items = {}
  for _, child in ipairs(registry.children(node)) do
    table.insert(items, { label = string.format("%s — %s", child.name, child.desc), value = child.name })
  end

  picker.pick(items, { prompt = node.name }, function(value)
    if not value then
      return
    end
    local next_argv = vim.list_extend(vim.deepcopy(argv), { value })
    M.execute({ fargs = next_argv }, ctx)
  end)
end

--- @param cmd_opts table the table from nvim_create_user_command
--- @param reuse_ctx table|nil prebuilt context (used when recursing from the picker)
function M.execute(cmd_opts, reuse_ctx)
  commands.ensure()

  local argv = cmd_opts.fargs or {}
  local node, rest = registry.resolve(argv)

  if node == registry.root() and #rest > 0 then
    notify.error(string.format("unknown command %q", rest[1]))
    return
  end

  local ctx = reuse_ctx
  if not ctx then
    local err
    ctx, err = M.context()
    if not ctx then
      notify.error(err)
      return
    end
  end

  if node.run and #rest > 0 then
    node.run(ctx, rest)
    return
  end

  if node.children and #node.children > 0 and #rest == 0 and not node.run then
    local consumed = {}
    for i = 1, #argv - #rest do
      table.insert(consumed, argv[i])
    end
    pick_child(node, ctx, consumed)
    return
  end

  if node.run then
    node.run(ctx, rest)
    return
  end

  notify.error(string.format("command %q does nothing", node.name))
end

--- @param arg_lead string
--- @param cmd_line string
--- @param _cursor_pos integer
--- @return string[]
function M.complete(arg_lead, cmd_line, _cursor_pos)
  commands.ensure()

  local words = vim.split(vim.trim(cmd_line), "%s+")
  table.remove(words, 1) -- drop "NeoNpm"
  if arg_lead ~= "" and words[#words] == arg_lead then
    table.remove(words)
  end

  local node = registry.resolve(words)

  if node.children and #node.children > 0 then
    local names = {}
    for _, child in ipairs(registry.children(node)) do
      if arg_lead == "" or child.name:sub(1, #arg_lead) == arg_lead then
        table.insert(names, child.name)
      end
    end
    if #names > 0 then
      return names
    end
  end

  if node.complete then
    local ctx = M.context()
    if not ctx then
      return {}
    end
    return node.complete(ctx, arg_lead) or {}
  end

  return {}
end

return M
