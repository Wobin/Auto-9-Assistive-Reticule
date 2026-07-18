
local mod = get_mod("Auto-9 Assistive Reticule")

local OUTLINE_SETTINGS_PATH = "scripts/settings/outline/outline_settings"
local OL_NAME = "a9_lock"
local MATERIAL_LAYERS = { "minion_outline" }

local outline = {}

local function is_alive(unit)
	local health_alive = rawget(_G, "HEALTH_ALIVE")
	return health_alive ~= nil and health_alive[unit] == true
end

local profile = nil

local function build_colour()
	local c = mod.settings and mod.settings.outline_colour
	if not c then
		return { 1, 0, 0 }
	end
	return { c[2] / 255, c[3] / 255, c[4] / 255 }
end

local function build_priority()
	return (mod.settings and mod.settings.outline_priority) or 0
end

local function apply_profile(settings)
	settings.MinionOutlineExtension[OL_NAME] = {
		priority = build_priority(),
		color = build_colour(),
		material_layers = MATERIAL_LAYERS,
		visibility_check = is_alive,
	}
	profile = settings.MinionOutlineExtension[OL_NAME]
end

mod:hook_require(OUTLINE_SETTINGS_PATH, apply_profile)

local cached_outline_settings = package.loaded[OUTLINE_SETTINGS_PATH]
if cached_outline_settings then
	apply_profile(cached_outline_settings)
end

outline.refresh = function()
	if profile then
		profile.color = build_colour()
		profile.priority = build_priority()
	end
end

local function outline_system()
	local state_extension = Managers.state and Managers.state.extension
	return state_extension and state_extension:system("outline_system") or nil
end

outline.add = function(unit)
	local system = outline_system()
	if not system or not unit then
		return false
	end
	system:add_outline(unit, OL_NAME)
	return true
end

outline.remove = function(unit)
	local system = outline_system()
	if not system or not unit then
		return
	end
	pcall(system.remove_outline, system, unit, OL_NAME)
end

outline.on_exit = function()
end

return outline
