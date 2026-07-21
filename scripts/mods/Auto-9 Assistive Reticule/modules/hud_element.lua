
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
local SWEEP_MIN = 0.08
local SWEEP_MAX = 0.4
local SWEEP_PER_PX = 0.0005
local ARRIVE = 5
local math_min = math.min
local math_max = math.max
local math_sqrt = math.sqrt
local SW = 1920
local SH = 1080
local SLIDE_MARGIN = 300
local EXEC_STEP = 0.16
local EXEC_BOX_TIME = 0.16
local WHIRR_EVENT = "wwise/events/player/play_ability_cryptic_precision_stance_target"
local math_random = math.random
local DEFAULT_LABEL_KEY = "a9_scanner_labels_default"
local ARCHETYPE_LABEL_KEYS = {
	veteran = "a9_scanner_labels_veteran",
	broker = "a9_scanner_labels_broker",
	adamant = "a9_scanner_labels_adamant",
	cryptic = "a9_scanner_labels_cryptic",
	zealot = "a9_scanner_labels_zealot",
	psyker = "a9_scanner_labels_psyker",
	ogryn = "a9_scanner_labels_ogryn",
}

local SCRAMBLE_DURATION = 0.4
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

local CTX = {
	camera = nil,
	camera_position = nil,
	camera_direction = nil,
	screen_offset_x = 0,
	screen_offset_y = 0,
	inverse_scale = 1,
}

local function fill_ctx(scenegraph, camera, ui_renderer)
	local screen_position = UIScenegraph.world_position(scenegraph, "screen", ui_renderer.scale)
	CTX.camera = camera
	CTX.camera_position = Camera.local_position(camera)
	CTX.camera_direction = Quaternion.forward(Camera.local_rotation(camera))
	CTX.screen_offset_x = screen_position.x
	CTX.screen_offset_y = screen_position.y
	CTX.inverse_scale = ui_renderer.inverse_scale
	return CTX
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

local health_alive = nil

local function refresh_health_alive()
	health_alive = rawget(_G, "HEALTH_ALIVE")
	return health_alive
end

local reload_t = nil
local reload_unit = nil
local reload_value = false

local function is_reloading(player_unit, t)
	if t ~= nil and reload_t == t and reload_unit == player_unit then
		return reload_value
	end
	local value = false
	local unit_data = ScriptUnit.has_extension(player_unit, "unit_data_system")
	if unit_data then
		local weapon_action_component = unit_data:read_component("weapon_action")
		local weapon_template = WeaponTemplate.current_weapon_template(weapon_action_component)
		local _, action_settings = Action.current_action(weapon_action_component, weapon_template)
		value = sequence.is_reload_kind(action_settings and action_settings.kind)
	end
	reload_t = t
	reload_unit = player_unit
	reload_value = value
	return value
end

local function is_player_unit(unit)
	local player_manager = Managers.player
	if not player_manager then
		return true
	end
	return player_manager:player_by_unit(unit) or nil
end

local function is_enemy_unit(unit)
	return mod.target and mod.target.is_enemy_unit(unit, is_player_unit, health_alive)
end

local function screen_x_of(unit)
	if not is_enemy_unit(unit) then
		return nil
	end
	local ox = project_world(Unit.world_position(unit, 1), CTX)
	return ox
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
	self._sweep_dur = nil
	self._prev_wpos = nil
	self._ol_unit = nil
	self._locked_unit = nil
	self._focused_unit = nil
	self._tag_driven = nil
	self._whirr_unit = nil
	self._exec_active = nil
	self._exec_marked = nil
	self._exec_next_t = nil
	self._exec_acq_times = nil
	self._mark_row = nil
	self._mark_acq_times = nil
	self._scanner_unit = nil
	self._scanner_t = nil
	self._archetype = nil
	self._label = nil
	self._text = nil
	self._text_key = nil

	self._was_eligible = nil
	self._pu = nil
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

	local alive_lookup = health_alive
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

HudElementAuto9Reticule._reset_lock_state = function(self)
	self:_drop_outline()
	self._lock_unit = nil
	self._lock_t = nil
	self._cross = nil
	self._cross_origin = nil
	self._cross_t0 = nil
	self._sweep_dur = nil
	self._prev_wpos = nil
	self._locked_unit = nil
	self._mark_row = nil
	self._focused_unit = nil
	if mod.target then
		mod.target.reset()
	end
end

