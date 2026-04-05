local h = require("test.helpers")
h.setup()

local pipeline = require("formatls.pipeline")

h.test("gopls pattern: organizeImports then formatting", function()
  local call_log = {}

  local steps = {
    { kind = "lsp", name = "source.organizeImports", action = "source.organizeImports" },
    { kind = "lsp", name = "textDocument/formatting", action = "textDocument/formatting" },
  }

  local result = pipeline.run_pipeline(steps, {
    filepath = "/tmp/test.go",
    dirname = "/tmp",
    get_lsp_edits = function()
      call_log[#call_log + 1] = "format"
      return nil
    end,
    exec_action = function(action_kind, content)
      call_log[#call_log + 1] = action_kind
      return content .. "-- organized\n"
    end,
  }, "package main\n")

  h.assert_eq(call_log, { "source.organizeImports", "format" })
  h.assert_eq(result, "package main\n-- organized\n")
end)

h.test("cli runs before action when configured first", function()
  local call_log = {}

  local steps = {
    {
      kind = "cli",
      name = "cat",
      args = function()
        return {}
      end,
      cmd = "cat",
    },
    { kind = "lsp", name = "source.organizeImports", action = "source.organizeImports" },
  }

  local result = pipeline.run_pipeline(steps, {
    filepath = "/tmp/test.ts",
    dirname = "/tmp",
    get_lsp_edits = function()
      return nil
    end,
    exec_action = function(action_kind, content)
      call_log[#call_log + 1] = "cli"
      call_log[#call_log + 1] = action_kind
      return content
    end,
  }, "hello\n")

  h.assert_eq(call_log, { "cli", "source.organizeImports" })
  h.assert_eq(result, "hello\n")
end)

h.test("pipeline returns nil when cli fails after action", function()
  local action_ran = false

  local steps = {
    { kind = "lsp", name = "source.organizeImports", action = "source.organizeImports" },
    {
      kind = "cli",
      name = "false",
      args = function()
        return {}
      end,
      cmd = "false",
    },
  }

  local result = pipeline.run_pipeline(steps, {
    filepath = "/tmp/test.go",
    dirname = "/tmp",
    get_lsp_edits = function()
      return nil
    end,
    exec_action = function(action_kind, content)
      action_ran = true
      return content .. "-- organized\n"
    end,
  }, "package main\n")

  h.assert_eq(result, nil)
  h.assert_eq(action_ran, true)
end)

h.test("action steps skipped when exec_action not provided", function()
  local steps = {
    { kind = "lsp", name = "source.organizeImports", action = "source.organizeImports" },
  }

  local result = pipeline.run_pipeline(steps, {
    filepath = "/tmp/test.go",
    dirname = "/tmp",
    get_lsp_edits = function()
      return nil
    end,
  }, "hello\n")

  h.assert_eq(result, "hello\n")
end)

h.test("condition false skips step", function()
  local action_ran = false
  local steps = {
    {
      kind = "lsp",
      name = "source.organizeImports",
      action = "source.organizeImports",
      condition = function()
        return false
      end,
    },
  }

  local result = pipeline.run_pipeline(steps, {
    filepath = "/tmp/test.go",
    dirname = "/tmp",
    get_lsp_edits = function()
      return nil
    end,
    exec_action = function(_, content)
      action_ran = true
      return content
    end,
  }, "hello\n")

  h.assert_eq(action_ran, false)
  h.assert_eq(result, "hello\n")
end)

h.test("condition true runs step", function()
  local action_ran = false
  local steps = {
    {
      kind = "lsp",
      name = "source.organizeImports",
      action = "source.organizeImports",
      condition = function()
        return true
      end,
    },
  }

  pipeline.run_pipeline(steps, {
    filepath = "/tmp/test.go",
    dirname = "/tmp",
    get_lsp_edits = function()
      return nil
    end,
    exec_action = function(_, content)
      action_ran = true
      return content
    end,
  }, "hello\n")

  h.assert_eq(action_ran, true)
end)

h.test("server name reaches exec_action", function()
  local received_server = nil
  local steps = {
    {
      kind = "lsp",
      name = "source.organizeImports",
      action = "source.organizeImports",
      server = "gopls",
    },
  }

  pipeline.run_pipeline(steps, {
    filepath = "/tmp/test.go",
    dirname = "/tmp",
    get_lsp_edits = function()
      return nil
    end,
    exec_action = function(_, content, server)
      received_server = server
      return content
    end,
  }, "hello\n")

  h.assert_eq(received_server, "gopls")
end)

h.test("server name reaches get_lsp_edits", function()
  local received_server = nil
  local steps = {
    {
      kind = "lsp",
      name = "textDocument/formatting",
      action = "textDocument/formatting",
      server = "gopls",
    },
  }

  pipeline.run_pipeline(steps, {
    filepath = "/tmp/test.go",
    dirname = "/tmp",
    get_lsp_edits = function(server)
      received_server = server
      return nil
    end,
  }, "hello\n")

  h.assert_eq(received_server, "gopls")
end)

h.done()
