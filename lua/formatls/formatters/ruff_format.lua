return {
  meta = {
    url = "https://docs.astral.sh/ruff/",
    description = "An extremely fast Python linter and formatter, written in Rust.",
  },
  cmd = "ruff",
  args = function(path)
    return { "format", "--force-exclude", "--stdin-filename", path, "-" }
  end,
  config_files = {
    "pyproject.toml",
    "ruff.toml",
    ".ruff.toml",
  },
}
