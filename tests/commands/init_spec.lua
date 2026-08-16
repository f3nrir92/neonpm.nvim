local helpers = require("tests.helpers")

describe("neonpm.commands registration", function()
  local commands, registry, notifications, restore_notify

  before_each(function()
    helpers.reload()
    notifications, restore_notify = helpers.capture_notify()
    commands = require("neonpm.commands")
    registry = require("neonpm.registry")
    registry.reset()
  end)

  after_each(function()
    package.preload["neonpm.commands.run"] = nil
    restore_notify()
  end)

  it("registers the four built-in commands", function()
    commands.ensure()
    assert.equals(4, #registry.root().children)
  end)

  it("is idempotent when called repeatedly", function()
    commands.ensure()
    commands.ensure()
    assert.equals(4, #registry.root().children)
  end)

  it("is idempotent after the module alone is reloaded", function()
    commands.ensure()

    -- What ":Lazy reload" and plugin developers do: drop this module but keep the
    -- registry, which still holds the tree.
    package.loaded["neonpm.commands"] = nil
    local reloaded = require("neonpm.commands")

    assert.has_no.errors(function()
      reloaded.ensure()
    end)
    assert.equals(4, #registry.root().children)
  end)

  it("re-registers after the registry is reset", function()
    commands.ensure()
    registry.reset()
    commands.ensure()
    assert.equals(4, #registry.root().children)
  end)

  it("reports a command module that fails to load", function()
    package.loaded["neonpm.commands.run"] = nil
    package.preload["neonpm.commands.run"] = function()
      error("boom")
    end

    commands.ensure()

    assert.equals(3, #registry.root().children)
    assert.equals(1, #notifications)
    assert.equals(vim.log.levels.ERROR, notifications[1].level)
    assert.is_truthy(notifications[1].msg:find("run", 1, true))
    assert.is_truthy(notifications[1].msg:find("boom", 1, true))
  end)
end)
