local M = {}

local spec_cache = {}

function M.add_spec(name, spec)
  spec_cache[name] = spec
end

local function get_spec(name)
  if spec_cache[name] == nil then
    local ok, spec = pcall(require, "formatls.formatters." .. name)
    spec_cache[name] = ok and spec or false
  end

  return spec_cache[name] or nil
end

local function has_config(config_files, dirname)
  return #vim.fs.find(config_files, { upward = true, path = dirname, limit = 1 }) > 0
end

local function resolve_cmd(cmd, dirname)
  local found = vim.fs.find("node_modules/.bin/" .. cmd, { upward = true, path = dirname })
  return found[1] or cmd
end

local function resolve_cli(name, dirname)
  local spec = get_spec(name)
  if not spec then
    return nil
  end

  local cmd = resolve_cmd(spec.cmd, dirname)
  if vim.fn.executable(cmd) ~= 1 then
    return nil
  end

  if spec.config_files and not has_config(spec.config_files, dirname) then
    return nil
  end

  return spec, cmd
end

---@param entry formatls.StepInput
---@return formatls.Step
local function normalize_step(entry)
  local raw = type(entry) == "table" and entry[1] or entry
  local overrides = type(entry) == "table" and entry or nil

  local step
  if type(raw) == "string" and (raw:match("^source%.") or raw:match("^textDocument/")) then
    step = { kind = "lsp", name = raw, action = raw }
  else
    step = { kind = "cli", name = raw }
  end

  if overrides then
    step.server = overrides.server
    step.condition = overrides.condition
  end

  return step
end

function M.resolve_group(groups, dirname)
  for _, group in ipairs(groups) do
    local steps = {}
    local viable = true

    for _, entry in ipairs(group) do
      local step = normalize_step(entry)

      if step.kind == "cli" then
        local spec, cmd = resolve_cli(step.name, dirname)
        if not spec then
          viable = false
          break
        end
        step.cmd = cmd
        step.args = spec.args
      end

      steps[#steps + 1] = step
    end

    if viable then
      return steps
    end
  end

  return nil
end

function M.run_cmd(cmd, content, cwd)
  local result = vim.system(cmd, { stdin = content, cwd = cwd }):wait(5000)

  if result.code ~= 0 then
    local name = vim.fn.fnamemodify(cmd[1], ":t")
    return nil, name .. " failed"
  end

  if not result.stdout or result.stdout == "" then
    return nil, cmd[1] .. " produced no output"
  end

  return result.stdout
end

function M.compute_edits(old, new)
  local edits = {}
  local new_lines = vim.split(new, "\n", { plain = true })

  for _, hunk in ipairs(vim.text.diff(old, new, { result_type = "indices" })) do
    local old_start, old_count, new_start, new_count = unpack(hunk)

    local replacement = {}
    for i = new_start, new_start + new_count - 1 do
      replacement[#replacement + 1] = new_lines[i]
    end

    local start_line = old_count == 0 and old_start or old_start - 1

    edits[#edits + 1] = {
      range = {
        start = { line = start_line, character = 0 },
        ["end"] = { line = start_line + old_count, character = 0 },
      },
      newText = #replacement > 0 and (table.concat(replacement, "\n") .. "\n") or "",
    }
  end

  return edits
end

function M.apply_text_edits(content, edits)
  local scratch = vim.api.nvim_create_buf(false, true)
  local lines = vim.split(content, "\n", { plain = true })
  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines)
  end
  vim.api.nvim_buf_set_lines(scratch, 0, -1, false, lines)
  vim.lsp.util.apply_text_edits(edits, scratch, "utf-16")
  local result = table.concat(vim.api.nvim_buf_get_lines(scratch, 0, -1, false), "\n") .. "\n"
  vim.api.nvim_buf_delete(scratch, { force = true })
  return result
end

function M.run_pipeline(steps, ctx, content)
  for _, step in ipairs(steps) do
    local skip = step.condition and not step.condition(vim.uri_to_bufnr(vim.uri_from_fname(ctx.filepath)))

    if not skip then
      if step.kind == "cli" then
        local output, err = M.run_cmd({ step.cmd, unpack(step.args(ctx.filepath)) }, content, ctx.dirname)
        if not output then
          vim.notify("[formatls] " .. err, vim.log.levels.WARN)
          return nil
        end
        content = output
      elseif step.kind == "lsp" then
        if step.action == "textDocument/formatting" then
          local edits = ctx.get_lsp_edits(step.server)
          if edits then
            content = M.apply_text_edits(content, edits)
          end
        elseif ctx.exec_action then
          content = ctx.exec_action(step.action, content, step.server)
        end
      end
    end
  end
  return content
end

return M
