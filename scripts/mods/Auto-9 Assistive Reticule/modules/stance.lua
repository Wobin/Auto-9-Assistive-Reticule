local stance = {}

stance.GRACE = 0.15

local KEYWORD = "enable_auto_aim"

local active = false
local drop_at = nil

local function is_acd(buff)
	if not buff or not buff.template then
		return false
	end
	local template = buff:template()
	local keywords = template and template.keywords
	if not keywords then
		return false
	end
	for i = 1, #keywords do
		if keywords[i] == KEYWORD then
			return true
		end
	end
	return false
end

stance.on_buff_added = function(buff)
	if not is_acd(buff) then
		return
	end
	active = true
	drop_at = nil
end

stance.on_buff_removed = function(buff)
	if not is_acd(buff) then
		return
	end
	if active and not drop_at then
		drop_at = false
	end
end

stance.update = function(t)
	if drop_at == false then
		drop_at = t + stance.GRACE
	end
	if drop_at and drop_at ~= false and t >= drop_at then
		active = false
		drop_at = nil
	end
end

stance.is_active = function()
	return active
end

stance.reset = function()
	active = false
	drop_at = nil
end

stance.init = function(mod)
	local player_manager = Managers.player

	local function is_local_player(player)
		local local_player = player_manager:local_player_safe(1)
		return local_player ~= nil and player == local_player
	end

	mod.event_player_buff_added = function(_self, player, buff)
		if is_local_player(player) then
			stance.on_buff_added(buff)
		end
	end

	mod.event_player_buff_removed = function(_self, player, buff)
		if is_local_player(player) then
			stance.on_buff_removed(buff)
		end
	end

	Managers.event:register(mod, "event_player_buff_added", "event_player_buff_added")
	Managers.event:register(mod, "event_player_buff_removed", "event_player_buff_removed")
end

return stance
