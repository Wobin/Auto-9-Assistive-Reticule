local runner = require("spec.runner")
local engine = require("spec.mock_engine")

local function load_cn()
	return dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/modules/credits_names.lua")
end

local FAKE = {
	settings = {
		entries = {
			{ text = "Warhammer 40,000: Darktide", type = "header" },
			{ text = "loc_credits_view_ceo_title", type = "title", localized = true },
			{ text = "Sven Folkesson", type = "person" },
			{ text = "Lucia Granda", type = "person" },
			{ text = "Sven Wahlund", type = "person" },
			{ text = "Anders De Geer", type = "person" },
			{ text = " ", type = "person" },
			{ text = "Some Header Words", type = "header" },
		},
	},
}

return function()
	runner.suite("credits names")

	runner.it("build extracts and dedupes first/last pools, person-typed only", function()
		local cn = load_cn()
		local firsts, lasts = cn.build(FAKE)
		table.sort(firsts); table.sort(lasts)
		runner.eq(table.concat(firsts, ","), "Anders,Lucia,Sven", "first names deduped")
		runner.eq(table.concat(lasts, ","), "Folkesson,Geer,Granda,Wahlund", "last names collected")
	end)

	runner.it("random_name returns a First Last from the pools", function()
		local cn = load_cn()
		cn.init(FAKE)
		local name = cn.random_name()
		local f, l = name:match("^(%u%a+) (%u%a+)$")
		runner.truthy(f ~= nil and l ~= nil, "shaped like 'First Last': " .. tostring(name))
	end)

	runner.it("random_name falls back when a pool is empty", function()
		local cn = load_cn()
		cn.init({})
		runner.eq(cn.random_name(), "Unknown Subject")
	end)

	runner.it("name_for returns the SAME name for the same unit (locked per-unit)", function()
		local cn = load_cn()
		cn.init(FAKE)
		local u = {}
		local a = cn.name_for(u)
		local b = cn.name_for(u)
		runner.eq(a, b, "same unit -> same name across calls")
	end)

	runner.it("name_for gives independent, stable names to distinct units", function()
		local cn = load_cn()
		cn.init(FAKE)
		local u1, u2 = {}, {}
		local n1 = cn.name_for(u1)
		runner.eq(cn.name_for(u1), n1, "u1 stable")
		local n2 = cn.name_for(u2)
		runner.eq(cn.name_for(u2), n2, "u2 stable and independently cached")
	end)
end
