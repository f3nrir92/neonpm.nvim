local helpers = require("tests.helpers")

describe("neonpm.commands.util", function()
  local cmdutil

  before_each(function()
    helpers.reload()
    cmdutil = require("neonpm.commands.util")
  end)

  it("separates packages from flags", function()
    local pkgs, flags = cmdutil.parse_args({ "lodash", "-D", "dayjs" })
    assert.same({ "lodash", "dayjs" }, pkgs)
    assert.is_true(flags.dev)
    assert.is_false(flags.global)
  end)

  it("understands long flag forms", function()
    local _, flags = cmdutil.parse_args({ "--save-dev", "--global", "--save-exact" })
    assert.is_true(flags.dev)
    assert.is_true(flags.global)
    assert.is_true(flags.exact)
  end)

  it("unrecognised flags stay positional", function()
    local pkgs = cmdutil.parse_args({ "--port", "3000" })
    assert.same({ "--port", "3000" }, pkgs)
  end)

  it("collects dependencies from package.json", function()
    local pkg = {
      dependencies = { lodash = "^4", axios = "^1" },
      devDependencies = { vitest = "^1" },
    }
    assert.same({ "axios", "lodash", "vitest" }, cmdutil.dependencies(pkg))
  end)

  it("collects scripts from package.json", function()
    assert.same({ "build", "dev" }, cmdutil.scripts({ scripts = { dev = "vite", build = "vite build" } }))
  end)

  it("returns empty lists for a package.json without those sections", function()
    assert.same({}, cmdutil.dependencies({}))
    assert.same({}, cmdutil.scripts({}))
  end)
end)
