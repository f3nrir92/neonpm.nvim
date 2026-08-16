describe("yarn adapter", function()
  local yarn

  before_each(function()
    package.loaded["neonpm.manager.yarn"] = nil
    yarn = require("neonpm.manager.yarn")
  end)

  it("declares its metadata", function()
    assert.equals("yarn", yarn.name)
    assert.same({ "yarn.lock" }, yarn.lockfiles)
  end)

  it("install is identical in v1 and berry", function()
    assert.same({ "yarn", "install" }, yarn.build({ op = "install" }, { berry = false }))
    assert.same({ "yarn", "install" }, yarn.build({ op = "install" }, { berry = true }))
  end)

  it("add with -D and -E", function()
    assert.same(
      { "yarn", "add", "-D", "-E", "vitest" },
      yarn.build({ op = "add", pkgs = { "vitest" }, dev = true, exact = true }, { berry = false })
    )
  end)

  it("v1: update maps to upgrade", function()
    assert.same({ "yarn", "upgrade" }, yarn.build({ op = "update" }, { berry = false }))
  end)

  it("berry: update maps to up", function()
    assert.same({ "yarn", "up" }, yarn.build({ op = "update" }, { berry = true }))
  end)

  it("v1: global install uses yarn global add", function()
    assert.same(
      { "yarn", "global", "add", "tsx" },
      yarn.build({ op = "add", pkgs = { "tsx" }, global = true }, { berry = false })
    )
  end)

  it("berry: global operations are not supported", function()
    local argv, err = yarn.build({ op = "add", pkgs = { "tsx" }, global = true }, { berry = true })
    assert.is_nil(argv)
    assert.is_string(err)
  end)

  it("remove", function()
    assert.same({ "yarn", "remove", "lodash" }, yarn.build({ op = "remove", pkgs = { "lodash" } }, {}))
  end)

  it("run passes arguments without a separator", function()
    assert.same(
      { "yarn", "run", "dev", "--port", "3000" },
      yarn.build({ op = "run", script = "dev", args = { "--port", "3000" } }, {})
    )
  end)
end)
