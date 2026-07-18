
local math_exp = math.exp

local sequence = {}

sequence.ease_out = function(p)
	local inv = 1 - p
	return 1 - inv * inv * inv
end

sequence.slide_factor = function(dt, tau)
	return 1 - math_exp(-dt / tau)
end

sequence.arrived = function(cx, cy, gx, gy, r)
	local dx = cx - gx
	local dy = cy - gy
	return (dx * dx + dy * dy) < (r * r)
end

sequence.settled = function(is_locked, lock_t, t, settle, has_arrived)
	if not is_locked or not lock_t or not has_arrived then
		return false
	end
	return (t - lock_t) >= settle
end

local RELOAD_KINDS = {
	reload_shotgun = true,
	reload_state = true,
	ranged_load_special = true,
}

sequence.is_reload_kind = function(kind)
	return RELOAD_KINDS[kind] == true
end

return sequence
