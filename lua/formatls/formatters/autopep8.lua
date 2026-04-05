return {
  meta = {
    url = "https://github.com/hhatto/autopep8",
    description = "Automatically formats Python code to conform to the PEP 8 style guide.",
  },
  cmd = "autopep8",
  args = function()
    return { "-" }
  end,
}
