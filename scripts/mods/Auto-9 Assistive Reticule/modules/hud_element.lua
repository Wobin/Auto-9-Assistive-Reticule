
local mod = get_mod("Auto-9 Assistive Reticule")

local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UIScenegraph = require("scripts/managers/ui/ui_scenegraph")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local Action = require("scripts/utilities/action/action")
local WeaponTemplate = require("scripts/utilities/weapon/weapon_template")

local sequence = mod:io_dofile("Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/modules/sequence")

local ScriptUnit = ScriptUnit
local Camera = Camera
local Quaternion = Quaternion
local Vector3 = Vector3
local Vector3Box = Vector3Box
local Managers = Managers

local SETTLE = 0.0
local SWEEP_DURATION = 0.4
local ARRIVE = 5
local math_min = math.min
local SW = 1920
local SH = 1080
local SLIDE_MARGIN = 300
local WHIRR_EVENT = "wwise/events/player/play_ability_cryptic_precision_stance_target"
local SCRAMBLE_DURATION = 0.4
local DOTS_PERIOD = 0.4
local SCANNER_X = 720
local SCANNER_Y = 600
local SCANNER_OUTLINE_OFFSETS = { { -2, 0 }, { 2, 0 }, { 0, -2 }, { 0, 2 }, { -2, -2 }, { 2, -2 }, { -2, 2 }, { 2, 2 } }
local SCANNER_POS = { 0, 0, 3 }
local SCANNER_SIZE = { 800, 0 }
local SCANNER_BLACK = { 0, 0, 0, 0 }
local SCANNER_OPTS = {}
local TAG_DATA = {}

local HudElementAuto9Reticule = class("HudElementAuto9Reticule", "HudElementBase")

local scenegraph_definition = {
	screen = UIWorkspaceSettings.screen,
}

local definitions = {
	scenegraph_definition = scenegraph_definition,
	widget_definitions = {},
}

local function project_world(pos, ctx)
	local to = Vector3.normalize(pos - ctx.camera_position)
	if Vector3.dot(ctx.camera_direction, to) <= 0 then
		return nil
	end
	local screen = Camera.world_to_screen(ctx.camera, pos)
	return (screen.x - ctx.screen_offset_x) * ctx.inverse_scale, (screen.y - ctx.screen_offset_y) * ctx.inverse_scale
end

local function slide_origin(prev_wpos, ctx, gx, gy)
	if not prev_wpos then
		return gx, gy
	end
	local p = prev_wpos:unbox()
	local ox, oy = project_world(p, ctx)
	if ox then
		return ox, oy
	end
	local to_x = p.x - ctx.camera_position.x
	local to_y = p.y - ctx.camera_position.y
	local right_dot = ctx.camera_direction.y * to_x - ctx.camera_direction.x * to_y
	if right_dot >= 0 then
		return SW + SLIDE_MARGIN, gy
	end
	return -SLIDE_MARGIN, gy
end

local function is_reloading(player_unit)
	local unit_data = ScriptUnit.has_extension(player_unit, "unit_data_system")
	if not unit_data then
		return false
	end
	local weapon_action_component = unit_data:read_component("weapon_action")
	local weapon_template = WeaponTemplate.current_weapon_template(weapon_action_component)
	local _, action_settings = Action.current_action(weapon_action_component, weapon_template)
	return sequence.is_reload_kind(action_settings and action_settings.kind)
end

HudElementAuto9Reticule.init = function(self, parent, draw_layer, start_scale)
	HudElementAuto9Reticule.super.init(self, parent, draw_layer, start_scale, definitions)

	self._cached_unit = nil
	self._cached_nodes = nil
	self._cached_breed = nil

	self._lock_unit = nil
	self._lock_t = nil
	self._cross = nil
	self._cross_origin = nil
	self._cross_t0 = nil
	self._prev_wpos = nil
	self._ol_unit = nil
	self._locked_unit = nil
	self._focused_unit = nil
	self._tag_driven = nil
	self._whirr_unit = nil
	self._scanner_unit = nil
	self._scanner_t = nil

	self._was_eligible = nil
end

local function breed_for(unit)
	local extension = ScriptUnit.has_extension(unit, "unit_data_system")
	if not extension then
		return nil
	end
	return extension:breed()
end

