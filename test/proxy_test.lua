local h = require("test.helpers")
h.setup()

local Proxy = require("formatls.proxy")

h.test("second buffer with same client preserves original capabilities", function()
  local proxy = Proxy.start("formatls")

  local caps = { documentFormattingProvider = true, documentRangeFormattingProvider = false }
  local client = { id = 1, name = "test_ls", server_capabilities = caps }

  proxy:add(1, client)
  proxy:add(2, client)

  local formatters = proxy:get_formatters(2)
  h.assert_eq(#formatters, 1, "second buffer should see the client as a formatter")
  h.assert_eq(formatters[1].can_format, true)

  proxy:stop()
end)

h.done()
