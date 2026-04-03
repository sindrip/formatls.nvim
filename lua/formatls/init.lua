local Server = require("formatls.server")
local Proxy = require("formatls.proxy")
local pipeline = require("formatls.pipeline")

local function exec_action(bufnr, action_kind)
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    range = {
      start = { line = 0, character = 0 },
      ["end"] = { line = vim.api.nvim_buf_line_count(bufnr), character = 0 },
    },
    context = { only = { action_kind }, diagnostics = {} },
  }

  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/codeAction" })

  for _, client in ipairs(clients) do
    local res = client:request_sync("textDocument/codeAction", params, 5000, bufnr)
    if res and not res.err then
      for _, action in ipairs(res.result or {}) do
        if not action.edit then
          local resolved = client:request_sync("codeAction/resolve", action, 5000, bufnr)
          if resolved and resolved.result then
            action = resolved.result
          end
        end

        if action.edit then
          vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
        end
        if action.command then
          local cmds = (client.server_capabilities.executeCommandProvider or {}).commands or {}
          for _, c in ipairs(cmds) do
            if c == action.command.command then
              client:request_sync("workspace/executeCommand", action.command, 5000, bufnr)
              break
            end
          end
        end
      end
    end
  end
end

local function get_lsp_edits(proxy, bufnr, method, params)
  for _, entry in ipairs(proxy:get_formatters(bufnr)) do
    local client = vim.lsp.get_client_by_id(entry.client_id)
    if client then
      local result = client:request_sync(method, params, 5000, bufnr)
      if result and result.result and #result.result > 0 then
        return result.result
      end
    end
  end
  return nil
end

local function handle_format(self, method, params)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
  local filepath = vim.uri_to_fname(params.textDocument.uri)
  local dirname = vim.fn.fnamemodify(filepath, ":h")

  local steps = pipeline.resolve_group(self.formatters_by_ft[vim.bo[bufnr].filetype] or {}, dirname)

  local lsp_edits = function()
    return get_lsp_edits(self.proxy, bufnr, method, params)
  end

  if not steps then
    return lsp_edits() or {}
  end

  local original = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n") .. "\n"

  local final = pipeline.run_pipeline(steps, {
    filepath = filepath,
    dirname = dirname,
    get_lsp_edits = lsp_edits,
    exec_action = function(action_kind, content)
      local lines = vim.split(content, "\n", { plain = true })
      if #lines > 0 and lines[#lines] == "" then
        table.remove(lines)
      end
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      exec_action(bufnr, action_kind)
      return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n") .. "\n"
    end,
  }, original)

  if not final then
    -- Rollback buffer to original on pipeline failure
    local orig_lines = vim.split(original, "\n", { plain = true })
    if #orig_lines > 0 and orig_lines[#orig_lines] == "" then
      table.remove(orig_lines)
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, orig_lines)
    return {}
  end

  -- Compute edits from the buffer's current state (which includes any action changes)
  local current = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n") .. "\n"
  if final == current then
    return {}
  end

  return pipeline.compute_edits(current, final)
end

local M = Server.new("formatls")

M.capabilities = {
  documentFormattingProvider = true,
  documentRangeFormattingProvider = true,
  textDocumentSync = { openClose = true },
}

function M:on_init(params)
  local opts = params.initializationOptions or {}
  self.formatters_by_ft = opts.formatters_by_ft or {}
  self.notified_fts = {}
  self.proxy = Proxy.start(self.name)

  for name, spec in pairs(opts.formatters or {}) do
    pipeline.add_spec(name, spec)
  end
end

function M:on_shutdown()
  self.proxy:stop()
end

M.notifications["textDocument/didOpen"] = function(self, params)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
  local ft = vim.bo[bufnr].filetype

  if self.notified_fts[ft] then
    return
  end
  self.notified_fts[ft] = true

  local dirname = vim.fn.fnamemodify(vim.uri_to_fname(params.textDocument.uri), ":h")
  local steps = pipeline.resolve_group(self.formatters_by_ft[ft] or {}, dirname)
  if not steps then
    return
  end

  local names = {}
  for _, step in ipairs(steps) do
    names[#names + 1] = step.action or step.cmd or "lsp"
  end

  local title = table.concat(names, " | ")
  self.dispatchers.server_request("window/workDoneProgress/create", { token = self.name }, function() end)
  self.dispatchers.notification("$/progress", { token = self.name, value = { kind = "begin", title = title } })
  self.dispatchers.notification("$/progress", { token = self.name, value = { kind = "end" } })
end

M.requests["textDocument/formatting"] = function(self, params)
  return handle_format(self, "textDocument/formatting", params)
end

M.requests["textDocument/rangeFormatting"] = function(self, params)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
  return get_lsp_edits(self.proxy, bufnr, "textDocument/rangeFormatting", params) or {}
end

return M:build()
