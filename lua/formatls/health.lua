local M = {}

function M.check()
  vim.health.start("formatls")

  if vim.fn.has("nvim-0.12") ~= 1 then
    vim.health.error("Neovim 0.12+ required")
  else
    vim.health.ok("Neovim " .. tostring(vim.version()))
  end

  local clients = vim.lsp.get_clients({ name = "formatls" })
  if #clients == 0 then
    vim.health.warn("formatls is not attached to any buffer")
    return
  end
  vim.health.ok("formatls attached (" .. #clients .. " client(s))")

  local client = clients[1]
  local opts = client.config.init_options or {}
  local formatters_by_ft = opts.formatters_by_ft or {}
  local pipeline = require("formatls.pipeline")

  local seen = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.lsp.buf_is_attached(bufnr, client.id) then
      local ft = vim.bo[bufnr].filetype
      local filepath = vim.api.nvim_buf_get_name(bufnr)
      local dirname = vim.fn.fnamemodify(filepath, ":h")
      local key = ft .. ":" .. dirname

      if not seen[key] and formatters_by_ft[ft] then
        seen[key] = true
        local steps = pipeline.resolve_group(formatters_by_ft[ft], dirname)
        local label = filepath .. " [" .. ft .. "]"
        if steps then
          local names = {}
          for _, step in ipairs(steps) do
            names[#names + 1] = step.name
          end
          vim.health.ok(label .. ": " .. table.concat(names, " → "))
        else
          vim.health.warn(label .. ": no viable group")
        end
      end
    end
  end
end

return M
