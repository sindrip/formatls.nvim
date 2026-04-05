local h = require("test.helpers")
h.setup()

local pipeline = require("formatls.pipeline")

local cwd = vim.uv.cwd()

local function read_fixture(name)
  local path = cwd .. "/test/fixtures/" .. name
  return path, table.concat(vim.fn.readfile(path), "\n") .. "\n"
end

local function test_formatter(name, fixture, opts)
  h.test(name .. " formats " .. fixture, function()
    local spec = require("formatls.formatters." .. name)
    if vim.fn.executable(spec.cmd) ~= 1 then
      print("        SKIP (" .. spec.cmd .. " not found)")
      return
    end

    local filepath, content = read_fixture(fixture)
    local dirname = vim.fn.fnamemodify(filepath, ":h")
    local arg_path = opts and opts.tmppath and vim.fn.tempname() .. "." .. vim.fn.fnamemodify(filepath, ":e")
      or filepath
    local cmd = { spec.cmd, unpack(spec.args(arg_path)) }
    local output, err = pipeline.run_cmd(cmd, content, dirname)
    assert(output, err)
    assert(output ~= content, name .. " did not change the file")
  end)
end

-- JS/TS
test_formatter("prettier", "messy.ts")
test_formatter("prettierd", "messy.ts")
test_formatter("eslint_d", "messy.js")
test_formatter("biome", "messy.ts")
test_formatter("deno_fmt", "messy.ts")

-- Go
test_formatter("gofmt", "messy.go")
test_formatter("goimports", "messy.go")
test_formatter("gofumpt", "messy.go")
test_formatter("golines", "messy.go")

-- Python
test_formatter("black", "messy.py")
test_formatter("autopep8", "messy.py")
test_formatter("isort", "messy.py")
test_formatter("ruff_format", "messy.py")

-- Lua
test_formatter("stylua", "messy.lua", { tmppath = true })

h.done()