HudElementAuto9Reticule._update_targeting = function(self, t)
	refresh_health_alive()

	local stance = mod.stance
	local target = mod.target
	local eligibility = mod.eligibility
	if not stance or not target or not eligibility then
		return
	end

	local eligible = eligibility.get()
	if eligible == false and self._was_eligible then
		self:_reset_lock_state()
	end
	if eligible ~= nil then
		self._was_eligible = eligible
	end
	local s = mod.settings
	if mod.exec_stance then
		mod.exec_stance.update(t)
	end
	local exec_active = (s and s.exec_enabled and mod.exec_stance and mod.exec_stance.is_active()) and true or false
	self._exec_active = exec_active

	if mod.focus_stance then
		mod.focus_stance.update(t)
	end

	local mark_row = mod.active_mark_row and mod.active_mark_row() or nil
	if self._mark_row and self._mark_row ~= mark_row and mod.mark_capture then
		local ended = mod.mark_capture.clear(self._mark_row)
		if mod.outline then
			local mark = mod.outline.MARK_NAME
			for i = 1, #ended do
				mod.outline.remove(ended[i], mark)
			end
		end
		self._mark_acq_times = nil
	end
	self._mark_row = mark_row

	if mark_row and mod.mark_capture then
		local dropped = mod.mark_capture.prune(mark_row, is_enemy_unit)
		if mod.outline then
			local mark = mod.outline.MARK_NAME
			for i = 1, #dropped do
				mod.outline.remove(dropped[i], mark)
			end
		end
	end

	local tag_enabled = s and s.tag_enabled
	if not eligible and not tag_enabled and not exec_active and not mark_row then
		return
	end

	stance.update(t)

	local parent = self._parent
	local player_unit = parent and parent:player_unit()
	local local_player = Managers.player and Managers.player:local_player_safe(1)
	local local_player_unit = local_player and local_player.player_unit

	if self._pu ~= nil and local_player_unit ~= self._pu then
		self:_reset_lock_state()
		if mod.mark_capture then
			local stale = mod.mark_capture.clear_all()
			if mod.outline then
				local mark = mod.outline.MARK_NAME
				for i = 1, #stale do
					mod.outline.remove(stale[i], mark)
				end
			end
			self._mark_acq_times = nil
		end
		if mod.outline and self._exec_marked then
			mod.outline.remove_all(self._exec_marked, mod.outline.MARK_NAME)
		end
		self._exec_marked = nil
		self._exec_acq_times = nil
		self._exec_next_t = nil
		if mod.exec_stance then
			mod.exec_stance.reset()
		end
	end
	self._pu = local_player_unit

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
		if self._locked_unit and player_unit and is_enemy_unit(self._locked_unit)
			and is_reloading(player_unit, t) then
			held = self._locked_unit
		end
		if held then
			locked_unit = held
		elseif state == target.LOCKED then
			local u = target.unit()
			if is_enemy_unit(u) then
				locked_unit = u
			end
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
	if self._exec_active or self._mark_row then
		return true
	end
	local s = mod.settings
	return s ~= nil and s.tag_enabled == true
end

