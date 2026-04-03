local h = require("test.helpers")
h.setup()

local pipeline = require("formatls.pipeline")

h.test("source.format resolves to format step", function()
  local steps = pipeline.resolve_group({ { "source.format" } }, "/tmp")
  h.assert_eq(#steps, 1)
  h.assert_eq(steps[1].kind, "format")
end)

h.test("source.organizeImports resolves to action step", function()
  local steps = pipeline.resolve_group({ { "source.organizeImports" } }, "/tmp")
  h.assert_eq(#steps, 1)
  h.assert_eq(steps[1].kind, "action")
  h.assert_eq(steps[1].action, "source.organizeImports")
end)

h.test("mixed source actions and format", function()
  local steps = pipeline.resolve_group({ { "source.organizeImports", "source.format" } }, "/tmp")
  h.assert_eq(#steps, 2)
  h.assert_eq(steps[1].kind, "action")
  h.assert_eq(steps[2].kind, "format")
end)

h.test("unavailable CLI falls back to next group", function()
  local steps = pipeline.resolve_group({
    { "nonexistent_formatter" },
    { "source.format" },
  }, "/tmp")
  h.assert_eq(#steps, 1)
  h.assert_eq(steps[1].kind, "format")
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

h.done()
