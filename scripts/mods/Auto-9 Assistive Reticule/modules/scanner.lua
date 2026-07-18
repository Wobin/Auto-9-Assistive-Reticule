local math_floor = math.floor

local scanner = {}

scanner.GLYPHS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#%&*"

local function glyph_at(pos, tick, glyphs)
	local n = #glyphs
	local h = (pos * 73856093 + tick * 19349663) % n
	return glyphs:sub(h + 1, h + 1)
end

scanner.scramble = function(target, elapsed, duration, glyphs)
	glyphs = glyphs or scanner.GLYPHS
	local n = #target
	if n == 0 or elapsed >= duration then
		return target
	end
	local revealed = math_floor((elapsed / duration) * n)
	local tick = math_floor(elapsed * 30)
	local out = {}
	for i = 1, n do
		local ch = target:sub(i, i)
		if ch == " " then
			out[i] = " "
		elseif i <= revealed then
			out[i] = ch
		else
			out[i] = glyph_at(i, tick, glyphs)
		end
	end
	return table.concat(out)
end

scanner.dots = function(elapsed, period)
	period = period or 0.4
	local phase = math_floor(elapsed / period + 1e-9) % 4
	return string.rep(".", phase)
end

scanner.split_labels = function(csv)
	local items = {}
	if type(csv) ~= "string" then
		return items
	end
	for item in csv:gmatch("[^,]+") do
		item = item:match("^%s*(.-)%s*$")
		if item ~= "" then
			items[#items + 1] = item
		end
	end
	return items
end

return scanner
