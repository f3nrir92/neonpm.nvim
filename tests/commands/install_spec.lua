local helpers = require("tests.helpers")

describe("install and update commands", function()
  local install, update, runner, calls, real_executable

  local function ctx_for(manager_name)
    local manager = require("neonpm.manager")
    return {
      root = "/tmp/project",
      pkg = { name = "demo" },
      manager = manager.bind(manager.get(manager_name), {}, "test"),
      bufnr = 0,
    }
  end

  before_each(function()
    helpers.reload()
    install = require("neonpm.commands.install")
    update = require("neonpm.commands.update")
    runner = require("neonpm.runner")
    calls = {}
    runner.system = function(argv, opts, _)
      table.insert(calls, { argv = argv, cwd = opts.cwd })
      return { pid = 1 }
    end
    -- The test must not depend on which managers are installed on the machine.
    real_executable = vim.fn.executable
    vim.fn.executable = function()
      return 1
    end
  end)

  after_each(function()
    vim.fn.executable = real_executable
  end)

  it("the install node is declared correctly", function()
    assert.equals("install", install.name)
    assert.is_string(install.desc)
    assert.is_function(install.run)
  end)

  it("install without arguments installs everything from the lockfile", function()
    install.run(ctx_for("pnpm"), {})
    assert.same({ "pnpm", "install" }, calls[1].argv)
    assert.equals("/tmp/project", calls[1].cwd)
  end)

  it("install with a package adds a dependency", function()
    install.run(ctx_for("pnpm"), { "lodash" })
    assert.same({ "pnpm", "add", "lodash" }, calls[1].argv)
  end)

  it("install with -D adds a dev dependency", function()
    install.run(ctx_for("npm"), { "vitest", "-D" })
    assert.same({ "npm", "install", "--save-dev", "vitest" }, calls[1].argv)
  end)

  it("update runs the update", function()
    update.run(ctx_for("bun"), {})
    assert.same({ "bun", "update" }, calls[1].argv)
  end)
end)
