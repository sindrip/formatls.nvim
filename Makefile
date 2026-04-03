test:
	nvim --headless -l test/resolve_test.lua
	nvim --headless -l test/compute_edits_test.lua
	nvim --headless -l test/format_test.lua
	nvim --headless -l test/proxy_test.lua
	nvim --headless -l test/pipeline_test.lua

style:
	stylua --check .

.PHONY: test style
