describe("pnpm adapter", function()
  local pnpm

  before_each(function()
    package.loaded["neonpm.manager.pnpm"] = nil
    pnpm = require("neonpm.manager.pnpm")
  end)

  it("declares its metadata", function()
    assert.equals("pnpm", pnpm.name)
    assert.same({ "pnpm-lock.yaml" }, pnpm.lockfiles)
  end)

  it("install", function()
    assert.same({ "pnpm", "install" }, pnpm.build({ op = "install" }))
  end)

  it("add with -D and -E", function()
    assert.same(
      { "pnpm", "add", "-D", "-E", "vitest" },
      pnpm.build({ op = "add", pkgs = { "vitest" }, dev = true, exact = true })
    )
  end)

  it("add globally", function()
    assert.same({ "pnpm", "add", "-g", "tsx" }, pnpm.build({ op = "add", pkgs = { "tsx" }, global = true }))
  end)

  it("remove", function()
    assert.same({ "pnpm", "remove", "lodash" }, pnpm.build({ op = "remove", pkgs = { "lodash" } }))
  end)

  it("update", function()
    assert.same({ "pnpm", "update" }, pnpm.build({ op = "update" }))
  end)

  it("run passes arguments without a separator", function()
    assert.same(
      { "pnpm", "run", "dev", "--port", "3000" },
      pnpm.build({ op = "run", script = "dev", args = { "--port", "3000" } })
    )
  end)
end)
