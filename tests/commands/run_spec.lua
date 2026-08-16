local helpers = require("tests.helpers")

describe("run command", function()
  local run_cmd, runner, picker, terminal_calls, real_executable, restore_notify

  local function ctx()
    local manager = require("neonpm.manager")
    return {
      root = "/tmp/project",
      pkg = { scripts = { dev = "vite", build = "vite build" } },
      manager = manager.bind(manager.get("pnpm"), {}, "test"),
      bufnr = 0,
    }
  end

  before_each(function()
    helpers.reload()
    restore_notify = select(2, helpers.capture_notify())
    run_cmd = require("neonpm.commands.run")
    runner = require("neonpm.runner")
    picker = require("neonpm.ui.picker")
    terminal_calls = {}
    runner.run_terminal = function(argv, opts)
      table.insert(terminal_calls, { argv = argv, opts = opts })
    end
    real_executable = vim.fn.executable
    vim.fn.executable = function()
      return 1
    end
  end)

  after_each(function()
    vim.fn.executable = real_executable
    restore_notify()
  end)

  it("the node is declared correctly", function()
    assert.equals("run", run_cmd.name)
    assert.is_function(run_cmd.complete)
  end)

  it("runs a script in the terminal", function()
    run_cmd.run(ctx(), { "dev" })
    assert.same({ "pnpm", "run", "dev" }, terminal_calls[1].argv)
    assert.equals("/tmp/project", terminal_calls[1].opts.cwd)
    assert.equals("dev", terminal_calls[1].opts.script)
  end)

  it("passes the trailing arguments to the script", function()
    run_cmd.run(ctx(), { "dev", "--port", "3000" })
    assert.same({ "pnpm", "run", "dev", "--port", "3000" }, terminal_calls[1].argv)
  end)

  it("without arguments it shows a picker of scripts", function()
    local shown
    picker.pick = function(items, _, on_choice)
      shown = items
      on_choice(items[2].value)
    end

    run_cmd.run(ctx(), {})

    assert.equals(2, #shown)
    assert.equals("build — vite build", shown[1].label)
    assert.same({ "pnpm", "run", "dev" }, terminal_calls[1].argv)
  end)

  it("cancelling the picker runs nothing", function()
    picker.pick = function(_, _, on_choice)
      on_choice(nil)
    end
    run_cmd.run(ctx(), {})
    assert.equals(0, #terminal_calls)
  end)

  it("reports when there are no scripts", function()
    local empty = ctx()
    empty.pkg = { scripts = {} }
    run_cmd.run(empty, {})
    assert.equals(0, #terminal_calls)
  end)

  it("complete returns script names", function()
    assert.same({ "build", "dev" }, run_cmd.complete(ctx(), ""))
  end)
end)
