local helpers = require("tests.helpers")

describe("uninstall command", function()
  local uninstall, runner, picker, calls, real_executable

  local function ctx()
    local manager = require("neonpm.manager")
    return {
      root = "/tmp/project",
      pkg = {
        dependencies = { lodash = "^4", axios = "^1" },
        devDependencies = { vitest = "^1" },
      },
      manager = manager.bind(manager.get("pnpm"), {}, "test"),
      bufnr = 0,
    }
  end

  before_each(function()
    helpers.reload()
    uninstall = require("neonpm.commands.uninstall")
    runner = require("neonpm.runner")
    picker = require("neonpm.ui.picker")
    calls = {}
    runner.system = function(argv, opts, _)
      table.insert(calls, { argv = argv, cwd = opts.cwd })
      return { pid = 1 }
    end
    real_executable = vim.fn.executable
    vim.fn.executable = function()
      return 1
    end
  end)

  after_each(function()
    vim.fn.executable = real_executable
  end)

  it("the node is declared correctly", function()
    assert.equals("uninstall", uninstall.name)
    assert.is_function(uninstall.complete)
  end)

  it("removes the package given as an argument", function()
    uninstall.run(ctx(), { "lodash" })
    assert.same({ "pnpm", "remove", "lodash" }, calls[1].argv)
  end)

  it("without arguments it shows a picker of dependencies", function()
    local shown
    picker.pick = function(items, _, on_choice)
      shown = items
      on_choice(items[1].value)
    end

    uninstall.run(ctx(), {})

    assert.equals(3, #shown)
    assert.equals("axios", shown[1].value)
    assert.same({ "pnpm", "remove", "axios" }, calls[1].argv)
  end)

  it("cancelling the picker runs nothing", function()
    picker.pick = function(_, _, on_choice)
      on_choice(nil)
    end

    uninstall.run(ctx(), {})
    assert.equals(0, #calls)
  end)

  it("complete returns dependency names", function()
    assert.same({ "axios", "lodash", "vitest" }, uninstall.complete(ctx(), ""))
  end)

  it("complete filters by prefix", function()
    assert.same({ "lodash" }, uninstall.complete(ctx(), "lo"))
  end)
end)
