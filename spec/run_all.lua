-- Entrypoint for the Auto-9 Assistive Reticule test suite.
--
--   cd "<...>/mods/Auto-9 Assistive Reticule"
--   luajit spec/run_all.lua
--
-- Requires only standalone LuaJIT; nothing is loaded from the game.

package.path = "./?.lua;" .. package.path

local engine = require("spec.mock_engine")
engine.MOD_ROOT = "."

local runner = require("spec.runner")

local SPECS = {
	"spec.parse_spec",
	"spec.stance_spec",
	"spec.target_spec",
	"spec.project_spec",
	"spec.sequence_spec",
	"spec.settings_lint_spec",
	"spec.scanner_spec",
	"spec.credits_names_spec",
	"spec.tag_spec",
	"spec.exec_stance_spec",
	"spec.mark_sources_spec",
	"spec.mark_capture_spec",
	"spec.mark_hooks_spec",
	"spec.keyword_stance_spec",
}

for _, name in ipairs(SPECS) do
	local ok, spec = pcall(require, name)
	if not ok then
		print("\n!! could not load " .. name .. ": " .. tostring(spec))
		os.exit(1)
	end
	spec()
end

os.exit(runner.report() and 0 or 1)