HudElementAuto9Reticule._draw_box = function(self, ui_renderer, t)
	if self._exec_active then
		return
	end
	if not mod_active(self) then
		self._lock_unit = nil
		self._lock_t = nil
		self._cross = nil
		self._cross_origin = nil
		self._cross_t0 = nil
		self._sweep_dur = nil
		self._prev_wpos = nil
		self._focused_unit = nil
		self:_drop_outline()
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
	local player = Managers.player and Managers.player:local_player_safe(1)
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
	local reloading = false
	if stance and stance.is_active()
		and self._lock_unit and is_enemy_unit(self._lock_unit)
		and is_reloading(player_unit, t) then
		unit = self._lock_unit
		reloading = true
	end

	if not unit or not is_enemy_unit(unit) then
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

	local ctx = fill_ctx(self._ui_scenegraph, camera, ui_renderer)

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
		local dx = gx - ox
		local dy = gy - oy
		self._sweep_dur = math_min(SWEEP_MAX, math_max(SWEEP_MIN, math_sqrt(dx * dx + dy * dy) * SWEEP_PER_PX))
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
	local sweep_dur = self._sweep_dur or SWEEP_DURATION
	if origin and sweep_dur > 0 then
		local u = math_min(1, (t - (self._cross_t0 or t)) / sweep_dur)
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
	local mark_row = self._mark_row
	local exec_active = self._exec_active
	if not mark_row and not exec_active and (not target or target.state() == target.IDLE) then
		self._scanner_unit = nil
		self._text_key = nil
		return
	end
	local scanner = mod.scanner
	local credits_names = mod.credits_names
	if not scanner or not credits_names then
		return
	end

	if not self._archetype then
		self._archetype = mod.local_archetype and mod.local_archetype() or nil
	end

	local text
	local locked_unit = self._locked_unit
	local acq_times = (mark_row and self._mark_acq_times) or (exec_active and self._exec_acq_times) or nil
	if not locked_unit and acq_times then
		local newest, newest_at
		for unit, at in pairs(acq_times) do
			if newest_at == nil or at > newest_at then
				newest_at = at
				newest = unit
			end
		end
		if newest then
			locked_unit = newest
		end
	end
	if locked_unit then
		if locked_unit ~= self._scanner_unit then
			self._scanner_unit = locked_unit
			self._scanner_t = t
			self._text_key = nil
			local key = ARCHETYPE_LABEL_KEYS[self._archetype] or DEFAULT_LABEL_KEY
			local labels = scanner.split_labels(mod:localize(key))
			self._label = (#labels > 0 and labels[math_random(#labels)]) or "WANTED"
		end
		local name = credits_names.name_for(locked_unit, breed_for(locked_unit))
		local resolved = scanner.scramble(name, t - (self._scanner_t or t), SCRAMBLE_DURATION)
		if self._text_key ~= resolved or not self._text then
			self._text_key = resolved
			self._text = mod:localize("a9_scanner_subject") .. resolved .. " / " .. (self._label or "WANTED")
		end
		text = self._text
	else
		if self._scanner_unit then
			self._scanner_unit = nil
			self._text_key = nil
		end
		return
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

HudElementAuto9Reticule._draw_marks = function(self, ui_renderer, t, mark_row)
	local outline = mod.outline
	local project = mod.project
	local capture = mod.mark_capture
	if not outline or not project or not capture then
		return
	end
	local set = capture.pending_set(mark_row)
	if not set then
		return
	end

	self._mark_acq_times = self._mark_acq_times or {}
	local acq = self._mark_acq_times
	local mark = outline.MARK_NAME
	for unit in pairs(set) do
		if not acq[unit] and outline.add(unit, mark) then
			acq[unit] = t
		end
	end
	for unit in pairs(acq) do
		if not set[unit] then
			acq[unit] = nil
		end
	end

	local s = mod.settings
	if not s or not s.box_enabled then
		return
	end
	local parent = self._parent
	local camera = parent and parent:player_camera()
	if not camera then
		return
	end
	local ctx = fill_ctx(self._ui_scenegraph, camera, ui_renderer)

	local box_thickness = s.box_thickness or 2
	local colour = s.box_colour or { 255, 255, 0, 0 }
	for unit in pairs(set) do
		local at = acq[unit]
		if at and (t - at) <= EXEC_BOX_TIME and health_alive and health_alive[unit] then
			local nodes = project.nodes_for(unit)
			if nodes then
				local gx, gy, half_w, half_h = project.box_for(ctx, unit, nodes, breed_for(unit))
				if gx then
					local eased = sequence.ease_out((t - at) / EXEC_BOX_TIME)
					local w, h = project.lerp_slam_size(half_w, half_h, eased)
					local x = gx - w * 0.5
					local y = gy - h * 0.5
					UIRenderer.draw_rect(ui_renderer, Vector3(x, y, 1), Vector3(w, box_thickness, 1), colour)
					UIRenderer.draw_rect(ui_renderer, Vector3(x, y + h - box_thickness, 1), Vector3(w, box_thickness, 1), colour)
					UIRenderer.draw_rect(ui_renderer, Vector3(x, y, 1), Vector3(box_thickness, h, 1), colour)
					UIRenderer.draw_rect(ui_renderer, Vector3(x + w - box_thickness, y, 1), Vector3(box_thickness, h, 1), colour)
				end
			end
		end
	end
end

HudElementAuto9Reticule._draw_exec = function(self, ui_renderer, t)
	local mark_row = self._mark_row
	if mark_row then
		self:_draw_marks(ui_renderer, t, mark_row)
		return
	end
	if self._mark_acq_times then
		if mod.outline then
			local mark = mod.outline.MARK_NAME
			for unit in pairs(self._mark_acq_times) do
				mod.outline.remove(unit, mark)
			end
		end
		self._mark_acq_times = nil
	end
	local exec = mod.exec_stance
	local outline = mod.outline
	local project = mod.project
	if not self._exec_active or not exec or not outline or not project then
		if self._exec_marked then
			outline.remove_all(self._exec_marked, outline.MARK_NAME)
			self._exec_marked = nil
		end
		self._exec_next_t = nil
		self._exec_acq_times = nil
		return
	end

	local parent = self._parent
	local player = Managers.player and Managers.player:local_player_safe(1)
	local player_unit = player and player.player_unit
	local camera = parent and parent:player_camera()
	if not player_unit or not camera then
		return
	end

	self._exec_marked = self._exec_marked or {}

	local ctx = fill_ctx(self._ui_scenegraph, camera, ui_renderer)

	local ordered = exec.order_by_x(exec.pending_set(), screen_x_of)
	local s = mod.settings
	self._exec_acq_times = self._exec_acq_times or {}

	local mark = outline.MARK_NAME
	if s and s.exec_parallel then
		for i = 1, #ordered do
			local u = ordered[i]
			if not self._exec_marked[u] and outline.add(u, mark) then
				self._exec_marked[u] = true
				self._exec_acq_times[u] = t
			end
		end
	else
		self._exec_next_t = self._exec_next_t or t
		if t >= self._exec_next_t then
			for i = 1, #ordered do
				local u = ordered[i]
				if not self._exec_marked[u] then
					if outline.add(u, mark) then
						self._exec_marked[u] = true
						self._exec_acq_times[u] = t
					end
					break
				end
			end
			self._exec_next_t = t + EXEC_STEP
		end
	end

	local box_thickness = (s and s.box_thickness) or 2
	local colour = (s and s.box_colour) or { 255, 255, 0, 0 }
	for i = 1, #ordered do
		local u = ordered[i]
		local at = self._exec_acq_times[u]
		if at and (t - at) <= EXEC_BOX_TIME and health_alive and health_alive[u] then
			local nodes = project.nodes_for(u)
			if nodes then
				local gx, gy, half_w, half_h = project.box_for(ctx, u, nodes, breed_for(u))
				if gx then
					local eased = sequence.ease_out((t - at) / EXEC_BOX_TIME)
					local w, h = project.lerp_slam_size(half_w, half_h, eased)
					local x = gx - w * 0.5
					local y = gy - h * 0.5
					UIRenderer.draw_rect(ui_renderer, Vector3(x, y, 1), Vector3(w, box_thickness, 1), colour)
					UIRenderer.draw_rect(ui_renderer, Vector3(x, y + h - box_thickness, 1), Vector3(w, box_thickness, 1), colour)
					UIRenderer.draw_rect(ui_renderer, Vector3(x, y, 1), Vector3(box_thickness, h, 1), colour)
					UIRenderer.draw_rect(ui_renderer, Vector3(x + w - box_thickness, y, 1), Vector3(box_thickness, h, 1), colour)
				end
			end
		end
	end
end

HudElementAuto9Reticule._draw_widgets = function(self, dt, t, input_service, ui_renderer, render_settings)
	HudElementAuto9Reticule.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)

	refresh_health_alive()

	local ok, err = pcall(self._draw_all, self, ui_renderer, t)
	if not ok then
		mod:error("Auto-9 Assistive Reticule draw failed: " .. tostring(err))
	end
