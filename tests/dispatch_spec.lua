local helpers = require("tests.helpers")

describe("neonpm.dispatch", function()
  local dispatch, picker, runner, calls, real_executable

  before_each(function()
    helpers.reload()
    require("neonpm.config").reset()
    dispatch = require("neonpm.dispatch")
    picker = require("neonpm.ui.picker")
    runner = require("neonpm.runner")
    calls = {}
    runner.system = function(argv, opts, _)
      table.insert(calls, { argv = argv, cwd = opts.cwd })
      return { pid = 1 }
    end

    local file = vim.fs.joinpath(helpers.fixture("npm-project"), "src", "index.js")
    vim.cmd.edit(vim.fn.fnameescape(file))

    real_executable = vim.fn.executable
    vim.fn.executable = function()
      return 1
    end
  end)

  after_each(function()
    vim.fn.executable = real_executable
  end)

  it("executes a subcommand with arguments", function()
    dispatch.execute({ fargs = { "install", "lodash" } })
    assert.same({ "npm", "install", "lodash" }, calls[1].argv)
    assert.equals(helpers.fixture("npm-project"), calls[1].cwd)
  end)

  it("without arguments it shows a picker of commands", function()
    local shown
    picker.pick = function(items, _, on_choice)
      shown = items
      on_choice(nil)
    end

    dispatch.execute({ fargs = {} })

    local names = {}
    for _, item in ipairs(shown) do
      table.insert(names, item.value)
    end
    assert.same({ "install", "run", "uninstall", "update" }, names)
  end)

  it("choosing in the picker runs the selected command", function()
    picker.pick = function(items, _, on_choice)
      for _, item in ipairs(items) do
        if item.value == "update" then
          on_choice(item.value)
          return
        end
      end
    end

    dispatch.execute({ fargs = {} })
    assert.same({ "npm", "update" }, calls[1].argv)
  end)

  it("reports an error for an unknown subcommand", function()
    local errors = {}
    local original = vim.notify
    vim.notify = function(msg, level)
      table.insert(errors, { msg = msg, level = level })
    end
    finally(function()
      vim.notify = original
    end)

    dispatch.execute({ fargs = { "teleport" } })

    assert.equals(0, #calls)
    assert.equals(1, #errors)
    assert.equals(vim.log.levels.ERROR, errors[1].level)
  end)

  it("completion returns command names for empty input", function()
    local items = dispatch.complete("", "NeoNpm ", 7)
    assert.same({ "install", "run", "uninstall", "update" }, items)
  end)

  it("completion filters by prefix", function()
    assert.same({ "install" }, dispatch.complete("ins", "NeoNpm ins", 10))
  end)

  it("completion inside a command delegates to its complete", function()
    local items = dispatch.complete("", "NeoNpm run ", 11)
    assert.same({ "build", "dev" }, items)
  end)
end)
