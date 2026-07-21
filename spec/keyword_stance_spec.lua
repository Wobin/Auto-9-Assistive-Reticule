local runner = require("spec.runner")
local engine = require("spec.mock_engine")

local function load_factory()
	return dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/modules/keyword_stance.lua")
end

local function buff(keywords)
	return { template = function() return { keywords = keywords } end }
end

local FOCUS = buff({ "uninterruptible", "broker_combat_ability_focus" })
local OTHER = buff({ "enable_auto_aim" })

return function()
	runner.suite("keyword_stance")

	runner.it("activates only on its own keyword", function()
		local d = load_factory().new("broker_combat_ability_focus")
		d.on_buff_added(OTHER)
		runner.falsy(d.is_active(), "unrelated buff does not activate")
		d.on_buff_added(FOCUS)
		runner.truthy(d.is_active())
	end)

	runner.it("deactivates after the grace period once removed", function()
		local d = load_factory().new("broker_combat_ability_focus")
		d.on_buff_added(FOCUS)
		d.on_buff_removed(FOCUS)
		runner.truthy(d.is_active(), "still active immediately after removal")
		d.update(0)
		d.update(d.GRACE + 1)
		runner.falsy(d.is_active(), "inactive after grace elapses")
	end)

	runner.it("a re-add inside the grace window cancels the pending drop", function()
		local d = load_factory().new("broker_combat_ability_focus")
		d.on_buff_added(FOCUS)
		d.update(0)
		d.on_buff_removed(FOCUS)
		d.update(0.05)
		d.on_buff_added(FOCUS)
		d.update(1.0)
		runner.truthy(d.is_active(), "re-add must cancel the drop")
	end)

	runner.it("reset clears active state", function()
		local d = load_factory().new("broker_combat_ability_focus")
		d.on_buff_added(FOCUS)
		d.reset()
		runner.falsy(d.is_active())
	end)

	runner.it("two detectors keep independent state", function()
		local f = load_factory()
		local a = f.new("broker_combat_ability_focus")
		local b = f.new("some_other_keyword")
		a.on_buff_added(FOCUS)
		runner.truthy(a.is_active())
		runner.falsy(b.is_active(), "detectors must not share state")
	end)

	runner.it("tolerates malformed buffs", function()
		local d = load_factory().new("broker_combat_ability_focus")
		d.on_buff_added(nil)
		d.on_buff_added({})
		d.on_buff_added({ template = function() return nil end })
		d.on_buff_added({ template = function() return {} end })
		runner.falsy(d.is_active())
	end)
end
