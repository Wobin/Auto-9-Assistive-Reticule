--[[
	Name: Auto-9 Assistive Reticule
	Author: Wobin
	Date: 21/07/2026
	Version: 1.3.0
	Repository: https://github.com/Wobin/Auto-9-Assistive-Reticule
]]--

local mod = get_mod("Auto-9 Assistive Reticule")
mod.version = "1.3.0"

mod.settings = {}

mod.stance = mod:io_dofile("Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/modules/stance")
mod.target = mod:io_dofile("Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/modules/target")
mod.project = mod:io_dofile("Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/modules/project")
mod.outline = mod:io_dofile("Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/modules/outline")
mod.eligibility = mod:io_dofile("Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/modules/eligibility")
mod.scanner = mod:io_dofile("Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/modules/scanner")
mod.credits_names = mod:io_dofile("Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/modules/credits_names")
mod.tag = mod:io_dofile("Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/modules/tag")
mod.exec_stance = mod:io_dofile("Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/modules/exec_stance")
mod.mark_sources = mod:io_dofile("Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/modules/mark_sources")
mod.mark_capture = mod:io_dofile("Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/modules/mark_capture")
mod.keyword_stance = mod:io_dofile("Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/modules/keyword_stance")
mod.focus_stance = mod.keyword_stance.new("broker_combat_ability_focus")

local cached_archetype = nil
local cached_archetype_unit = nil

local function local_archetype()
	local player_manager = Managers.player
	local player = player_manager and player_manager:local_player_safe(1)
	local unit = player and player.player_unit
	if unit ~= nil and unit == cached_archetype_unit then
		return cached_archetype
	end
	local profile = player and player:profile()
	local archetype = profile and profile.archetype
	cached_archetype = archetype and archetype.name or nil
	cached_archetype_unit = unit
	return cached_archetype
end

mod.local_archetype = local_archetype

local function row_is_live(row)
	if not row then
		return false
	end
	local s = mod.settings
	if not s or s[row.setting] ~= true then
		return false
	end
	if row.kind == "stance" then
		return mod.focus_stance ~= nil and mod.focus_stance.is_active()
	end
	return true
end

mod.active_mark_row = function()
	local archetype = local_archetype()
	if not archetype then
		return nil
	end
	if not mod.mark_sources then
		return nil
	end
	local rows = mod.mark_sources.ROWS
	for i = 1, #rows do
		local row = rows[i]
		if row.archetype == archetype and row_is_live(row) then
			return row
		end
	end
	return nil
end

local DRAW_LAYER = 360
local UI_HUD_SETTINGS_PATH = "scripts/settings/ui/ui_hud_settings"

local function apply_draw_layer(settings)
	settings.element_draw_layers = settings.element_draw_layers or {}
	settings.element_draw_layers.HudElementAuto9Reticule = DRAW_LAYER
end

mod:hook_require(UI_HUD_SETTINGS_PATH, apply_draw_layer)

local cached_hud_settings = package.loaded[UI_HUD_SETTINGS_PATH]
if cached_hud_settings then
	apply_draw_layer(cached_hud_settings)
end

mod:register_hud_element({
	class_name = "HudElementAuto9Reticule",
	filename = "Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/modules/hud_element",
	visibility_groups = { "alive" },
	use_hud_scale = true,
})

mod:hook("OutlineSystem", "add_outline", function(func, self, unit, outline_name)
	local s = mod.settings
	if s and s.exec_enabled and mod.exec_stance and mod.exec_stance.is_active() and outline_name == "special_target" then
		mod.exec_stance.capture(unit)
		return
	end
	local sources = mod.mark_sources
	local row = sources and sources.NAMES[outline_name] and sources.row_for(outline_name, local_archetype()) or nil
	if row and row_is_live(row) and mod.mark_capture then
		mod.mark_capture.capture(row, unit)
		return
	end
	return func(self, unit, outline_name)
end)

mod:hook("OutlineSystem", "remove_outline", function(func, self, unit, outline_name)
	local sources = mod.mark_sources
	local row = sources and sources.NAMES[outline_name] and sources.row_for(outline_name, local_archetype()) or nil
	if row and row_is_live(row) and mod.mark_capture and mod.mark_capture.uncapture(row, unit) then
		if mod.outline then
			mod.outline.remove(unit, mod.outline.MARK_NAME)
		end
		return
	end
	return func(self, unit, outline_name)
end)

