local keyword_stance = {}

local DEFAULT_GRACE = 0.15

keyword_stance.new = function(keyword, optional_grace)
	local detector = {}
	detector.KEYWORD = keyword
	detector.GRACE = optional_grace or DEFAULT_GRACE

	local active = false
	local drop_at = nil

	local function matches(buff)
		if not buff or not buff.template then
			return false
		end
		local template = buff:template()
		local keywords = template and template.keywords
		if not keywords then
			return false
		end
		for i = 1, #keywords do
			if keywords[i] == detector.KEYWORD then
				return true
			end
		end
		return false
	end

	detector.on_buff_added = function(buff)
		if not matches(buff) then
			return
		end
		active = true
		drop_at = nil
	end

	detector.on_buff_removed = function(buff)
		if not matches(buff) then
			return
		end
		if active and not drop_at then
			drop_at = false
		end
	end

	detector.update = function(t)
		if drop_at == false then
			drop_at = t + detector.GRACE
		end
		if drop_at and drop_at ~= false and t >= drop_at then
			active = false
			drop_at = nil
		end
	end

	detector.is_active = function()
		return active
	end

	detector.reset = function()
		active = false
		drop_at = nil
	end

	detector.init = function()
		local player_manager = Managers.player
		local function is_local_player(player)
			local local_player = player_manager:local_player_safe(1)
			return local_player ~= nil and player == local_player
		end
		local listener = {}
		listener.event_player_buff_added = function(_self, player, buff)
			if is_local_player(player) then
				detector.on_buff_added(buff)
			end
		end
		listener.event_player_buff_removed = function(_self, player, buff)
			if is_local_player(player) then
				detector.on_buff_removed(buff)
			end
		end
		detector._listener = listener
		Managers.event:register(listener, "event_player_buff_added", "event_player_buff_added")
		Managers.event:register(listener, "event_player_buff_removed", "event_player_buff_removed")
	end

	return detector
end

return keyword_stance
