return {
  cmd = "biome",
  args = function(path)
    return {
      "format",
      "--stdin-file-path",
      path,
    }
  end,
  range_args = function(path, range_start, range_end)
    return {
      "format",
      "--stdin-file-path",
      path,
      "--range",
      range_start .. "-" .. range_end,
    }
  end,
  config_files = {
    "biome.json",
    "biome.jsonc",
  },
}
