local runner = require("spec.runner")
local engine = require("spec.mock_engine")

local function load_exec()
	return dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/modules/exec_stance.lua")
end

local function buff(keywords)
	return { template = function() return { keywords = keywords } end }
end

local STANCE = buff({ "uninterruptible", "veteran_combat_ability_stance" })
local OTHER = buff({ "enable_auto_aim" })

return function()
	runner.suite("exec_stance")

	runner.it("activates only on the veteran stance keyword", function()
		local e = load_exec()
		e.reset()
		e.on_buff_added(OTHER)
		runner.falsy(e.is_active(), "unrelated buff does not activate")
		e.on_buff_added(STANCE)
		runner.truthy(e.is_active(), "stance keyword activates")
	end)

	runner.it("deactivates after the grace period once removed", function()
		local e = load_exec()
		e.reset()
		e.on_buff_added(STANCE)
		e.on_buff_removed(STANCE)
		runner.truthy(e.is_active(), "still active immediately after removal")
		e.update(0)
		e.update(e.GRACE + 1)
		runner.falsy(e.is_active(), "inactive after grace elapses")
	end)

	runner.it("reset clears active state", function()
		local e = load_exec()
		e.on_buff_added(STANCE)
		e.reset()
		runner.falsy(e.is_active())
	end)

	runner.it("capture accumulates units, pending_set returns them, reset clears", function()
		local e = load_exec()
		e.reset()
		local a, b = {}, {}
		e.capture(a)
		e.capture(b)
		e.capture(nil)
		local set = e.pending_set()
		runner.truthy(set[a] and set[b], "both captured")
		local n = 0
		for _ in pairs(set) do n = n + 1 end
		runner.eq(n, 2, "nil not captured")
		e.reset()
		local n2 = 0
		for _ in pairs(e.pending_set()) do n2 = n2 + 1 end
		runner.eq(n2, 0, "reset clears pending")
	end)

	runner.it("order_by_x keeps on-screen units and sorts ascending by x", function()
		local e = load_exec()
		local u_l, u_r, u_off = {}, {}, {}
		local xs = { [u_l] = 100, [u_r] = 300, [u_off] = nil }
		local out = e.order_by_x({ [u_l] = true, [u_r] = true, [u_off] = true }, function(u) return xs[u] end)
		runner.eq(#out, 2, "off-screen (nil x) excluded")
		runner.eq(out[1], u_l, "leftmost (x=100) first")
		runner.eq(out[2], u_r, "then x=300")
	end)
end