local function colour(base, opacity_id)
	return {
		mod:get(opacity_id) or 255,
		mod:get(base .. "_R") or 255,
		mod:get(base .. "_G") or 0,
		mod:get(base .. "_B") or 0,
	}
end

mod.refresh_settings = function()
	local s = mod.settings
	s.box_enabled = mod:get("a9_box_enabled")
	s.box_thickness = mod:get("a9_box_thickness") or 2
	s.box_colour = colour("a9_box_colour", "a9_box_opacity")
	s.slam_duration = mod:get("a9_slam_duration") or 0.2
	s.lines_enabled = mod:get("a9_lines_enabled")
	s.lines_thickness = mod:get("a9_lines_thickness") or 2
	s.lines_match_box = mod:get("a9_lines_match_box")
	if s.lines_match_box then
		local b = s.box_colour
		s.lines_colour = { b[1], b[2], b[3], b[4] }
	else
		s.lines_colour = colour("a9_lines_colour", "a9_lines_opacity")
	end
	s.outline_match_lines = mod:get("a9_outline_match_lines")
	if s.outline_match_lines then
		local l = s.lines_colour
		s.outline_colour = { l[1], l[2], l[3], l[4] }
	else
		s.outline_colour = {
			255,
			mod:get("a9_outline_colour_R") or 255,
			mod:get("a9_outline_colour_G") or 0,
			mod:get("a9_outline_colour_B") or 0,
		}
	end
	s.outline_priority = mod:get("a9_outline_priority") or 0

	s.scanner_enabled = mod:get("a9_scanner_enabled")
	s.scanner_x = mod:get("a9_scanner_x") or 720
	s.scanner_y = mod:get("a9_scanner_y") or 600
	s.scanner_size = mod:get("a9_scanner_size") or 24
	s.scanner_colour = {
		255,
		mod:get("a9_scanner_colour_R") or 255,
		mod:get("a9_scanner_colour_G") or 176,
		mod:get("a9_scanner_colour_B") or 0,
	}

	s.tag_enabled = mod:get("a9_tag_enabled")
	s.tag_own_only = mod:get("a9_tag_own_only")
	s.tag_whirr = mod:get("a9_tag_whirr")

	s.exec_enabled = mod:get("a9_exec_enabled")
	s.exec_parallel = mod:get("a9_exec_parallel")

	s.mark_arbites = mod:get("a9_mark_arbites")
	s.mark_psyker = mod:get("a9_mark_psyker")
	s.mark_skitarii = mod:get("a9_mark_skitarii")
	s.mark_broker = mod:get("a9_mark_broker")

	mod.target.SLAM_DURATION = s.slam_duration
end

mod.on_setting_changed = function()
	mod.refresh_settings()
	if mod.outline then
		mod.outline.refresh()
	end
end

mod.on_all_mods_loaded = function()
	mod:info(mod.version)
	mod.refresh_settings()
	if mod.outline then
		mod.outline.refresh()
	end
	mod.stance.init(mod)
	if mod.eligibility then
		mod.eligibility.init()
	end
	if mod.credits_names then
		mod.credits_names.init()
	end
	if mod.tag then
		mod.tag.init(mod)
	end
	if mod.exec_stance then
		mod.exec_stance.init(mod)
	end
	if mod.focus_stance then
		mod.focus_stance.init()
	end
end

mod.on_game_state_changed = function(status, _state_name)
	cached_archetype = nil
	cached_archetype_unit = nil
	if status == "exit" then
		if mod.stance then
			mod.stance.reset()
		end
		if mod.tag then
			mod.tag.reset()
		end
		if mod.exec_stance then
			mod.exec_stance.reset()
		end
		if mod.focus_stance then
			mod.focus_stance.reset()
		end
		if mod.mark_capture then
			local dropped = mod.mark_capture.clear_all()
			if mod.outline then
				local mark = mod.outline.MARK_NAME
				for i = 1, #dropped do
					mod.outline.remove(dropped[i], mark)
				end
			end
		end
	end
end