HudElementAuto9Reticule._refresh_cache = function(self, unit)
	if not unit then
		self._cached_unit = nil
		self._cached_nodes = nil
		self._cached_breed = nil
		return
	end

	local alive_lookup = rawget(_G, "HEALTH_ALIVE")
	local is_alive = alive_lookup and alive_lookup[unit]

	if unit == self._cached_unit then
		if not is_alive then
			self._cached_unit = nil
			self._cached_nodes = nil
			self._cached_breed = nil
		end
		return
	end

	self._cached_unit = nil
	self._cached_nodes = nil
	self._cached_breed = nil

	if not is_alive then
		return
	end

	self._cached_unit = unit
	self._cached_nodes = mod.project.nodes_for(unit)
	self._cached_breed = breed_for(unit)
end

HudElementAuto9Reticule._drop_outline = function(self)
	if self._ol_unit then
		local outline = mod.outline
		if outline then
			outline.remove(self._ol_unit)
		end
		self._ol_unit = nil
	end
end

HudElementAuto9Reticule._update_targeting = function(self, t)
	local stance = mod.stance
	local target = mod.target
	local eligibility = mod.eligibility
	if not stance or not target or not eligibility then
		return
	end

	local eligible = eligibility.get()
	if eligible == false and self._was_eligible then
		self:_drop_outline()
		self._lock_unit = nil
		self._lock_t = nil
		self._cross = nil
		self._cross_origin = nil
		self._cross_t0 = nil
		self._prev_wpos = nil
		self._locked_unit = nil
		target.reset()
	end
	if eligible ~= nil then
		self._was_eligible = eligible
	end
	local s = mod.settings
	local tag_enabled = s and s.tag_enabled
	if not eligible and not tag_enabled then
		return
	end

	stance.update(t)

	local parent = self._parent
	local player_unit = parent and parent:player_unit()
	local local_player = Managers.player and Managers.player:local_player_safe(1)
	local local_player_unit = local_player and local_player.player_unit

	local tagged = nil
	if tag_enabled and mod.tag then
		tagged = mod.tag.current_unit(s.tag_own_only, local_player_unit)
	end
	self._tag_driven = tagged ~= nil

	if tagged ~= self._whirr_unit then
		if tagged and s.tag_whirr then
			local ui = Managers.ui
			if ui and ui.play_2d_sound then
				ui:play_2d_sound(WHIRR_EVENT)
			end
		end
		self._whirr_unit = tagged
	end

	local active, data
	if tagged then
		TAG_DATA.unit = tagged
		active, data = true, TAG_DATA
	elseif eligible and stance.is_active() then
		active = true
		data = player_unit and target.read_targeting_data(player_unit) or nil
	else
		active, data = false, nil
	end

	target.update(t, active, data)

	local state = target.state()
	if state == target.SLAM or state == target.LOCKED then
		self:_refresh_cache(target.unit())
	else
		self:_refresh_cache(nil)
	end

	local locked_unit = nil
	if active then
		local held = nil
		if self._locked_unit and player_unit and is_reloading(player_unit) then
			local health_alive = rawget(_G, "HEALTH_ALIVE")
			if health_alive and health_alive[self._locked_unit] then
				held = self._locked_unit
			end
		end
		if held then
			locked_unit = held
		elseif state == target.LOCKED then
			locked_unit = target.unit()
		end
	end
	self._locked_unit = locked_unit
end

HudElementAuto9Reticule.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	HudElementAuto9Reticule.super.update(self, dt, t, ui_renderer, render_settings, input_service)

	local ok, err = pcall(self._update_targeting, self, t)
	if not ok then
		mod:error("Auto-9 Assistive Reticule targeting update failed: " .. tostring(err))
	end
end

local function mod_active(self)
	if self._was_eligible then
		return true
	end
	local s = mod.settings
	return s ~= nil and s.tag_enabled == true
end

