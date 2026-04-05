return {
  meta = {
    url = "https://github.com/JohnnyMorganz/StyLua",
    description = "An opinionated code formatter for Lua.",
  },
  cmd = "stylua",
  args = function(path)
    return {
      "--search-parent-directories",
      "--respect-ignores",
      "--stdin-filepath",
      path,
      "-",
    }
  end,
}
