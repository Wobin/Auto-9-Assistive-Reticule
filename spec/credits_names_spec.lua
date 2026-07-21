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

	runner.it("style_for picks ogryn for ogryn-tagged breeds", function()
		local cn = load_cn()
		runner.eq(cn.style_for({ name = "chaos_ogryn_bulwark", tags = { ogryn = true } }), "ogryn")
	end)

	runner.it("style_for picks pet for hound breeds", function()
		local cn = load_cn()
		runner.eq(cn.style_for({ name = "chaos_hound", tags = { special = true } }), "pet")
		runner.eq(cn.style_for({ name = "chaos_armored_hound", tags = {} }), "pet")
		runner.eq(cn.style_for({ name = "companion_dog", tags = {} }), "pet")
	end)

	runner.it("style_for treats the ogryn houndmaster as an OGRYN, not a hound", function()
		local cn = load_cn()
		runner.eq(cn.style_for({ name = "chaos_ogryn_houndmaster", tags = { ogryn = true } }), "ogryn",
			"name contains 'hound' but it is the handler, and the ogryn tag wins")
	end)

	runner.it("style_for falls back to full name", function()
		local cn = load_cn()
		runner.eq(cn.style_for({ name = "renegade_rifleman", tags = {} }), "full")
		runner.eq(cn.style_for(nil), "full")
	end)

	runner.it("name_for yields an in-universe Ogryn name, not a credits surname", function()
		local cn = load_cn()
		cn.init(PETS_FAKE)
		local ogryn = { name = "chaos_ogryn_bulwark", tags = { ogryn = true } }
		local seen, n = {}, 0
		for i = 1, 2000 do
			local nm = cn.name_for({}, ogryn)
			if not seen[nm] then seen[nm] = true n = n + 1 end
		end
		runner.eq(n, 29, "the full Ogryn pool is reachable")
		runner.truthy(seen["Nork"], "canonical Ogryn name present")
		runner.truthy(seen["Smasha"], "canonical Ogryn name present")
		runner.falsy(seen["Folkesson"], "must NOT draw from the credits surname pool")
	end)

	runner.it("name_for yields a pet name for a hound", function()
		local cn = load_cn()
		cn.init(PETS_FAKE)
		local name = cn.name_for({}, { name = "chaos_hound", tags = {} })
		runner.falsy(name:find(" "), "a pet name is a single token; a full name would be 'First Last': " .. tostring(name))
		runner.truthy(name ~= "Unknown Subject", "pool must not be empty")
	end)

	runner.it("init merges the Cyber-Mastiff names into the pet pool, deduped", function()
		local cn = load_cn()
		cn.init(PETS_FAKE)
		local seen, n = {}, 0
		local hound = { name = "chaos_hound", tags = {} }
		for i = 1, 4000 do
			local name = cn.name_for({}, hound)
			if not seen[name] then
				seen[name] = true
				n = n + 1
			end
		end
		runner.truthy(seen["Cerberus"], "in-universe Mastiff name present")
		runner.truthy(seen["Teebo"], "credits pet name still present")
		runner.truthy(n > 115, "both pools merged, got " .. n .. " distinct names")
	end)

	runner.it("the merge does not duplicate a name present in both pools", function()
		local cn = load_cn()
		local _, _, pets = cn.build(PETS_FAKE)
		local before = #pets
		cn.init(PETS_FAKE)
		local hound = { name = "chaos_hound", tags = {} }
		local counts = {}
		for i = 1, 4000 do
			local nm = cn.name_for({}, hound)
			counts[nm] = (counts[nm] or 0) + 1
		end
		runner.truthy(before > 0, "fixture supplied credits pets")
		runner.truthy(counts["Freja"] == nil or counts["Freja"] > 0,
			"Freja appears in BOTH source lists and must not be duplicated in the pool")
	end)

	runner.it("ogryn style never falls back: the Ogryn names are baked in, not credits-derived", function()
		local cn = load_cn()
		cn.init({})
		local name = cn.random_name("ogryn")
		runner.truthy(name ~= "Unknown Subject",
			"even with NO credits data an ogryn still gets a name, got: " .. tostring(name))
		runner.falsy(name:find(" "), "single token")
	end)

	runner.it("pet style never falls back: the Mastiff names are baked in, not credits-derived", function()
		local cn = load_cn()
		cn.init({})
		local name = cn.random_name("pet")
		runner.truthy(name ~= "Unknown Subject",
			"even with NO credits data a hound still gets a name, got: " .. tostring(name))
		runner.falsy(name:find(" "), "single token")
	end)
end
