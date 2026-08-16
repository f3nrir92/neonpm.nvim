describe("neonpm.config", function()
  local config

  before_each(function()
    package.loaded["neonpm.config"] = nil
    config = require("neonpm.config")
  end)

  it("returns defaults before setup()", function()
    local opts = config.get()
    assert.equals("error", opts.log.auto_open)
    assert.equals("split", opts.run.win)
    assert.is_nil(opts.manager)
    assert.same({ "package.json" }, opts.root.patterns)
    assert.equals("telescope", opts.ui.picker_order[1])
    assert.equals("select", opts.ui.picker_order[#opts.ui.picker_order])
  end)

  it("merges user options with defaults", function()
    config.setup({ run = { win = "float" } })
    assert.equals("float", config.get().run.win)
    assert.equals("error", config.get().log.auto_open)
  end)

  it("errors on an unknown top-level key", function()
    assert.has_error(function()
      config.setup({ nope = true })
    end)
  end)

  it("errors on an unknown manager", function()
    assert.has_error(function()
      config.setup({ manager = "cargo" })
    end)
  end)

  it("errors on an invalid log.auto_open", function()
    assert.has_error(function()
      config.setup({ log = { auto_open = "sometimes" } })
    end)
  end)

  it("reset() restores defaults", function()
    config.setup({ notify = false })
    config.reset()
    assert.is_true(config.get().notify)
  end)
end)
