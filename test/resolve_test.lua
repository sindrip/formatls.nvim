local h = require("test.helpers")
h.setup()

local pipeline = require("formatls.pipeline")

h.test("textDocument/formatting resolves to lsp step", function()
  local steps = pipeline.resolve_group({ { "textDocument/formatting" } }, "/tmp")
  h.assert_eq(#steps, 1)
  h.assert_eq(steps[1].kind, "lsp")
  h.assert_eq(steps[1].action, "textDocument/formatting")
end)

h.test("source.organizeImports resolves to lsp step", function()
  local steps = pipeline.resolve_group({ { "source.organizeImports" } }, "/tmp")
  h.assert_eq(#steps, 1)
  h.assert_eq(steps[1].kind, "lsp")
  h.assert_eq(steps[1].action, "source.organizeImports")
end)

h.test("mixed source actions and textDocument/formatting", function()
  local steps = pipeline.resolve_group({ { "source.organizeImports", "textDocument/formatting" } }, "/tmp")
  h.assert_eq(#steps, 2)
  h.assert_eq(steps[1].kind, "lsp")
  h.assert_eq(steps[2].kind, "lsp")
  h.assert_eq(steps[2].action, "textDocument/formatting")
end)

h.test("unavailable CLI falls back to next group", function()
  local steps = pipeline.resolve_group({
    { "nonexistent_formatter" },
    { "textDocument/formatting" },
  }, "/tmp")
  h.assert_eq(#steps, 1)
  h.assert_eq(steps[1].kind, "lsp")
end)

h.test("all groups unavailable returns nil", function()
  local steps = pipeline.resolve_group({
    { "nonexistent_a" },
    { "nonexistent_b" },
  }, "/tmp")
  h.assert_eq(steps, nil)
end)

h.test("empty groups returns nil", function()
  local steps = pipeline.resolve_group({}, "/tmp")
  h.assert_eq(steps, nil)
end)

h.test("CLI available via add_spec", function()
  pipeline.add_spec("test_fmt", {
    cmd = "cat",
    args = function()
      return {}
    end,
  })
  local steps = pipeline.resolve_group({ { "test_fmt" } }, "/tmp")
  h.assert_eq(#steps, 1)
  h.assert_eq(steps[1].kind, "cli")
end)

h.test("table-form step with server field", function()
  local steps = pipeline.resolve_group({
    { { "source.organizeImports", server = "gopls" }, "textDocument/formatting" },
  }, "/tmp")
  h.assert_eq(#steps, 2)
  h.assert_eq(steps[1].kind, "lsp")
  h.assert_eq(steps[1].server, "gopls")
  h.assert_eq(steps[2].kind, "lsp")
  h.assert_eq(steps[2].server, nil)
end)

h.test("table-form step with condition", function()
  local steps = pipeline.resolve_group({
    { {
      "source.organizeImports",
      condition = function()
        return true
      end,
    } },
  }, "/tmp")
  h.assert_eq(#steps, 1)
  h.assert_eq(type(steps[1].condition), "function")
end)

h.done()
