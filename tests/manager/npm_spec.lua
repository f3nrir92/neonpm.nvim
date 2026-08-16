describe("npm adapter", function()
  local npm

  before_each(function()
    package.loaded["neonpm.manager.npm"] = nil
    npm = require("neonpm.manager.npm")
  end)

  it("declares its metadata", function()
    assert.equals("npm", npm.name)
    assert.equals("npm", npm.bin)
    assert.same({ "package-lock.json" }, npm.lockfiles)
  end)

  it("install without packages", function()
    assert.same({ "npm", "install" }, npm.build({ op = "install" }))
  end)

  it("add to dependencies", function()
    assert.same({ "npm", "install", "lodash" }, npm.build({ op = "add", pkgs = { "lodash" } }))
  end)

  it("add to devDependencies", function()
    assert.same(
      { "npm", "install", "--save-dev", "lodash" },
      npm.build({ op = "add", pkgs = { "lodash" }, dev = true })
    )
  end)

  it("add with an exact version, globally", function()
    assert.same(
      { "npm", "install", "--global", "--save-exact", "tsx" },
      npm.build({ op = "add", pkgs = { "tsx" }, global = true, exact = true })
    )
  end)

  it("remove", function()
    assert.same({ "npm", "uninstall", "lodash", "dayjs" }, npm.build({ op = "remove", pkgs = { "lodash", "dayjs" } }))
  end)

  it("update", function()
    assert.same({ "npm", "update" }, npm.build({ op = "update" }))
  end)

  it("run without script arguments", function()
    assert.same({ "npm", "run", "dev" }, npm.build({ op = "run", script = "dev" }))
  end)

  it("run separates arguments with --", function()
    assert.same(
      { "npm", "run", "dev", "--", "--port", "3000" },
      npm.build({ op = "run", script = "dev", args = { "--port", "3000" } })
    )
  end)

  it("errors on an unknown operation", function()
    local argv, err = npm.build({ op = "teleport" })
    assert.is_nil(argv)
    assert.is_string(err)
  end)

  it("requires at least one package for add", function()
    local argv, err = npm.build({ op = "add", pkgs = {} })
    assert.is_nil(argv)
    assert.is_string(err)
  end)
end)
