local helpers = require("tests.helpers")

describe("neonpm.commands.util", function()
  local cmdutil, notifications, restore_notify

  before_each(function()
    helpers.reload()
    notifications, restore_notify = helpers.capture_notify()
    cmdutil = require("neonpm.commands.util")
  end)

  after_each(function()
    restore_notify()
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

  describe("exec", function()
    local runner, calls, real_executable

    local function ctx_for(root)
      local manager = require("neonpm.manager")
      return {
        root = root,
        pkg = { name = "demo" },
        manager = manager.bind(manager.get("npm"), {}, "test"),
        bufnr = 0,
      }
    end

    before_each(function()
      runner = require("neonpm.runner")
      calls = {}
      runner.system = function(argv, opts, on_exit)
        table.insert(calls, { argv = argv, cwd = opts.cwd, finish = on_exit, system_opts = opts })
        return { pid = 1 }
      end
      real_executable = vim.fn.executable
      vim.fn.executable = function()
        return 1
      end
    end)

    after_each(function()
      vim.fn.executable = real_executable
    end)

    --- Replaces the progress module's seams with a recording fake backend.
    local function fake_progress(active)
      local progress = require("neonpm.ui.progress")
      local record = { started = nil, reported = {}, finished = nil }
      progress.is_active = function()
        return active
      end
      progress.start = function(opts)
        record.started = opts
        return {
          report = function(_, line)
            table.insert(record.reported, line)
          end,
          finish = function(_, ok, message)
            record.finished = { ok = ok, message = message }
          end,
        }
      end
      return record, progress
    end

    local function count_info()
      local n = 0
      for _, entry in ipairs(notifications) do
        if entry.level == vim.log.levels.INFO then
          n = n + 1
        end
      end
      return n
    end

    it("asks the runner to stream when detail is output", function()
      local record, progress = fake_progress(true)
      progress.wants_output = function()
        return true
      end

      cmdutil.exec(ctx_for("/tmp/p1"), { op = "install" })

      assert.equals("npm install", record.started.title)
      assert.is_function(calls[1].system_opts.stdout)
    end)

    it("keeps the buffered path in spinner mode", function()
      local _, progress = fake_progress(true)
      progress.wants_output = function()
        return false
      end

      cmdutil.exec(ctx_for("/tmp/p2"), { op = "install" })

      assert.is_nil(calls[1].system_opts.stdout)
      assert.is_true(calls[1].system_opts.text)
    end)

    it("routes streamed lines into the handle", function()
      local record, progress = fake_progress(true)
      progress.wants_output = function()
        return true
      end

      cmdutil.exec(ctx_for("/tmp/p3"), { op = "install" })
      calls[1].system_opts.stdout(nil, "resolving deps\n")
      vim.wait(200, function()
        return #record.reported > 0
      end)

      assert.same({ "resolving deps" }, record.reported)
    end)

    it("says nothing through notify while an indicator is showing the same thing", function()
      fake_progress(true)

      cmdutil.exec(ctx_for("/tmp/p4"), { op = "install" })
      calls[1].finish({ code = 0, stdout = "", stderr = "" })
      vim.wait(200, function()
        return not require("neonpm.runner").is_busy("/tmp/p4")
      end)

      assert.equals(0, count_info())
    end)

    it("keeps both notifications when no indicator is active", function()
      fake_progress(false)

      cmdutil.exec(ctx_for("/tmp/p5"), { op = "install" })
      calls[1].finish({ code = 0, stdout = "", stderr = "" })
      vim.wait(200, function()
        return not require("neonpm.runner").is_busy("/tmp/p5")
      end)

      assert.equals(2, count_info())
    end)

    it("finishes the handle with the command's outcome", function()
      local record = fake_progress(true)

      cmdutil.exec(ctx_for("/tmp/p6"), { op = "install" })
      calls[1].finish({ code = 0, stdout = "", stderr = "" })
      vim.wait(200, function()
        return record.finished ~= nil
      end)
      assert.is_true(record.finished.ok)

      local failing = fake_progress(true)
      cmdutil.exec(ctx_for("/tmp/p7"), { op = "install" })
      calls[2].finish({ code = 1, stdout = "", stderr = "" })
      vim.wait(200, function()
        return failing.finished ~= nil
      end)
      assert.is_false(failing.finished.ok)
    end)

    it("clears the project and manager caches once the command succeeds", function()
      local root = vim.fn.tempname()
      vim.fn.mkdir(root, "p")
      finally(function()
        vim.fn.delete(root, "rf")
      end)
      local path = vim.fs.joinpath(root, "package.json")

      local function write_package(body)
        local fd = assert(io.open(path, "w"))
        fd:write(body)
        fd:close()
      end

      local project = require("neonpm.project")
      local manager = require("neonpm.manager")
      write_package('{ "dependencies": {} }')
      assert.same({}, project.read_package(root).dependencies)
      assert.equals("npm", manager.detect(root).name)

      -- The subprocess rewrites package.json and drops a lockfile behind Neovim's
      -- back: no BufWritePost fires for either.
      assert.is_true(cmdutil.exec(ctx_for(root), { op = "add", pkgs = { "lodash" } }))
      write_package('{ "dependencies": { "lodash": "^4" } }')
      local lock = assert(io.open(vim.fs.joinpath(root, "pnpm-lock.yaml"), "w"))
      lock:write("lockfileVersion: 9.0\n")
      lock:close()

      calls[1].finish({ code = 0, stdout = "", stderr = "" })
      local cleared = vim.wait(500, function()
        return project.read_package(root).dependencies.lodash ~= nil
      end)

      assert.is_true(cleared)
      assert.equals("pnpm", manager.detect(root).name)
    end)

    it("reports an adapter build error without spawning anything", function()
      local ok, err = cmdutil.exec(ctx_for("/tmp/project"), { op = "add", pkgs = {} })

      assert.is_false(ok)
      assert.equals("npm: no package given", err)
      assert.equals(0, #calls)
      assert.equals("neonpm: " .. err, notifications[#notifications].msg)
      assert.equals(vim.log.levels.ERROR, notifications[#notifications].level)
    end)

    it("reports a missing binary without spawning anything", function()
      vim.fn.executable = function()
        return 0
      end

      local ok, err = cmdutil.exec(ctx_for("/tmp/project"), { op = "install" })

      assert.is_false(ok)
      assert.equals("npm not found in $PATH", err)
      assert.equals(0, #calls)
      assert.equals("neonpm: " .. err, notifications[#notifications].msg)
      assert.equals(vim.log.levels.ERROR, notifications[#notifications].level)
    end)
  end)
end)
