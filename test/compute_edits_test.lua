local h = require("test.helpers")
h.setup()

local pipeline = require("formatls.pipeline")

h.test("no changes produces no edits", function()
  local edits = pipeline.compute_edits("hello\nworld\n", "hello\nworld\n")
  h.assert_eq(edits, {})
end)

h.test("single line change", function()
  local edits = pipeline.compute_edits("hello\n", "goodbye\n")
  h.assert_eq(#edits, 1)
  h.assert_eq(edits[1].range.start.line, 0)
  h.assert_eq(edits[1].newText, "goodbye\n")
end)

h.test("insert line", function()
  local edits = pipeline.compute_edits("a\nc\n", "a\nb\nc\n")
  h.assert_eq(#edits, 1)
  h.assert_eq(edits[1].newText, "b\n")
end)

h.test("delete line", function()
  local edits = pipeline.compute_edits("a\nb\nc\n", "a\nc\n")
  h.assert_eq(#edits, 1)
  h.assert_eq(edits[1].newText, "")
end)

h.test("multiple changes", function()
  local old = "a\nb\nc\nd\ne\n"
  local new = "A\nb\nC\nd\nE\n"
  local edits = pipeline.compute_edits(old, new)
  h.assert_eq(#edits, 3)
end)

h.done()
