return {
  meta = {
    url = "https://github.com/psf/black",
    description = "The uncompromising Python code formatter.",
  },
  cmd = "black",
  args = function(path)
    return { "--stdin-filename", path, "--quiet", "-" }
  end,
  -- https://black.readthedocs.io/en/stable/usage_and_configuration/the_basics.html#configuration-via-a-file
  config_files = { "pyproject.toml" },
}
