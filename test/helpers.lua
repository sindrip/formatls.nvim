local M = {}

local passed = 0
local failed = 0
local current_test = ""

function M.test(name, fn)
  current_test = name
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    print("  PASS  " .. name)
  else
    failed = failed + 1
    print("  FAIL  " .. name)
    print("        " .. err)
  end
end

function M.assert_eq(actual, expected, msg)
  if not vim.deep_equal(actual, expected) then
    local info = msg and (msg .. "\n        ") or ""
    error(
      info
        .. "expected: "
        .. vim.inspect(expected, { newline = " ", indent = "" })
        .. "\n        actual:   "
        .. vim.inspect(actual, { newline = " ", indent = "" }),
      2
    )
  end
end

function M.setup()
  vim.opt.runtimepath:prepend(vim.uv.cwd())
end

function M.done()
  print(string.format("\n%d passed, %d failed", passed, failed))
  os.exit(failed > 0 and 1 or 0)
end

return M
