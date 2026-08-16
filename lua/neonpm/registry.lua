local M = {}

local root

function M.reset()
  root = { name = "NeoNpm", desc = "Node.js package manager commands", children = {} }
end

M.reset()

function M.root()
  return root
end

local function find_child(parent, name)
  for _, child in ipairs(parent.children or {}) do
    if child.name == name then
      return child
    end
  end
  return nil
end

function M.register(node, path)
  assert(type(node) == "table" and type(node.name) == "string", "neonpm: node must have a name")
  assert(type(node.desc) == "string", "neonpm: node must have a desc")

  local parent = root
  for _, name in ipairs(path or {}) do
    local next_parent = find_child(parent, name)
    if not next_parent then
      error(string.format("neonpm: parent %q not found", name), 2)
    end
    parent = next_parent
  end

  if find_child(parent, node.name) then
    error(string.format("neonpm: command %q is already registered", node.name), 2)
  end

  parent.children = parent.children or {}
  table.insert(parent.children, node)
end

function M.resolve(argv)
  local node = root
  local index = 1
  while argv[index] do
    local child = find_child(node, argv[index])
    if not child then
      break
    end
    node = child
    index = index + 1
  end

  local rest = {}
  for i = index, #argv do
    table.insert(rest, argv[i])
  end
  return node, rest
end

function M.children(node)
  local list = vim.deepcopy(node.children or {}, true)
  table.sort(list, function(a, b)
    return a.name < b.name
  end)
  return list
end

return M
