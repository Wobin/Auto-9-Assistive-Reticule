local exec_stance = {}

exec_stance.GRACE = 0.15
exec_stance.KEYWORD = "veteran_combat_ability_stance"

local active = false
local drop_at = nil
local pending = {}

local function is_stance(buff)
	if not buff or not buff.template then
		return false
	end
	local template = buff:template()
	local keywords = template and template.keywords
	if not keywords then
		return false
	end
	for i = 1, #keywords do
		if keywords[i] == exec_stance.KEYWORD then
			return true
		end
	end
	return false
end

exec_stance.on_buff_added = function(buff)
	if not is_stance(buff) then
		return
	end
	active = true
	drop_at = nil
	pending = {}
end

exec_stance.on_buff_removed = function(buff)
	if not is_stance(buff) then
		return
	end
	if active and not drop_at then
		drop_at = false
	end
end

exec_stance.update = function(t)
	if drop_at == false then
		drop_at = t + exec_stance.GRACE
	end
	if drop_at and drop_at ~= false and t >= drop_at then
		active = false
		drop_at = nil
	end
end

exec_stance.is_active = function()
	return active
end

exec_stance.reset = function()
	active = false
	drop_at = nil
	pending = {}
end

exec_stance.capture = function(unit)
	if unit then
		pending[unit] = true
	end
end

exec_stance.pending_set = function()
	return pending
end

exec_stance.order_by_x = function(units, screen_x_of)
	local out = {}
	local xs = {}
	for unit in pairs(units) do
		local x = screen_x_of(unit)
		if x then
			out[#out + 1] = unit
			xs[unit] = x
		end
	end
	table.sort(out, function(a, b)
		return xs[a] < xs[b]
	end)
	return out
end

exec_stance.init = function(_mod)
	local player_manager = Managers.player
	local function is_local_player(player)
		local local_player = player_manager:local_player_safe(1)
		return local_player ~= nil and player == local_player
	end
	local listener = {}
	listener.event_player_buff_added = function(_self, player, buff)
		if is_local_player(player) then
			exec_stance.on_buff_added(buff)
		end
	end
	listener.event_player_buff_removed = function(_self, player, buff)
		if is_local_player(player) then
			exec_stance.on_buff_removed(buff)
		end
	end
	exec_stance._listener = listener
	Managers.event:register(listener, "event_player_buff_added", "event_player_buff_added")
	Managers.event:register(listener, "event_player_buff_removed", "event_player_buff_removed")
end

return exec_stance
