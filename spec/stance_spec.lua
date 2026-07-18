local runner = require("spec.runner")
local engine = require("spec.mock_engine")

local function load_stance()
	package.loaded["scripts.mods.Auto-9 Assistive Reticule.modules.stance"] = nil
	return dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/modules/stance.lua")
end

local function buff(keywords)
	return {
		template = function()
			return { keywords = keywords }
		end,
	}
end

local ACD = buff({ "cryptic_precision_stance", "enable_auto_aim" })
local OTHER = buff({ "some_other_buff" })

return function()
	runner.suite("stance")

	runner.it("starts inactive", function()
		local stance = load_stance()
		runner.falsy(stance.is_active())
	end)

	runner.it("activates on a buff carrying enable_auto_aim", function()
		local stance = load_stance()
		stance.on_buff_added(ACD)
		runner.truthy(stance.is_active())
	end)

	runner.it("ignores unrelated buffs", function()
		local stance = load_stance()
		stance.on_buff_added(OTHER)
		runner.falsy(stance.is_active())
	end)

	runner.it("stays active through a rollback re-fire inside the grace window", function()
		local stance = load_stance()
		stance.on_buff_added(ACD)
		stance.update(0)
		stance.on_buff_removed(ACD)
		stance.update(0.05)
		runner.truthy(stance.is_active(), "must not drop inside the grace window")
		stance.on_buff_added(ACD)
		stance.update(0.10)
		runner.truthy(stance.is_active(), "re-add must cancel the pending drop")
		stance.update(1.0)
		runner.truthy(stance.is_active(), "still active long after the cancelled drop")
	end)

	runner.it("deactivates once the grace window elapses", function()
		local stance = load_stance()
		stance.on_buff_added(ACD)
		stance.update(0)
		stance.on_buff_removed(ACD)
		stance.update(0.05)
		runner.truthy(stance.is_active())
		stance.update(0.2)
		runner.falsy(stance.is_active(), "must drop after GRACE elapses")
	end)

	runner.it("ignores removal of an unrelated buff while active", function()
		local stance = load_stance()
		stance.on_buff_added(ACD)
		stance.update(0)
		stance.on_buff_removed(OTHER)
		stance.update(1.0)
		runner.truthy(stance.is_active())
	end)
end
