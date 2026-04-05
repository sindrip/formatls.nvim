return {
  meta = {
    url = "https://github.com/mantoni/eslint_d.js/",
    description = "Like ESLint, but faster.",
  },
  cmd = "eslint_d",
  args = function(path)
    return { "--fix-to-stdout", "--stdin", "--stdin-filename", path }
  end,
}
