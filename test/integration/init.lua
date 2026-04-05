-- Integration test config for NVIM_APPNAME=formatls-test
-- Installs all formatters via mason, then runs formatter_test.lua

vim.pack.add({
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
})

require("mason").setup()
require("mason-tool-installer").setup({
  ensure_installed = {
    "prettier",
    "prettierd",
    "eslint_d",
    "biome",
    "deno",
    "gofumpt",
    "goimports",
    "golines",
    "black",
    "autopep8",
    "isort",
    "ruff",
    "stylua",
  },
  run_on_start = false,
})

-- Install synchronously
require("mason-tool-installer").check_install(true, true)
