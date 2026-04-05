local h = require("test.helpers")
h.setup()

local pipeline = require("formatls.pipeline")

h.test("stylua formats messy lua file", function()
  if vim.fn.executable("stylua") ~= 1 then
    print("        SKIP (stylua not found)")
    return
  end

  local fixture = vim.uv.cwd() .. "/test/fixtures/messy.lua"
  local content = table.concat(vim.fn.readfile(fixture), "\n") .. "\n"

  local output, err = pipeline.run_cmd(
    { "stylua", "--search-parent-directories", "--stdin-filepath", fixture, "-" },
    content,
    vim.uv.cwd()
  )
  assert(output, err)

  -- stylua should fix formatting — output should differ from input
  assert(output ~= content, "stylua did not change the file")

  -- verify the output is valid lua
  local fn, load_err = loadstring(output)
  assert(fn, "stylua output is not valid lua: " .. (load_err or ""))
end)

h.test("compute_edits + apply_text_edits roundtrip (modify)", function()
  local old = "local x = 1\nlocal y = 2\nlocal z = 3\n"
  local new = "local x = 1\nlocal Y = 99\nlocal z = 3\n"

  local edits = pipeline.compute_edits(old, new)
  local result = pipeline.apply_text_edits(old, edits)

  h.assert_eq(result, new)
end)

h.test("compute_edits + apply_text_edits roundtrip (delete)", function()
  local old = "a\nb\nc\nd\n"
  local new = "a\nd\n"

  local edits = pipeline.compute_edits(old, new)
  local result = pipeline.apply_text_edits(old, edits)

  h.assert_eq(result, new)
end)

h.test("compute_edits + apply_text_edits roundtrip (insert)", function()
  local old = "a\nc\n"
  local new = "a\nb\nc\n"

  local edits = pipeline.compute_edits(old, new)
  local result = pipeline.apply_text_edits(old, edits)

  h.assert_eq(result, new)
end)

h.test("run_cmd returns nil on failure", function()
  local output, err = pipeline.run_cmd({ "false" }, "", "/tmp")
  h.assert_eq(output, nil)
  assert(err, "expected error message")
end)

h.test("run_pipeline with cli step", function()
  if vim.fn.executable("cat") ~= 1 then
    print("        SKIP (cat not found)")
    return
  end

  pipeline.add_spec("echo_fmt", {
    cmd = "cat",
    args = function()
      return {}
    end,
  })

  local steps = {
    {
      kind = "cli",
      name = "cat",
      args = function()
        return {}
      end,
      cmd = "cat",
    },
  }
  local result = pipeline.run_pipeline(steps, {
    filepath = "/tmp/test.lua",
    dirname = "/tmp",
    get_lsp_edits = function()
      return nil
    end,
  }, "hello\n")

  h.assert_eq(result, "hello\n")
end)

h.done()
