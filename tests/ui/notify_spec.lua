local helpers = require("tests.helpers")

describe("neonpm.ui.notify", function()
  local notify, config, original, captured

  before_each(function()
    helpers.reload()
    notify = require("neonpm.ui.notify")
    config = require("neonpm.config")
    config.reset()
    captured = {}
    original = vim.notify
    vim.notify = function(msg, level)
      table.insert(captured, { msg = msg, level = level })
    end
  end)

  after_each(function()
    vim.notify = original
  end)

  it("prefixes messages with the plugin name", function()
    notify.info("done")
    assert.equals(1, #captured)
    assert.equals("neonpm: done", captured[1].msg)
    assert.equals(vim.log.levels.INFO, captured[1].level)
  end)

  it("stays silent when notify = false", function()
    config.setup({ notify = false })
    notify.info("done")
    assert.equals(0, #captured)
  end)

  it("errors are shown even when notify = false", function()
    config.setup({ notify = false })
    notify.error("something broke")
    assert.equals(1, #captured)
    assert.equals(vim.log.levels.ERROR, captured[1].level)
  end)
end)
