local runner = require("spec.runner")
local engine = require("spec.mock_engine")

local function load_sequence()
	return dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/modules/sequence.lua")
end

return function()
	runner.suite("sequence")

	-- ease_out -----------------------------------------------------------

	runner.it("ease_out: starts at 0", function()
		local sequence = load_sequence()
		runner.near(sequence.ease_out(0), 0, 0.0001)
	end)

	runner.it("ease_out: ends at 1", function()
		local sequence = load_sequence()
		runner.near(sequence.ease_out(1), 1, 0.0001)
	end)

	runner.it("ease_out: midpoint is 0.875 (fast start, slow finish)", function()
		local sequence = load_sequence()
		runner.near(sequence.ease_out(0.5), 0.875, 0.0001)
	end)

	-- slide_factor ---------------------------------------------------------

	runner.it("slide_factor: zero dt produces zero movement", function()
		local sequence = load_sequence()
		runner.near(sequence.slide_factor(0, 0.10), 0, 0.0001)
	end)

	runner.it("slide_factor: one smoothing step moves partway toward the goal, never past it", function()
		local sequence = load_sequence()
		local f = sequence.slide_factor(0.016, 0.10)
		runner.truthy(f > 0 and f < 1, "factor must be strictly between 0 and 1 for a finite dt")

		local cross = 0
		local goal = 100
		cross = cross + (goal - cross) * f
		runner.truthy(cross > 0 and cross < goal, "one step must move toward, but not reach, the goal")
	end)

	runner.it("slide_factor: repeated steps monotonically approach the goal without overshoot", function()
		local sequence = load_sequence()
		local cross = 0
		local goal = 100
		local prev = cross
		for _ = 1, 20 do
			local f = sequence.slide_factor(0.016, 0.10)
			cross = cross + (goal - cross) * f
			runner.truthy(cross >= prev, "must not move backward")
			runner.truthy(cross <= goal, "must not overshoot the goal")
			prev = cross
		end
		runner.truthy(cross > 90, "20 steps at TAU=0.10 should have nearly converged")
	end)

	-- arrived --------------------------------------------------------------

	runner.it("arrived: true exactly at the goal centre", function()
		local sequence = load_sequence()
		runner.truthy(sequence.arrived(50, 50, 50, 50, 5))
	end)

	runner.it("arrived: false well outside the radius", function()
		local sequence = load_sequence()
		runner.falsy(sequence.arrived(0, 0, 100, 100, 5))
	end)

	runner.it("arrived: false exactly on the radius boundary (strict inequality)", function()
		local sequence = load_sequence()
		runner.falsy(sequence.arrived(5, 0, 0, 0, 5))
	end)

	runner.it("arrived: true just inside the radius", function()
		local sequence = load_sequence()
		runner.truthy(sequence.arrived(4.9, 0, 0, 0, 5))
	end)

	-- settled ----------------------------------------------------------------

	runner.it("settled: false when not LOCKED, even if arrived", function()
		local sequence = load_sequence()
		runner.falsy(sequence.settled(false, 10.0, 10.0, 0.0, true))
	end)

	runner.it("settled: false when LOCKED but not yet arrived", function()
		local sequence = load_sequence()
		runner.falsy(sequence.settled(true, 10.0, 10.0, 0.0, false))
	end)

	runner.it("settled: false when LOCKED and arrived but SETTLE has not elapsed", function()
		local sequence = load_sequence()
		runner.falsy(sequence.settled(true, 10.0, 10.2, 0.5, true))
	end)

	runner.it("settled: true when LOCKED, arrived, and elapsed >= SETTLE (SETTLE=0 is instant)", function()
		local sequence = load_sequence()
		runner.truthy(sequence.settled(true, 10.0, 10.0, 0.0, true))
	end)

	runner.it("settled: false with no lock_t recorded yet", function()
		local sequence = load_sequence()
		runner.falsy(sequence.settled(true, nil, 10.0, 0.0, true))
	end)

	-- is_reload_kind -----------------------------------------------------------

	runner.it("is_reload_kind: true for reload_shotgun", function()
		local sequence = load_sequence()
		runner.truthy(sequence.is_reload_kind("reload_shotgun"))
	end)

	runner.it("is_reload_kind: true for reload_state", function()
		local sequence = load_sequence()
		runner.truthy(sequence.is_reload_kind("reload_state"))
	end)

	runner.it("is_reload_kind: true for ranged_load_special", function()
		local sequence = load_sequence()
		runner.truthy(sequence.is_reload_kind("ranged_load_special"))
	end)

	runner.it("is_reload_kind: false for an unrelated kind", function()
		local sequence = load_sequence()
		runner.falsy(sequence.is_reload_kind("shoot_projectile"))
	end)

	runner.it("is_reload_kind: false for nil (no current action)", function()
		local sequence = load_sequence()
		runner.falsy(sequence.is_reload_kind(nil))
	end)
end
