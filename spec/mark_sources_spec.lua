local runner = require("spec.runner")
local engine = require("spec.mock_engine")

local function load_sources()
	return dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/modules/mark_sources.lua")
end

return function()
	runner.suite("mark_sources")

	runner.it("resolves each ability by outline plus archetype", function()
		local m = load_sources()
		runner.eq(m.row_for("adamant_mark_target", "adamant").setting, "mark_arbites")
		runner.eq(m.row_for("psyker_marked_target", "psyker").setting, "mark_psyker")
	end)

	runner.it("disambiguates the SHARED broker_proximity_target by archetype", function()
		local m = load_sources()
		local psalms = m.row_for("broker_proximity_target", "cryptic")
		local desperado = m.row_for("broker_proximity_target", "broker")
		runner.eq(psalms.setting, "mark_skitarii", "cryptic owns Target Prioritization Psalms")
		runner.eq(desperado.setting, "mark_broker", "broker owns Desperado")
		runner.eq(psalms.kind, "passive")
		runner.eq(desperado.kind, "stance")
		runner.eq(desperado.keyword, "broker_combat_ability_focus")
	end)

	runner.it("returns nil when the archetype does not own that outline", function()
		local m = load_sources()
		runner.falsy(m.row_for("broker_proximity_target", "veteran"), "veteran owns neither")
		runner.falsy(m.row_for("adamant_mark_target", "psyker"), "wrong class must not match")
	end)

	runner.it("ignores outlines the mod does not mirror", function()
		local m = load_sources()
		runner.falsy(m.row_for("a9_lock", "adamant"), "the mod's OWN outline must pass through")
		runner.falsy(m.row_for("special_target", "veteran"), "Veteran path is not registry-driven")
		runner.falsy(m.row_for(nil, "adamant"))
		runner.falsy(m.row_for("adamant_mark_target", nil))
	end)

	runner.it("passive rows carry no keyword", function()
		local m = load_sources()
		runner.falsy(m.row_for("adamant_mark_target", "adamant").keyword)
	end)
end
