local helpers = require("tests.helpers")

describe("neonpm.ui.progress", function()
  local progress, config

  before_each(function()
    helpers.reload()
    progress = require("neonpm.ui.progress")
    config = require("neonpm.config")
    config.reset()
  end)

  it("selects the off backend when the config asks for it", function()
    config.setup({ progress = { backend = "off" } })
    assert.equals("off", progress.select_backend().name)
  end)

  -- fidget is not on the runtimepath under the test harness, so autodetection
  -- must land on the null backend rather than erroring.
  it("falls back to the off backend when fidget is unavailable", function()
    local backend = progress.select_backend()
    assert.equals("off", backend.name)
  end)

  it("falls back to off when a named backend is not installed", function()
    config.setup({ progress = { backend = "fidget" } })
    assert.equals("off", progress.select_backend().name)
  end)

  it("start() returns a handle whose methods are safe to call", function()
    local handle = progress.start({ title = "pnpm add lodash" })
    assert.is_function(handle.report)
    assert.is_function(handle.finish)
    handle:report("resolving")
    handle:finish(true, "done")
  end)

  it("a finished handle ignores further reports", function()
    local handle = progress.start({ title = "npm install" })
    handle:finish(false, "exit code 1")
    handle:report("late line")
    handle:finish(true, "double finish")
  end)

  it("is_active() is false while the null backend is the one selected", function()
    assert.is_false(progress.is_active())
    config.setup({ progress = { backend = "off" } })
    assert.is_false(progress.is_active())
  end)

  it("wants_output() is true only when detail is output", function()
    assert.is_false(progress.wants_output())
    config.setup({ progress = { detail = "output" } })
    assert.is_true(progress.wants_output())
  end)
end)
