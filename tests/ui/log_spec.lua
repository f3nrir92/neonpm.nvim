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

  it("strips cursor hide/show codes", function()
    assert.equals("text", log.strip_ansi("\27[?25ltext"))
    assert.equals("text", log.strip_ansi("\27[?25htext"))
  end)

  it("strips OSC sequences terminated by BEL", function()
    assert.equals("hello", log.strip_ansi("\27]8;;http://example.com\7hello"))
  end)

  it("strips OSC sequences terminated by ST (ESC backslash)", function()
    -- OSC 8 hyperlink format: OSC 8 ; ; URL ST text OSC 8 ; ; ST
    local input = "\27]8;;http://example.com\27\\link text\27]8;;\27\\"
    assert.equals("link text", log.strip_ansi(input))
  end)

  it("handles mixed OSC terminators, ST then BEL, without text loss", function()
    -- ST-terminated hyperlink followed by BEL-terminated title
    local input = "\27]8;;http://x\27\\hello\27]0;title\7world"
    assert.equals("helloworld", log.strip_ansi(input))
  end)

  it("handles mixed OSC terminators, BEL then ST, without text loss", function()
    -- BEL-terminated title followed by ST-terminated hyperlink
    local input = "\27]0;title\7keep\27]8;;http://x\27\\tail"
    assert.equals("keeptail", log.strip_ansi(input))
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

  it("append preserves modifiable = false even on error", function()
    local bufnr = log.bufnr()
    -- Stub vim.api.nvim_buf_set_lines to raise an error during the protected window
    local original_set_lines = vim.api.nvim_buf_set_lines
    vim.api.nvim_buf_set_lines = function() -- luacheck: ignore 122
      error("simulated buffer write failure", 2)
    end
    -- Call append with a valid entry; the error occurs inside pcall
    local ok = (
      pcall(function()
        log.append({ argv = { "npm", "install" }, cwd = "/tmp", code = 0, stdout = "output" })
      end)
    )
    -- Restore the original function
    vim.api.nvim_buf_set_lines = original_set_lines -- luacheck: ignore 122
    -- Verify: the call errored and modifiable was restored to false
    assert.is_false(ok)
    assert.is_false(vim.bo[bufnr].modifiable)
  end)
end)
