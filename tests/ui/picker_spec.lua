local helpers = require("tests.helpers")

describe("neonpm.ui.picker", function()
  local picker, config, original

  before_each(function()
    helpers.reload()
    picker = require("neonpm.ui.picker")
    config = require("neonpm.config")
    config.reset()
    original = vim.ui.select
  end)

  after_each(function()
    vim.ui.select = original
  end)

  it("the select backend is always available", function()
    config.setup({ ui = { picker = "select" } })
    assert.equals("select", picker.select_backend().name)
  end)

  it("falls back to select when no backend is installed", function()
    config.setup({ ui = { picker_order = { "telescope", "snacks", "fzf_lua", "mini", "select" } } })
    local backend = picker.select_backend()
    assert.is_true(backend.is_available())
  end)

  it("pick returns the value of the chosen item", function()
    config.setup({ ui = { picker = "select" } })
    local shown
    vim.ui.select = function(items, opts, on_choice)
      shown = { items = items, prompt = opts.prompt, format = opts.format_item }
      on_choice(items[2])
    end

    local chosen
    picker.pick({
      { label = "install — install dependencies", value = "install" },
      { label = "run — run a script", value = "run" },
    }, { prompt = "NeoNpm" }, function(value)
      chosen = value
    end)

    assert.equals("run", chosen)
    assert.equals("NeoNpm", shown.prompt)
    assert.equals("install — install dependencies", shown.format(shown.items[1]))
  end)

  it("pick calls back with nil when cancelled", function()
    config.setup({ ui = { picker = "select" } })
    vim.ui.select = function(_, _, on_choice)
      on_choice(nil)
    end

    local called, chosen = false, "sentinel"
    picker.pick({ { label = "a", value = "a" } }, {}, function(value)
      called = true
      chosen = value
    end)

    assert.is_true(called)
    assert.is_nil(chosen)
  end)

  it("pick does not call the backend for an empty list", function()
    config.setup({ ui = { picker = "select" } })
    local touched = false
    vim.ui.select = function()
      touched = true
    end

    local chosen = "sentinel"
    picker.pick({}, {}, function(value)
      chosen = value
    end)

    assert.is_false(touched)
    assert.is_nil(chosen)
  end)
end)
