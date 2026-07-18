local runner = require("spec.runner")
local engine = require("spec.mock_engine")

local function load_tag()
	return dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/modules/tag.lua")
end

return function()
	runner.suite("tag")

	runner.it("tracks the newest enemy tag and returns its unit", function()
		local tag = load_tag()
		tag.reset()
		local me, mate = {}, {}
		local u1, u2 = {}, {}
		tag.on_create("t1", "enemy", me, u1)
		tag.on_create("t2", "enemy", mate, u2)
		runner.eq(tag.current_unit(false, me), u2, "any-mode: newest tag wins")
	end)

	runner.it("ignores non-enemy tags and location pings (no target_unit)", function()
		local tag = load_tag()
		tag.reset()
		local me = {}
		tag.on_create("loc", "location", me, nil)
		tag.on_create("att", "attention", me, {})
		runner.eq(tag.current_unit(false, me), nil, "no enemy tag stored")
	end)

	runner.it("own_only filters to the local player's tags", function()
		local tag = load_tag()
		tag.reset()
		local me, mate = {}, {}
		local mine, theirs = {}, {}
		tag.on_create("t1", "enemy", me, mine)
		tag.on_create("t2", "enemy", mate, theirs)
		runner.eq(tag.current_unit(true, me), mine, "own_only skips the teammate's newer tag")
		runner.eq(tag.current_unit(false, me), theirs, "any-mode returns the newer teammate tag")
	end)

	runner.it("falls back to the next newest live tag when the current clears", function()
		local tag = load_tag()
		tag.reset()
		local me = {}
		local a, b = {}, {}
		tag.on_create("t1", "enemy", me, a)
		tag.on_create("t2", "enemy", me, b)
		tag.on_remove("t2")
		runner.eq(tag.current_unit(false, me), a, "after removing newest, older live tag drives it")
		tag.on_remove("t1")
		runner.eq(tag.current_unit(false, me), nil, "all cleared -> nil")
	end)

	runner.it("double_tag_enemy counts as an enemy tag", function()
		local tag = load_tag()
		tag.reset()
		local me, u = {}, {}
		tag.on_create("t1", "double_tag_enemy", me, u)
		runner.eq(tag.current_unit(false, me), u)
	end)
end
