local helpers = require("tests.helpers")

describe("neonpm.ui.log", function()
  local log

  before_each(function()
    helpers.reload()
    log = require("neonpm.ui.log")
  end)

  it("strips ANSI sequences", function()
    assert.equals("done", log.strip_ansi("\27[32mdone\27[0m"))
  end)

  it("leaves plain text untouched", function()
    assert.equals("plain text", log.strip_ansi("plain text"))
  end)

  it("should_open: error mode opens only on a non-zero code", function()
    assert.is_false(log.should_open("error", 0))
    assert.is_true(log.should_open("error", 1))
  end)

  it("should_open: always mode always opens", function()
    assert.is_true(log.should_open("always", 0))
  end)

  it("should_open: never mode never opens", function()
    assert.is_false(log.should_open("never", 1))
  end)

  it("creates a scratch buffer with the expected name", function()
    local bufnr = log.bufnr()
    assert.is_true(vim.api.nvim_buf_is_valid(bufnr))
    assert.matches("neonpm://log$", vim.api.nvim_buf_get_name(bufnr))
    assert.equals("nofile", vim.bo[bufnr].buftype)
  end)

  it("append writes the header and the output", function()
    local bufnr = log.bufnr()
    log.append({ argv = { "npm", "install" }, cwd = "/tmp/project", code = 0, stdout = "added 1 package\n" })
    local lines = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
    assert.matches("npm install", lines)
    assert.matches("/tmp/project", lines)
    assert.matches("added 1 package", lines)
  end)

  it("append reuses a single buffer", function()
    local first = log.bufnr()
    log.append({ argv = { "npm", "install" }, cwd = "/tmp", code = 0 })
    assert.equals(first, log.bufnr())
  end)
end)
