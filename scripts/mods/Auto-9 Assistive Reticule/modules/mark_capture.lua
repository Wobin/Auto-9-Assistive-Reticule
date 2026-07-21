local mark_capture = {}

local sets = {}

local EMPTY = {}

local keys = setmetatable({}, { __mode = "k" })

local function key_for(row)
	if not row then
		return nil
	end
	local key = keys[row]
	if not key then
		key = tostring(row.archetype) .. "/" .. tostring(row.outline)
		keys[row] = key
	end
	return key
end

mark_capture.capture = function(row, unit)
	local key = key_for(row)
	if not key or not unit then
		return
	end
	local set = sets[key]
	if not set then
		set = {}
		sets[key] = set
	end
	set[unit] = true
end

mark_capture.uncapture = function(row, unit)
	local key = key_for(row)
	if not key or not unit then
		return false
	end
	local set = sets[key]
	if not set or not set[unit] then
		return false
	end
	set[unit] = nil
	return true
end

mark_capture.pending_set = function(row)
	local key = key_for(row)
	if not key then
		return nil
	end
	return sets[key]
end

mark_capture.prune = function(row, is_enemy_unit)
	local key = key_for(row)
	if not key or not is_enemy_unit then
		return EMPTY
	end
	local set = sets[key]
	if not set then
		return EMPTY
	end
	local dropped = nil
	for unit in pairs(set) do
		if not is_enemy_unit(unit) then
			dropped = dropped or {}
			dropped[#dropped + 1] = unit
		end
	end
	if not dropped then
		return EMPTY
	end
	for i = 1, #dropped do
		set[dropped[i]] = nil
	end
	return dropped
end

mark_capture.clear = function(row)
	local dropped = {}
	local key = key_for(row)
	if not key then
		return dropped
	end
	local set = sets[key]
	if not set then
		return dropped
	end
	for unit in pairs(set) do
		dropped[#dropped + 1] = unit
	end
	sets[key] = nil
	return dropped
end

mark_capture.clear_all = function()
	local dropped = {}
	for _, set in pairs(sets) do
		for unit in pairs(set) do
			dropped[#dropped + 1] = unit
		end
	end
	sets = {}
	return dropped
end

return mark_capture
