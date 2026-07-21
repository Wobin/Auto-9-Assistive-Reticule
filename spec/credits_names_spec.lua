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

local PETS_FAKE = {
	settings = {
		entries = {
			{ text = "loc_credits_view_ceo_title", type = "title", localized = true },
			{ text = "Sven Folkesson", type = "person" },
			{ text = "loc_credits_view_pets_title", type = "header", localized = true },
			{ text = "Teebo, Ginger & Bourbon, Muffin", type = "person" },
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

	runner.it("build extracts the pet list and keeps it OUT of the person pools", function()
		local cn = load_cn()
		local firsts, lasts, pets = cn.build(PETS_FAKE)
		table.sort(pets)
		runner.eq(table.concat(pets, ","), "Bourbon,Ginger,Muffin,Teebo",
			"split on comma AND ampersand, trimmed")
		runner.falsy(table.concat(firsts, ","):find("Teebo"), "pet entry must not pollute first names")
		runner.falsy(table.concat(lasts, ","):find("Bourbon"), "pet entry must not pollute last names")
		runner.eq(table.concat(firsts, ","), "Sven", "only the real person entry feeds the pools")
	end)

	runner.it("style_for picks surname for ogryn-tagged breeds", function()
		local cn = load_cn()
		runner.eq(cn.style_for({ name = "chaos_ogryn_bulwark", tags = { ogryn = true } }), "surname")
	end)

	runner.it("style_for picks pet for hound breeds", function()
		local cn = load_cn()
		runner.eq(cn.style_for({ name = "chaos_hound", tags = { special = true } }), "pet")
		runner.eq(cn.style_for({ name = "chaos_armored_hound", tags = {} }), "pet")
		runner.eq(cn.style_for({ name = "companion_dog", tags = {} }), "pet")
	end)

	runner.it("style_for treats the ogryn houndmaster as an OGRYN, not a hound", function()
		local cn = load_cn()
		runner.eq(cn.style_for({ name = "chaos_ogryn_houndmaster", tags = { ogryn = true } }), "surname",
			"name contains 'hound' but it is the handler, and the ogryn tag wins")
	end)

	runner.it("style_for falls back to full name", function()
		local cn = load_cn()
		runner.eq(cn.style_for({ name = "renegade_rifleman", tags = {} }), "full")
		runner.eq(cn.style_for(nil), "full")
	end)

	runner.it("name_for yields a bare surname for an ogryn", function()
		local cn = load_cn()
		cn.init(PETS_FAKE)
		local name = cn.name_for({}, { name = "chaos_ogryn_bulwark", tags = { ogryn = true } })
		runner.eq(name, "Folkesson", "single surname, no first name")
	end)

	runner.it("name_for yields a pet name for a hound", function()
		local cn = load_cn()
		cn.init(PETS_FAKE)
		local name = cn.name_for({}, { name = "chaos_hound", tags = {} })
		local ok = name == "Teebo" or name == "Ginger" or name == "Bourbon" or name == "Muffin"
		runner.truthy(ok, "expected a pet name, got: " .. tostring(name))
	end)

	runner.it("pet and surname styles fall back when their pool is empty", function()
		local cn = load_cn()
		cn.init({})
		runner.eq(cn.random_name("pet"), "Unknown Subject")
		runner.eq(cn.random_name("surname"), "Unknown Subject")
	end)
end
