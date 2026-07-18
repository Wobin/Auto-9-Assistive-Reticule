local runner = require("spec.runner")
local engine = require("spec.mock_engine")

local SOURCES = {
	"scripts/mods/Auto-9 Assistive Reticule/Auto-9 Assistive Reticule.lua",
	"scripts/mods/Auto-9 Assistive Reticule/Auto-9 Assistive Reticule_data.lua",
	"scripts/mods/Auto-9 Assistive Reticule/Auto-9 Assistive Reticule_localization.lua",
	"scripts/mods/Auto-9 Assistive Reticule/modules/stance.lua",
	"scripts/mods/Auto-9 Assistive Reticule/modules/target.lua",
	"scripts/mods/Auto-9 Assistive Reticule/modules/project.lua",
	"scripts/mods/Auto-9 Assistive Reticule/modules/sequence.lua",
	"scripts/mods/Auto-9 Assistive Reticule/modules/hud_element.lua",
	"scripts/mods/Auto-9 Assistive Reticule/modules/outline.lua",
	"scripts/mods/Auto-9 Assistive Reticule/modules/eligibility.lua",
	"scripts/mods/Auto-9 Assistive Reticule/modules/scanner.lua",
	"scripts/mods/Auto-9 Assistive Reticule/modules/credits_names.lua",
	"scripts/mods/Auto-9 Assistive Reticule/modules/tag.lua",
}

local function read(path)
	local f = io.open(engine.MOD_ROOT .. "/" .. path, "r")
	if not f then return nil end
	local s = f:read("*a")
	f:close()
	return s
end

return function()
	runner.suite("parse")

	for _, path in ipairs(SOURCES) do
		runner.it("parses: " .. path, function()
			local chunk, err = loadfile(engine.MOD_ROOT .. "/" .. path)
			runner.truthy(chunk, "syntax error in " .. path .. ": " .. tostring(err))
		end)
	end

	runner.it("no goto statements", function()
		for _, path in ipairs(SOURCES) do
			local src = read(path)
			if src then
				runner.falsy(src:match("%f[%w]goto%f[%W]"), "goto found in " .. path)
			end
		end
	end)

	runner.it("no em-dashes", function()
		for _, path in ipairs(SOURCES) do
			local src = read(path)
			if src then
				runner.falsy(src:find("\226\128\148", 1, true), "em-dash found in " .. path)
			end
		end
	end)

	runner.it(".mod version matches mod.version", function()
		local manifest = read("Auto-9 Assistive Reticule.mod")
		local entry = read("scripts/mods/Auto-9 Assistive Reticule/Auto-9 Assistive Reticule.lua")
		local manifest_version = manifest:match('version%s*=%s*"([^"]+)"')
		local entry_version = entry:match('mod%.version%s*=%s*"([^"]+)"')
		runner.eq(entry_version, manifest_version, "version drift between .mod and .lua")
	end)

	runner.it("info.json version matches .mod version", function()
		local manifest = read("Auto-9 Assistive Reticule.mod")
		local info = read("info.json")
		local manifest_version = manifest:match('version%s*=%s*"([^"]+)"')
		local info_version = info:match('"version"%s*:%s*"([^"]+)"')
		runner.eq(info_version, manifest_version, "version drift between info.json and .mod")
	end)
end
