local runner = require("spec.runner")
local engine = require("spec.mock_engine")

local function load_capture()
	return dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/modules/mark_capture.lua")
end

local ROW_A = { outline = "adamant_mark_target", archetype = "adamant" }
local ROW_B = { outline = "broker_proximity_target", archetype = "cryptic" }

local function count(set)
	local n = 0
	for _ in pairs(set or {}) do n = n + 1 end
	return n
end

return function()
	runner.suite("mark_capture")

	runner.it("captures units into a row's set", function()
		local c = load_capture()
		local u1, u2 = {}, {}
		c.capture(ROW_A, u1)
		c.capture(ROW_A, u2)
		c.capture(ROW_A, nil)
		local set = c.pending_set(ROW_A)
		runner.truthy(set[u1] and set[u2], "both captured")
		runner.eq(count(set), 2, "nil not captured")
	end)

	runner.it("keeps rows isolated from each other", function()
		local c = load_capture()
		local u = {}
		c.capture(ROW_A, u)
		runner.falsy(c.pending_set(ROW_B) and c.pending_set(ROW_B)[u], "row B must not see row A's unit")
	end)

	runner.it("uncapture removes and reports whether it was present", function()
		local c = load_capture()
		local u = {}
		c.capture(ROW_A, u)
		runner.truthy(c.uncapture(ROW_A, u), "was present")
		runner.falsy(c.pending_set(ROW_A)[u], "removed")
		runner.falsy(c.uncapture(ROW_A, u), "second uncapture reports absent")
	end)

	runner.it("prune drops units failing is_enemy_unit and returns them", function()
		local c = load_capture()
		local alive, dead = {}, {}
		c.capture(ROW_A, alive)
		c.capture(ROW_A, dead)
		local dropped = c.prune(ROW_A, function(u) return u == alive end)
		runner.eq(#dropped, 1, "one dropped")
		runner.eq(dropped[1], dead)
		runner.truthy(c.pending_set(ROW_A)[alive], "valid unit retained")
		runner.falsy(c.pending_set(ROW_A)[dead], "invalid unit removed")
	end)

	runner.it("clear empties one row and returns its units", function()
		local c = load_capture()
		local u = {}
		c.capture(ROW_A, u)
		c.capture(ROW_B, {})
		local dropped = c.clear(ROW_A)
		runner.eq(#dropped, 1)
		runner.eq(count(c.pending_set(ROW_A)), 0, "row A emptied")
		runner.eq(count(c.pending_set(ROW_B)), 1, "row B untouched")
	end)

	runner.it("clear_all empties every row and returns all units", function()
		local c = load_capture()
		c.capture(ROW_A, {})
		c.capture(ROW_B, {})
		local dropped = c.clear_all()
		runner.eq(#dropped, 2)
		runner.eq(count(c.pending_set(ROW_A)), 0)
		runner.eq(count(c.pending_set(ROW_B)), 0)
	end)

	runner.it("tolerates nil row and nil predicate", function()
		local c = load_capture()
		c.capture(nil, {})
		runner.falsy(c.pending_set(nil))
		runner.falsy(c.uncapture(nil, {}))
		runner.eq(#c.prune(nil, function() return true end), 0)
		runner.eq(#c.prune(ROW_A, nil), 0)
	end)
end
