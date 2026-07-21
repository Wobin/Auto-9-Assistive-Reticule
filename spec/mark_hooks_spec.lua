local runner = require("spec.runner")
local engine = require("spec.mock_engine")

-- The OutlineSystem hooks are the highest-blast-radius code in the mod: they run on EVERY
-- outline add/remove in the game, so a wrong branch here breaks vanilla tags, scans and
-- companion outlines for the whole session. These tests load the real entry point under the
-- mock and drive the recorded hook bodies directly with a spy for the vanilla function.

local ENTRY = "/scripts/mods/Auto-9 Assistive Reticule/Auto-9 Assistive Reticule.lua"

local function load_entry(settings, archetype)
	local mod = engine.install(settings or {})
	engine.set_archetype(archetype)
	dofile(engine.MOD_ROOT .. ENTRY)
	mod.refresh_settings()
	return mod
end

local function hook_for(mod, name)
	for i = 1, #mod.hooks do
		local h = mod.hooks[i]
		if h.obj == "OutlineSystem" and h.name == name then
			return h.fn
		end
	end
	return nil
end

local function spy()
	local calls = { n = 0 }
	calls.fn = function(_self, unit, outline_name)
		calls.n = calls.n + 1
		calls.unit = unit
		calls.outline_name = outline_name
	end
	return calls
end

local FAKE_SYSTEM = {}

return function()
	runner.suite("mark hooks")

	runner.it("registers both OutlineSystem hooks", function()
		local mod = load_entry({}, nil)
		runner.truthy(hook_for(mod, "add_outline"), "add_outline hook must be registered")
		runner.truthy(hook_for(mod, "remove_outline"), "remove_outline hook must be registered")
	end)

	runner.it("add_outline passes an unknown outline name straight through", function()
		local mod = load_entry({ a9_mark_arbites = true }, "adamant")
		local add = hook_for(mod, "add_outline")
		local vanilla = spy()
		local unit = {}
		add(vanilla.fn, FAKE_SYSTEM, unit, "a9_lock")
		runner.eq(vanilla.n, 1, "vanilla add_outline must still run for outlines we do not own")
		runner.eq(vanilla.outline_name, "a9_lock")
	end)

	runner.it("add_outline captures and suppresses a matching row when its toggle is on", function()
		local mod = load_entry({ a9_mark_arbites = true }, "adamant")
		local add = hook_for(mod, "add_outline")
		local vanilla = spy()
		local unit = {}
		add(vanilla.fn, FAKE_SYSTEM, unit, "adamant_mark_target")
		runner.eq(vanilla.n, 0, "vanilla outline must be suppressed when we capture")
		local row = mod.mark_sources.row_for("adamant_mark_target", "adamant")
		runner.truthy(row, "row must resolve")
		runner.truthy(mod.mark_capture.pending_set(row)[unit], "unit must be captured")
	end)

	runner.it("add_outline passes through when the row's toggle is off", function()
		local mod = load_entry({ a9_mark_arbites = false }, "adamant")
		local add = hook_for(mod, "add_outline")
		local vanilla = spy()
		local unit = {}
		add(vanilla.fn, FAKE_SYSTEM, unit, "adamant_mark_target")
		runner.eq(vanilla.n, 1, "toggle off must leave the vanilla outline alone")
		local row = mod.mark_sources.row_for("adamant_mark_target", "adamant")
		runner.falsy(mod.mark_capture.pending_set(row), "nothing must be captured with the toggle off")
	end)

	runner.it("add_outline passes through when the archetype does not match the row", function()
		local mod = load_entry({ a9_mark_arbites = true }, "psyker")
		local add = hook_for(mod, "add_outline")
		local vanilla = spy()
		add(vanilla.fn, FAKE_SYSTEM, {}, "adamant_mark_target")
		runner.eq(vanilla.n, 1, "another archetype's outline must pass through")
	end)

	-- FIX 1 regression pin. A live row alone is NOT enough to swallow the vanilla remove:
	-- if we never captured the unit (toggle flipped on mid-mission, after vanilla already drew
	-- the outline) then swallowing the remove strands a vanilla outline nothing can clear.
	runner.it("remove_outline passes through for a unit that was never captured", function()
		local mod = load_entry({ a9_mark_arbites = true }, "adamant")
		local remove = hook_for(mod, "remove_outline")
		local vanilla = spy()
		local unit = {}
		remove(vanilla.fn, FAKE_SYSTEM, unit, "adamant_mark_target")
		runner.eq(vanilla.n, 1, "uncaptured unit must reach vanilla remove_outline")
		runner.eq(vanilla.unit, unit)
	end)

	runner.it("remove_outline suppresses only after a real capture", function()
		local mod = load_entry({ a9_mark_arbites = true }, "adamant")
		local add = hook_for(mod, "add_outline")
		local remove = hook_for(mod, "remove_outline")
		local vanilla = spy()
		local unit = {}
		add(vanilla.fn, FAKE_SYSTEM, unit, "adamant_mark_target")
		remove(vanilla.fn, FAKE_SYSTEM, unit, "adamant_mark_target")
		runner.eq(vanilla.n, 0, "an uncapture we own must not reach vanilla")
		local row = mod.mark_sources.row_for("adamant_mark_target", "adamant")
		runner.falsy(mod.mark_capture.pending_set(row)[unit], "unit must be released")
		remove(vanilla.fn, FAKE_SYSTEM, unit, "adamant_mark_target")
		runner.eq(vanilla.n, 1, "a second remove is no longer ours and must pass through")
	end)

	runner.it("remove_outline passes an unknown outline name straight through", function()
		local mod = load_entry({ a9_mark_arbites = true }, "adamant")
		local remove = hook_for(mod, "remove_outline")
		local vanilla = spy()
		remove(vanilla.fn, FAKE_SYSTEM, {}, "a9_lock")
		runner.eq(vanilla.n, 1, "vanilla remove_outline must still run for outlines we do not own")
	end)

	runner.it("the stance row stays inert while its keyword stance is not active", function()
		local mod = load_entry({ a9_mark_broker = true }, "broker")
		local add = hook_for(mod, "add_outline")
		local vanilla = spy()
		add(vanilla.fn, FAKE_SYSTEM, {}, "broker_proximity_target")
		runner.eq(vanilla.n, 1, "a stance row must not capture while the stance is inactive")
	end)
end
