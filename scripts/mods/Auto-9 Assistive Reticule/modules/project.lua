local math_abs = math.abs
local math_sqrt = math.sqrt

local Vector3 = rawget(_G, "Vector3")

local project = {}

local function offset_point(p, dx, dy, dz)
	if Vector3 then
		return Vector3(p.x + dx, p.y + dy, p.z + dz)
	end
	return { x = p.x + dx, y = p.y + dy, z = p.z + dz }
end

local NODE_LOW = "enemy_aim_target_01"
local NODE_MID = "enemy_aim_target_02"
local NODE_HIGH = "enemy_aim_target_03"

local DEFAULT_HALF_EXTENT_RIGHT = 0.3
local MIN_HEIGHT_ASPECT = 0.5

project.nodes_for = function(unit)
	local Unit = Unit
	local function node(name)
		if Unit.has_node(unit, name) then
			return Unit.node(unit, name)
		end
		return nil
	end
	local low, mid, high = node(NODE_LOW), node(NODE_MID), node(NODE_HIGH)
	if not mid or not high then
		return nil
	end
	return { low = low or 1, mid = mid, high = high }
end

project.box_from_positions = function(ctx, positions, half_extent_right)
	local Camera = Camera

	local mid = positions.mid
	if not mid then
		return nil
	end

	local low = positions.low or mid
	local high = positions.high or mid

	local camera_position = ctx.camera_position
	local camera_direction = ctx.camera_direction
	local to_target_x = mid.x - camera_position.x
	local to_target_y = mid.y - camera_position.y
	local to_target_z = mid.z - camera_position.z
	local forward_dot = camera_direction.x * to_target_x + camera_direction.y * to_target_y + camera_direction.z * to_target_z
	if forward_dot < 0 then
		return nil
	end
	if Camera.inside_frustum(ctx.camera, mid) <= 0 then
		return nil
	end

	local s_low = Camera.world_to_screen(ctx.camera, low)
	local s_high = Camera.world_to_screen(ctx.camera, high)
	local s_mid = Camera.world_to_screen(ctx.camera, mid)

	local half_h = math_abs(s_low.y - s_high.y) * 0.5
	if half_h <= 0 then
		return nil
	end

	local rx = camera_direction.y
	local ry = -camera_direction.x
	local r_len = math_sqrt(rx * rx + ry * ry)
	local half_w
	if r_len > 0 then
		rx = (rx / r_len) * half_extent_right
		ry = (ry / r_len) * half_extent_right
		local s_left = Camera.world_to_screen(ctx.camera, offset_point(mid, -rx, -ry, 0))
		local s_right = Camera.world_to_screen(ctx.camera, offset_point(mid, rx, ry, 0))
		half_w = math_abs(s_right.x - s_left.x) * 0.5
	else
		half_w = half_h
	end

	local min_half_h = half_w * MIN_HEIGHT_ASPECT
	if half_h < min_half_h then
		half_h = min_half_h
	end

	local inverse_scale = ctx.inverse_scale
	local cx = (s_mid.x - ctx.screen_offset_x) * inverse_scale
	local cy = (s_mid.y - ctx.screen_offset_y) * inverse_scale
	half_w = half_w * inverse_scale
	half_h = half_h * inverse_scale

	return cx, cy, half_w, half_h
end

project.box_for = function(ctx, unit, nodes, breed)
	local Unit = Unit
	if not nodes then
		return nil
	end
	local mid = Unit.world_position(unit, nodes.mid)
	local positions = {
		low = Unit.world_position(unit, nodes.low),
		mid = mid,
		high = Unit.world_position(unit, nodes.high),
	}
	local half_extent_right = (breed and breed.half_extent_right) or DEFAULT_HALF_EXTENT_RIGHT

	local cx, cy, half_w, half_h = project.box_from_positions(ctx, positions, half_extent_right)
	if not cx then
		return nil
	end
	return cx, cy, half_w, half_h, mid
end

project.SLAM_FULL_SIZE = 2000

project.lerp_slam_size = function(half_w, half_h, progress, full_size)
	full_size = full_size or project.SLAM_FULL_SIZE
	local w = full_size + (half_w * 2 - full_size) * progress
	local h = full_size + (half_h * 2 - full_size) * progress
	return w, h
end

return project
