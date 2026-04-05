return {
  meta = {
    url = "https://deno.land/manual/tools/formatter",
    description = "Use Deno to format TypeScript, JavaScript/JSON and markdown.",
  },
  cmd = "deno",
  args = function(path)
    local ext = vim.fn.fnamemodify(path, ":e")
    return { "fmt", "-", "--ext", ext }
  end,
}
