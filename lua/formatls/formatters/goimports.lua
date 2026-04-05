return {
  meta = {
    url = "https://pkg.go.dev/golang.org/x/tools/cmd/goimports",
    description = "Updates your Go import lines, adding missing ones and removing unreferenced ones.",
  },
  cmd = "goimports",
  args = function(path)
    return { "-srcdir", vim.fn.fnamemodify(path, ":h") }
  end,
}
