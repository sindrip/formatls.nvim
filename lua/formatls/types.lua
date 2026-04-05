---@module "formatls.types"

---@class formatls.Step
---@field kind "cli"|"lsp"
---@field name string
---@field action? string                        -- lsp: the code action kind or LSP method
---@field server? string                        -- lsp: filter by client name
---@field cmd? string                           -- cli: resolved binary path
---@field args? fun(path: string): string[]     -- cli: argument builder
---@field condition? fun(bufnr: integer): boolean

---@class formatls.FormatterSpec
---@field cmd string
---@field args fun(path: string): string[]
---@field config_files? string[]
---@field meta? { url: string, description: string }

---@class formatls.ProxyEntry
---@field name string
---@field client_id integer
---@field can_format boolean
---@field can_range_format boolean

---@class formatls.PipelineContext
---@field filepath string
---@field dirname string
---@field get_lsp_edits fun(server?: string): lsp.TextEdit[]?
---@field exec_action? fun(action_kind: string, content: string, server?: string): string

---User-facing config: either a string shorthand or a table with overrides.
---@alias formatls.StepInput string | formatls.StepTableInput

---@class formatls.StepTableInput
---@field [1] string                            -- name: "biome", "source.organizeImports", etc.
---@field server? string                        -- pin to a specific LSP client
---@field condition? fun(bufnr: integer): boolean
