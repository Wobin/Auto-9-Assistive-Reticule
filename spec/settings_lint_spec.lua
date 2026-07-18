local runner = require("spec.runner")
local engine = require("spec.mock_engine")

-- Ids read at runtime but deliberately not declared as widgets. Must be justified here.
-- (Currently empty: every id refresh_settings() reads has a declaring widget. Keep this
-- mechanism wired into the diff below even while empty, so a future intentional gap has
-- somewhere to go instead of being grepped around.)
local INTENTIONALLY_UNDECLARED = {}

local function declared_ids()
	local mod = engine.install({})
	local data = dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/Auto-9 Assistive Reticule_data.lua")
	local ids = {}
	local function walk(widgets)
		for _, w in ipairs(widgets or {}) do
			if w.setting_id then ids[w.setting_id] = true end
			walk(w.sub_widgets)
		end
	end
	walk(data.options and data.options.widgets)
	return ids
end

return function()
	runner.suite("settings lint")

	runner.it("every declared setting has a localization entry", function()
		local ids = declared_ids()
		local loc = dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/Auto-9 Assistive Reticule_localization.lua")
		for id in pairs(ids) do
			runner.truthy(loc[id], "missing localization for " .. id)
		end
	end)

	runner.it("no localization string contains a bare percent sign", function()
		local loc = dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/Auto-9 Assistive Reticule_localization.lua")
		for key, entry in pairs(loc) do
			for lang, text in pairs(entry) do
				if type(text) == "string" then
					runner.falsy(text:find("%%"), "bare percent in " .. key .. "." .. lang .. " CRASHES mod:localize")
				end
			end
		end
	end)

	runner.it("declares the settings the spec requires", function()
		local ids = declared_ids()
		local required = {
			"a9_box_enabled", "a9_box_thickness", "a9_slam_duration",
			"a9_lines_enabled", "a9_lines_thickness",
			"a9_outline_priority",
		}
		for _, id in ipairs(required) do
			runner.truthy(ids[id], "spec requires setting " .. id)
		end
	end)

	-- THE REAL LINT. A static walk of data.lua (the tests above) cannot catch a read built
	-- dynamically, e.g. mod:get(attacker .. "_range_max") - the id never appears as a literal
	-- anywhere, so nothing to grep for exists. This exercises the mod for real instead: it
	-- installs a recording mod:get, loads the actual entry point under it, runs
	-- refresh_settings() (the only place mod:get is allowed to appear), and diffs every id
	-- that was actually requested against what data.lua declares. A widget deleted out from
	-- under a still-live mod:get call, or a mod:get call added for an id nobody declared,
	-- both fail this test; a plain grep would have missed a dynamically-built id.
	runner.it("every setting the code reads at runtime is declared in data.lua", function()
		local declared = declared_ids()

		local mod = engine.install({})
		local requested = {}
		local raw_get = mod.get
		mod.get = function(self, id)
			requested[id] = true
			return raw_get(self, id)
		end

		dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/Auto-9 Assistive Reticule.lua")
		runner.truthy(mod.refresh_settings, "entry point must expose refresh_settings on the mod table")
		mod.refresh_settings()

		local missing = {}
		for id in pairs(requested) do
			if not declared[id] and not INTENTIONALLY_UNDECLARED[id] then
				missing[#missing + 1] = id
			end
		end
		table.sort(missing)

		runner.eq(#missing, 0,
			"undeclared settings read by code: " .. table.concat(missing, ", "))
	end)
end
