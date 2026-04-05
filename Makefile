test:
	nvim --headless -l test/resolve_test.lua
	nvim --headless -l test/compute_edits_test.lua
	nvim --headless -l test/format_test.lua
	nvim --headless -l test/proxy_test.lua
	nvim --headless -l test/pipeline_test.lua

NVIM_INTEGRATION = NVIM_APPNAME=formatls-test nvim --headless -u test/integration/init.lua

test-integration: test-integration-setup
	$(NVIM_INTEGRATION) -l test/formatter_test.lua

test-integration-setup:
	$(NVIM_INTEGRATION) -c "qa"

style:
	stylua --check .

.PHONY: test test-integration test-integration-setup style
