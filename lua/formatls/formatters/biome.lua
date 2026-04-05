return {
  meta = {
    url = "https://biomejs.dev/reference/cli/#biome-format",
    description = "A toolchain for web projects. Runs formatting only.",
  },
  cmd = "biome",
  args = function(path)
    return {
      "format",
      "--stdin-file-path",
      path,
    }
  end,
  config_files = {
    "biome.json",
    "biome.jsonc",
  },
}
