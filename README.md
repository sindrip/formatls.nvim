# formatls.nvim

[![CI](https://github.com/sindrip/formatls.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/sindrip/formatls.nvim/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

An in-process LSP formatting server for Neovim. Runs as a native LSP client — no external binary needed.

Supports CLI formatters (biome, prettier, stylua), LSP code actions (organize imports), and chaining multiple steps in a pipeline. Automatically resolves local `node_modules/.bin` binaries and detects config files.

Requires Neovim 0.12+.

## Install

With vim.pack:

```lua
vim.pack.add("https://github.com/sindrip/formatls.nvim")
```

With lazy.nvim:

```lua
{ "sindrip/formatls.nvim" }
```

## Setup

```lua
vim.lsp.config("formatls", {
  init_options = {
    formatters_by_ft = {
      typescript = {
        -- try biome first
        { "biome" },
        -- fall back to organize imports + prettier
        { "source.organizeImports", "prettier" },
      },
      go = {
        -- organize imports + format via gopls
        { "source.organizeImports", "textDocument/formatting" },
      },
      lua = {
        { "stylua" },
      },
    },
  },
})

vim.lsp.enable("formatls")
```

Then format with `vim.lsp.buf.format()` or your preferred keymap.

## How it works

formatls registers as an LSP server that advertises `documentFormattingProvider`. It proxies formatting capabilities from other LSP servers on the buffer so that all format requests go through formatls.

### `formatters_by_ft`

Each filetype maps to a list of **groups**. Groups are tried in order — the first group where all CLI formatters are available is used.

A group is a list of steps, executed sequentially:

| Step | Description |
|---|---|
| `"biome"`, `"prettier"`, `"stylua"` | CLI formatter — resolved via spec |
| `"source.organizeImports"`, `"source.fixAll"` | LSP code action — sent via `textDocument/codeAction` |
| `"textDocument/formatting"` | LSP formatting — delegated to a server's formatter |

### CLI formatter resolution

For each CLI formatter, formatls:

1. Looks up the formatter spec by name (e.g. `require("formatls.formatters.biome")`)
2. Searches for a local binary in `node_modules/.bin/` (walking up the directory tree)
3. Falls back to a global binary on `$PATH`
4. Checks for required config files (e.g. `biome.json` for biome)

If any step fails, the group is skipped and the next group is tried.

### Fallback

When no groups are configured for a filetype (or none are viable), formatls delegates directly to the original LSP server's formatter.

## Custom formatters

Define custom formatter specs inline:

```lua
vim.lsp.config("formatls", {
  init_options = {
    formatters = {
      my_formatter = {
        cmd = "my-formatter",
        args = function(path)
          return { "--stdin-filepath", path }
        end,
        -- optional: required config files (skip if none found)
        config_files = { ".my-formatter.json" },
      },
    },
    formatters_by_ft = {
      python = {
        { "my_formatter" },
      },
    },
  },
})
```

## Alternatives

- [conform.nvim](https://github.com/stevearc/conform.nvim) — a more mature formatting plugin with a large collection of built-in formatter definitions. The built-in formatter specs in formatls are based on the hard work done by conform and its maintainers.
