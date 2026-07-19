local runner = require("spec.runner")
local engine = require("spec.mock_engine")

local function load_target()
	return dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/modules/target.lua")
end

local UNIT_A = newproxy(false)
local UNIT_B = newproxy(false)

local function data_for(unit)
	if not unit then return nil end
	return { unit = unit }
end

return function()
	runner.suite("target")

	runner.it("is IDLE while the stance is down", function()
		local target = load_target()
		runner.eq(target.update(0, false, nil), target.IDLE)
	end)

	runner.it("is SWEEP when the stance is up with no target", function()
		local target = load_target()
		runner.eq(target.update(0, true, nil), target.SWEEP)
	end)

	runner.it("enters SLAM on acquisition", function()
		local target = load_target()
		target.update(0, true, nil)
		runner.eq(target.update(1.0, true, data_for(UNIT_A)), target.SLAM)
		runner.eq(target.unit(), UNIT_A)
	end)

	runner.it("settles from SLAM into LOCKED after SLAM_DURATION", function()
		local target = load_target()
		target.update(0, true, data_for(UNIT_A))
		runner.eq(target.state(), target.SLAM)
		target.update(target.SLAM_DURATION + 0.01, true, data_for(UNIT_A))
		runner.eq(target.state(), target.LOCKED)
	end)

	runner.it("slam_progress ramps 0 to 1 across SLAM_DURATION", function()
		local target = load_target()
		target.update(0, true, data_for(UNIT_A))
		runner.near(target.slam_progress(0), 0, 0.001, "progress starts at 0")
		runner.near(target.slam_progress(target.SLAM_DURATION * 0.5), 0.5, 0.001, "half way")
		runner.near(target.slam_progress(target.SLAM_DURATION), 1, 0.001, "fully collapsed")
		runner.near(target.slam_progress(target.SLAM_DURATION * 5), 1, 0.001, "clamps at 1")
	end)

	-- THE REGRESSION TEST. Without the loss grace this mod strobes in live play.
	runner.it("holds LOCKED through a resim gap shorter than LOSS_GRACE", function()
		local target = load_target()
		target.update(0, true, data_for(UNIT_A))
		target.update(1.0, true, data_for(UNIT_A))
		runner.eq(target.state(), target.LOCKED)

		target.update(1.05, true, nil)
		runner.eq(target.state(), target.LOCKED, "a nil unit inside the grace window is NOT a loss")
		runner.eq(target.unit(), UNIT_A, "must keep believing the last target")

		target.update(1.1, true, data_for(UNIT_A))
		runner.eq(target.state(), target.LOCKED, "recovery must not re-slam")
	end)

	runner.it("drops to SWEEP once a gap exceeds LOSS_GRACE", function()
		local target = load_target()
		target.update(0, true, data_for(UNIT_A))
		target.update(1.0, true, data_for(UNIT_A))
		target.update(1.0 + target.LOSS_GRACE + 0.01, true, nil)
		runner.eq(target.state(), target.SWEEP, "a real loss must eventually register")
		runner.eq(target.unit(), nil)
	end)

	runner.it("re-slams partially on a target change, not from full size", function()
		local target = load_target()
		target.update(0, true, data_for(UNIT_A))
		target.update(1.0, true, data_for(UNIT_A))
		runner.eq(target.state(), target.LOCKED)

		target.update(2.0, true, data_for(UNIT_B))
		runner.eq(target.state(), target.SLAM, "a change re-slams")
		runner.eq(target.unit(), UNIT_B)
		runner.near(target.slam_progress(2.0), 1 - target.RESLAM_FRACTION, 0.001,
			"a change starts partway in, not at 0")
	end)

	runner.it("enters RELEASE when the stance drops while locked", function()
		local target = load_target()
		target.update(0, true, data_for(UNIT_A))
		target.update(1.0, true, data_for(UNIT_A))
		runner.eq(target.update(2.0, false, data_for(UNIT_A)), target.RELEASE)
	end)

	runner.it("returns to IDLE after RELEASE completes", function()
		local target = load_target()
		target.update(0, true, data_for(UNIT_A))
		target.update(1.0, true, data_for(UNIT_A))
		target.update(2.0, false, nil)
		runner.eq(target.state(), target.RELEASE)
		target.update(2.0 + target.RELEASE_DURATION + 0.01, false, nil)
		runner.eq(target.state(), target.IDLE)
	end)

	runner.it("a stance drop beats the loss grace", function()
		local target = load_target()
		target.update(0, true, data_for(UNIT_A))
		target.update(1.0, true, data_for(UNIT_A))
		target.update(1.05, false, nil)
		runner.eq(target.state(), target.RELEASE, "stance down is authoritative over a pending loss")
	end)

	runner.it("is_enemy_unit rejects nil", function()
		local target = load_target()
		runner.falsy(target.is_enemy_unit(nil, function() return nil end, {}))
	end)

	runner.it("is_enemy_unit rejects a dead unit", function()
		local target = load_target()
		runner.falsy(target.is_enemy_unit(UNIT_A, function() return nil end, {}), "absent from HEALTH_ALIVE = dead")
	end)

	runner.it("is_enemy_unit rejects a live PLAYER unit (the respawn-recycle bug)", function()
		local target = load_target()
		local health_alive = { [UNIT_A] = true }
		local is_player = function(u) return u == UNIT_A and "player_obj" or nil end
		runner.falsy(target.is_enemy_unit(UNIT_A, is_player, health_alive),
			"a recycled handle now owned by a player must never be targeted")
	end)

	runner.it("is_enemy_unit accepts a live non-player unit", function()
		local target = load_target()
		local health_alive = { [UNIT_A] = true }
		runner.truthy(target.is_enemy_unit(UNIT_A, function() return nil end, health_alive))
	end)

	runner.it("is_enemy_unit skips the liveness gate when no health table is supplied", function()
		local target = load_target()
		runner.truthy(target.is_enemy_unit(UNIT_A, function() return nil end, nil),
			"nil health_alive = caller already pre-checked liveness")
	end)
end