HudElementAuto9Reticule._draw_box = function(self, ui_renderer, t)
	if not mod_active(self) then
		return
	end

	local s = mod.settings
	local target = mod.target
	local project = mod.project
	local outline = mod.outline
	if not target or not project then
		return
	end

	local state = target.state()
	local player = Managers.player:local_player_safe(1)
	local player_unit = player and player.player_unit

	if not s or not s.box_enabled or state == target.IDLE or not player_unit then
		self._lock_unit = nil
		self._lock_t = nil
		self._cross = nil
		self._cross_origin = nil
		self._cross_t0 = nil
		self._prev_wpos = nil
		self._focused_unit = nil
		self:_drop_outline()
		return
	end

	local unit = target.unit()

	local stance = mod.stance
	local health_alive = rawget(_G, "HEALTH_ALIVE")
	local reloading = false
	if stance and stance.is_active()
		and self._lock_unit and health_alive and health_alive[self._lock_unit]
		and is_reloading(player_unit) then
		unit = self._lock_unit
		reloading = true
	end

	if not unit then
		self._lock_t = nil
		self:_drop_outline()
		return
	end

	if reloading then
		if self._ol_unit ~= unit and outline then
			if self._ol_unit then
				outline.remove(self._ol_unit)
			end
			if outline.add(unit) then
				self._ol_unit = unit
			end
		end
		return
	end

	local nodes = self._cached_nodes
	if not nodes then
		if self._ol_unit and not (health_alive and health_alive[self._ol_unit]) then
			self:_drop_outline()
		end
		return
	end

	local parent = self._parent
	local camera = parent and parent:player_camera()
	if not camera then
		return
	end

	local camera_position = Camera.local_position(camera)
	local camera_direction = Quaternion.forward(Camera.local_rotation(camera))
	local scale = ui_renderer.scale
	local inverse_scale = ui_renderer.inverse_scale
	local screen_position = UIScenegraph.world_position(self._ui_scenegraph, "screen", scale)

	local ctx = {
		camera = camera,
		camera_position = camera_position,
		camera_direction = camera_direction,
		screen_offset_x = screen_position.x,
		screen_offset_y = screen_position.y,
		inverse_scale = inverse_scale,
	}

	local gx, gy, half_w, half_h, mid_wpos = project.box_for(ctx, unit, nodes, self._cached_breed)
	if not gx then
		return
	end

	local progress = target.slam_progress(t)
	local eased = sequence.ease_out(progress)
	local w, h = project.lerp_slam_size(half_w, half_h, eased)

	if unit ~= self._lock_unit then
		local ox, oy = slide_origin(self._prev_wpos, ctx, gx, gy)
		self._cross = { x = ox, y = oy }
		self._cross_origin = { x = ox, y = oy }
		self._cross_t0 = t
		self._lock_unit = unit
		self._lock_t = nil
		self._focused_unit = nil
	end

	if mid_wpos then
		if self._prev_wpos then
			self._prev_wpos:store(mid_wpos)
		else
			self._prev_wpos = Vector3Box(mid_wpos)
		end
	end

	local origin = self._cross_origin
	if origin and SWEEP_DURATION > 0 then
		local u = math_min(1, (t - (self._cross_t0 or t)) / SWEEP_DURATION)
		local e = u * u * (3 - 2 * u)
		self._cross = self._cross or { x = gx, y = gy }
		self._cross.x = origin.x + (gx - origin.x) * e
		self._cross.y = origin.y + (gy - origin.y) * e
	else
		self._cross = { x = gx, y = gy }
	end

	local has_arrived = sequence.arrived(self._cross.x, self._cross.y, gx, gy, ARRIVE)
	local is_locked = state == target.LOCKED
	if is_locked then
		self._lock_t = self._lock_t or t
	else
		self._lock_t = nil
	end
	local settled = sequence.settled(is_locked, self._lock_t, t, SETTLE, has_arrived)
	if self._tag_driven and self._focused_unit == unit then
		settled = true
	end

	if settled then
		self._focused_unit = unit
		if self._ol_unit ~= unit and outline then
			if self._ol_unit then
				outline.remove(self._ol_unit)
			end
			if outline.add(unit) then
				self._ol_unit = unit
			end
		end
		return
	end

	self:_drop_outline()

	local box_thickness = s.box_thickness or 2

	if s.lines_enabled then
		local lines_thickness = s.lines_thickness or 2
		local line_colour = s.lines_colour
		UIRenderer.draw_rect(ui_renderer, Vector3(0, self._cross.y - lines_thickness * 0.5, 2), Vector3(SW, lines_thickness, 1), line_colour)
		UIRenderer.draw_rect(ui_renderer, Vector3(self._cross.x - lines_thickness * 0.5, 0, 2), Vector3(lines_thickness, SH, 1), line_colour)
	end

	local x = gx - w * 0.5
	local y = gy - h * 0.5
	local colour = s.box_colour
	UIRenderer.draw_rect(ui_renderer, Vector3(x, y, 1), Vector3(w, box_thickness, 1), colour)
	UIRenderer.draw_rect(ui_renderer, Vector3(x, y + h - box_thickness, 1), Vector3(w, box_thickness, 1), colour)
	UIRenderer.draw_rect(ui_renderer, Vector3(x, y, 1), Vector3(box_thickness, h, 1), colour)
	UIRenderer.draw_rect(ui_renderer, Vector3(x + w - box_thickness, y, 1), Vector3(box_thickness, h, 1), colour)
