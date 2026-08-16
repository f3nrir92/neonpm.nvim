describe("bun adapter", function()
  local bun

  before_each(function()
    package.loaded["neonpm.manager.bun"] = nil
    bun = require("neonpm.manager.bun")
  end)

  it("declares metadata and both lockfile variants", function()
    assert.equals("bun", bun.name)
    assert.same({ "bun.lock", "bun.lockb" }, bun.lockfiles)
  end)

  it("install", function()
    assert.same({ "bun", "install" }, bun.build({ op = "install" }))
  end)

  it("add to devDependencies uses -d", function()
    assert.same({ "bun", "add", "-d", "vitest" }, bun.build({ op = "add", pkgs = { "vitest" }, dev = true }))
  end)

  it("add with an exact version", function()
    assert.same({ "bun", "add", "--exact", "tsx" }, bun.build({ op = "add", pkgs = { "tsx" }, exact = true }))
  end)

  it("remove", function()
    assert.same({ "bun", "remove", "lodash" }, bun.build({ op = "remove", pkgs = { "lodash" } }))
  end)

  it("update", function()
    assert.same({ "bun", "update" }, bun.build({ op = "update" }))
  end)

  it("run passes arguments without a separator", function()
    assert.same(
      { "bun", "run", "dev", "--port", "3000" },
      bun.build({ op = "run", script = "dev", args = { "--port", "3000" } })
    )
  end)
end)
