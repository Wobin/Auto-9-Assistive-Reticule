local math_min = math.min
local math_max = math.max

local target = {}

target.IDLE = "idle"
target.SWEEP = "sweep"
target.SLAM = "slam"
target.LOCKED = "locked"
target.RELEASE = "release"

target.LOSS_GRACE = 0.2
target.SLAM_DURATION = 0.2
target.RELEASE_DURATION = 0.15
target.RESLAM_FRACTION = 0.25

local state = target.IDLE
local current_unit = nil
local slam_started_at = 0
local slam_from = 0
local last_seen_at = 0
local release_started_at = 0

local function begin_slam(t, from)
	state = target.SLAM
	slam_started_at = t
	slam_from = from or 0
end

target.slam_progress = function(t)
	if state == target.LOCKED then
		return 1
	end
	if state ~= target.SLAM then
		return 0
	end
	if target.SLAM_DURATION <= 0 then
		return 1
	end
	local elapsed = t - slam_started_at
	local raw = slam_from + (elapsed / target.SLAM_DURATION)
	return math_min(1, math_max(0, raw))
end

target.update = function(t, stance_active, data)
	if not stance_active then
		if state == target.SLAM or state == target.LOCKED or state == target.SWEEP then
			state = target.RELEASE
			release_started_at = t
			current_unit = nil
		elseif state == target.RELEASE and t - release_started_at >= target.RELEASE_DURATION then
			state = target.IDLE
		end
		return state
	end

	if state == target.IDLE or state == target.RELEASE then
		state = target.SWEEP
		current_unit = nil
	end

	local unit = data and data.unit or nil

	if unit then
		last_seen_at = t
		if unit ~= current_unit then
			local from = (current_unit == nil) and 0 or (1 - target.RESLAM_FRACTION)
			current_unit = unit
			begin_slam(t, from)
		elseif state == target.SLAM and target.slam_progress(t) >= 1 then
			state = target.LOCKED
		end
		return state
	end

	if current_unit then
		if t - last_seen_at >= target.LOSS_GRACE then
			current_unit = nil
			state = target.SWEEP
		end
		return state
	end

	state = target.SWEEP
	return state
end

target.state = function()
	return state
end

target.unit = function()
	return current_unit
end

target.reset = function()
	state = target.IDLE
	current_unit = nil
	last_seen_at = 0
end

local ScriptUnit = ScriptUnit

target.read_targeting_data = function(player_unit)
	if not player_unit then
		return nil
	end
	local extension = ScriptUnit.has_extension(player_unit, "smart_targeting_system")
	if not extension then
		return nil
	end
	return extension:targeting_data()
end

return target