end

HudElementAuto9Reticule._draw_scanner = function(self, ui_renderer, t)
	if not mod_active(self) then
		return
	end
	local s = mod.settings
	if not s or not s.scanner_enabled then
		return
	end
	local target = mod.target
	if not target or target.state() == target.IDLE then
		self._scanner_unit = nil
		return
	end
	local scanner = mod.scanner
	local credits_names = mod.credits_names
	if not scanner or not credits_names then
		return
	end

	local text
	local locked_unit = self._locked_unit
	if locked_unit then
		if locked_unit ~= self._scanner_unit then
			self._scanner_unit = locked_unit
			self._scanner_t = t
		end
		local name = credits_names.name_for(locked_unit)
		local resolved = scanner.scramble(name, t - (self._scanner_t or t), SCRAMBLE_DURATION)
		text = "SUBJECT: " .. resolved .. " / WANTED"
	else
		self._scanner_unit = nil
		text = "SCANNING" .. scanner.dots(t, DOTS_PERIOD)
	end

	local font_size = s.scanner_size or 24
	local colour = s.scanner_colour
	SCANNER_BLACK[1] = colour[1]
	SCANNER_SIZE[2] = font_size * 1.5
	local x, y = s.scanner_x or SCANNER_X, s.scanner_y or SCANNER_Y
	for i = 1, #SCANNER_OUTLINE_OFFSETS do
		local o = SCANNER_OUTLINE_OFFSETS[i]
		SCANNER_POS[1] = x + o[1]
		SCANNER_POS[2] = y + o[2]
		UIRenderer.draw_text(ui_renderer, text, font_size, "mono_tide_regular", SCANNER_POS, SCANNER_SIZE, SCANNER_BLACK, SCANNER_OPTS)
	end
	SCANNER_POS[1] = x
	SCANNER_POS[2] = y
	UIRenderer.draw_text(ui_renderer, text, font_size, "mono_tide_regular", SCANNER_POS, SCANNER_SIZE, colour, SCANNER_OPTS)
end

HudElementAuto9Reticule._draw_widgets = function(self, dt, t, input_service, ui_renderer, render_settings)
	HudElementAuto9Reticule.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)

	local ok, err = pcall(self._draw_box, self, ui_renderer, t)
	if not ok then
		mod:error("Auto-9 Assistive Reticule box draw failed: " .. tostring(err))
	end

	local ok2, err2 = pcall(self._draw_scanner, self, ui_renderer, t)
	if not ok2 then
		mod:error("Auto-9 Assistive Reticule scanner draw failed: " .. tostring(err2))
	end
end

HudElementAuto9Reticule.destroy = function(self, ui_renderer)
	HudElementAuto9Reticule.super.destroy(self, ui_renderer)

	if mod.target then
		mod.target.reset()
	end

	if mod.outline and self._ol_unit then
		mod.outline.remove(self._ol_unit)
	end

	self._cached_unit = nil
	self._cached_nodes = nil
	self._cached_breed = nil

	self._lock_unit = nil
	self._lock_t = nil
	self._cross = nil
	self._cross_origin = nil
	self._cross_t0 = nil
	self._prev_wpos = nil
	self._ol_unit = nil
	self._locked_unit = nil
	self._focused_unit = nil
	self._tag_driven = nil
	self._whirr_unit = nil
	self._scanner_unit = nil
	self._scanner_t = nil
end

return HudElementAuto9Reticule
