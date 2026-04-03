return {
  cmd = "prettier",
  args = function(path)
    return {
      "--stdin-filepath",
      path,
    }
  end,
  range_args = function(path, range_start, range_end)
    return {
      "--stdin-filepath",
      path,
      "--range-start",
      tostring(range_start),
      "--range-end",
      tostring(range_end),
    }
  end,
  config_files = {
    ".prettierrc",
    ".prettierrc.json",
    ".prettierrc.yml",
    ".prettierrc.yaml",
    ".prettierrc.js",
    ".prettierrc.cjs",
    ".prettierrc.mjs",
    ".prettierrc.toml",
    "prettier.config.js",
    "prettier.config.cjs",
    "prettier.config.mjs",
  },
}
