return {
  meta = {
    url = "https://github.com/PyCQA/isort",
    description = "Sort Python imports alphabetically and automatically separate them into sections.",
  },
  cmd = "isort",
  args = function(path)
    return { "--stdout", "--filename", path, "-" }
  end,
  -- https://pycqa.github.io/isort/docs/configuration/config_files.html
  config_files = {
    ".isort.cfg",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "tox.ini",
  },
}
