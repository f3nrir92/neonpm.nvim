local helpers = require("tests.helpers")

describe("neonpm.runner", function()
  local runner

  before_each(function()
    helpers.reload()
    runner = require("neonpm.runner")
  end)

  --- vim.system stub: records the call and lets the test finish it manually.
  local function fake_system(collector)
    return function(argv, opts, on_exit)
      table.insert(collector, {
        argv = argv,
        cwd = opts.cwd,
        finish = function(result)
          on_exit(result)
        end,
      })
      return { pid = 1234 }
    end
  end

  it("passes argv and cwd to vim.system", function()
    local calls = {}
    runner.system = fake_system(calls)

    local ok = runner.run_async({ "npm", "install" }, { cwd = "/tmp/project", root = "/tmp/project" })
    assert.is_true(ok)
    assert.same({ "npm", "install" }, calls[1].argv)
    assert.equals("/tmp/project", calls[1].cwd)
  end)

  it("calls on_done with the exit code and output", function()
    local calls = {}
    runner.system = fake_system(calls)

    local seen
    runner.run_async({ "npm", "install" }, { cwd = "/tmp", root = "/tmp" }, function(result)
      seen = result
    end)
    calls[1].finish({ code = 0, stdout = "added 1 package", stderr = "" })
    vim.wait(200, function()
      return seen ~= nil
    end)

    assert.equals(0, seen.code)
    assert.equals("added 1 package", seen.stdout)
  end)

  it("holds the lock on the root while a command runs", function()
    local calls = {}
    runner.system = fake_system(calls)

    runner.run_async({ "npm", "install" }, { cwd = "/tmp", root = "/tmp" })
    assert.is_true(runner.is_busy("/tmp"))

    local ok, err = runner.run_async({ "npm", "update" }, { cwd = "/tmp", root = "/tmp" })
    assert.is_false(ok)
    assert.is_string(err)
    assert.equals(1, #calls)
  end)

  it("releases the lock once the command finishes", function()
    local calls = {}
    runner.system = fake_system(calls)

    runner.run_async({ "npm", "install" }, { cwd = "/tmp", root = "/tmp" })
    calls[1].finish({ code = 0, stdout = "", stderr = "" })
    vim.wait(200, function()
      return not runner.is_busy("/tmp")
    end)

    assert.is_false(runner.is_busy("/tmp"))
  end)

  it("the lock is per root", function()
    local calls = {}
    runner.system = fake_system(calls)

    runner.run_async({ "npm", "install" }, { cwd = "/a", root = "/a" })
    local ok = runner.run_async({ "npm", "install" }, { cwd = "/b", root = "/b" })
    assert.is_true(ok)
  end)

  it("builds the terminal buffer name from root and script", function()
    local name = runner.terminal_buf_name("/home/user/app", "dev")
    assert.equals("neonpm://run/home/user/app/dev", name)
  end)

  it("clears the lock and reports the error when vim.system raises synchronously", function()
    runner.system = function()
      error("spawn failed")
    end

    local ok, err = runner.run_async({ "npm", "install" }, { cwd = "/tmp", root = "/tmp" })

    assert.is_false(ok)
    assert.is_string(err)
    assert.is_false(runner.is_busy("/tmp"))
  end)

  describe("run_terminal buffer creation", function()
    local config
    local original_jobstart

    before_each(function()
      config = require("neonpm.config")
      original_jobstart = vim.fn.jobstart
      vim.fn.jobstart = function()
        return 1
      end
    end)

    after_each(function()
      vim.fn.jobstart = original_jobstart
      config.reset()
    end)

    local function count_new_buffers(before, after)
      local before_set = {}
      for _, b in ipairs(before) do
        before_set[b] = true
      end
      local new_count = 0
      for _, b in ipairs(after) do
        if not before_set[b] then
          new_count = new_count + 1
        end
      end
      return new_count
    end

    it("creates exactly one buffer in float mode", function()
      config.setup({ run = { win = "float" } })
      local before = vim.api.nvim_list_bufs()

      runner.run_terminal({ "npm", "run", "dev" }, { cwd = "/tmp", root = "/tmp", script = "dev-float" })

      local after = vim.api.nvim_list_bufs()
      assert.equals(1, count_new_buffers(before, after))
    end)

    it("creates exactly one buffer in split mode", function()
      config.setup({ run = { win = "split" } })
      local before = vim.api.nvim_list_bufs()

      runner.run_terminal({ "npm", "run", "dev" }, { cwd = "/tmp", root = "/tmp", script = "dev-split" })

      local after = vim.api.nvim_list_bufs()
      assert.equals(1, count_new_buffers(before, after))
    end)
  end)
end)
