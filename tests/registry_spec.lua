describe("neonpm.registry", function()
  local registry

  before_each(function()
    package.loaded["neonpm.registry"] = nil
    registry = require("neonpm.registry")
    registry.reset()
  end)

  local function node(name)
    return { name = name, desc = "desc of " .. name, run = function() end }
  end

  it("registers a node at the root", function()
    registry.register(node("install"))
    local found, rest = registry.resolve({ "install" })
    assert.equals("install", found.name)
    assert.same({}, rest)
  end)

  it("returns the argv remainder as arguments", function()
    registry.register(node("install"))
    local found, rest = registry.resolve({ "install", "lodash", "-D" })
    assert.equals("install", found.name)
    assert.same({ "lodash", "-D" }, rest)
  end)

  it("returns the root and the whole argv for an unknown word", function()
    registry.register(node("install"))
    local found, rest = registry.resolve({ "bogus" })
    assert.equals("NeoNpm", found.name)
    assert.same({ "bogus" }, rest)
  end)

  it("returns the root for an empty argv", function()
    local found, rest = registry.resolve({})
    assert.equals("NeoNpm", found.name)
    assert.same({}, rest)
  end)

  it("supports nested nodes", function()
    registry.register({ name = "workspace", desc = "ws", children = {} })
    registry.register(node("list"), { "workspace" })
    local found, rest = registry.resolve({ "workspace", "list", "x" })
    assert.equals("list", found.name)
    assert.same({ "x" }, rest)
  end)

  it("errors on a duplicate name", function()
    registry.register(node("install"))
    assert.has_error(function()
      registry.register(node("install"))
    end)
  end)

  it("errors when the parent is missing", function()
    assert.has_error(function()
      registry.register(node("list"), { "workspace" })
    end)
  end)

  it("children() sorts by name", function()
    registry.register(node("update"))
    registry.register(node("install"))
    local names = {}
    for _, child in ipairs(registry.children(registry.root())) do
      table.insert(names, child.name)
    end
    assert.same({ "install", "update" }, names)
  end)
end)
