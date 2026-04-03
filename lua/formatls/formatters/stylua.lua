return {
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
  range_args = function(path, range_start, range_end)
    return {
      "--search-parent-directories",
      "--respect-ignores",
      "--stdin-filepath",
      path,
      "--range-start",
      tostring(range_start),
      "--range-end",
      tostring(range_end),
      "-",
    }
  end,
}