end

HudElementAuto9Reticule._draw_all = function(self, ui_renderer, t)
	self:_draw_box(ui_renderer, t)
	self:_draw_exec(ui_renderer, t)
	self:_draw_scanner(ui_renderer, t)
end

HudElementAuto9Reticule.destroy = function(self, ui_renderer)
	HudElementAuto9Reticule.super.destroy(self, ui_renderer)

	if mod.target then
		mod.target.reset()
	end

	if mod.outline and self._ol_unit then
		mod.outline.remove(self._ol_unit)
	end

	if mod.outline and self._exec_marked then
		mod.outline.remove_all(self._exec_marked, mod.outline.MARK_NAME)
	end

	if mod.outline and self._mark_acq_times then
		mod.outline.remove_all(self._mark_acq_times, mod.outline.MARK_NAME)
	end
	if mod.mark_capture then
		local stale = mod.mark_capture.clear_all()
		if mod.outline then
			local mark = mod.outline.MARK_NAME
			for i = 1, #stale do
				mod.outline.remove(stale[i], mark)
			end
		end
	end

	self._cached_unit = nil
	self._cached_nodes = nil
	self._cached_breed = nil

	self._lock_unit = nil
	self._lock_t = nil
	self._cross = nil
	self._cross_origin = nil
	self._cross_t0 = nil
	self._sweep_dur = nil
	self._prev_wpos = nil
	self._ol_unit = nil
	self._locked_unit = nil
	self._focused_unit = nil
	self._tag_driven = nil
	self._whirr_unit = nil
	self._exec_active = nil
	self._exec_marked = nil
	self._exec_next_t = nil
	self._exec_acq_times = nil
	self._mark_row = nil
	self._mark_acq_times = nil
	self._scanner_unit = nil
	self._scanner_t = nil
	self._archetype = nil
	self._label = nil
	self._text = nil
	self._text_key = nil
	self._pu = nil
end

return HudElementAuto9Reticule
