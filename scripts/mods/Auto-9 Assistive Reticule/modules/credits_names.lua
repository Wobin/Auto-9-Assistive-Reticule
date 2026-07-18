local math_random = math.random

local credits_names = {}

local CREDITS_PATH = "scripts/ui/views/credits_view/credits"

local first_pool = {}
local last_pool = {}

local name_cache = setmetatable({}, { __mode = "k" })

credits_names.build = function(credits)
	local firsts, lasts = {}, {}
	local seen_f, seen_l = {}, {}
	local function walk(t)
		if type(t) ~= "table" then
			return
		end
		if t.type == "person" and type(t.text) == "string" then
			local words = {}
			for w in t.text:gmatch("%S+") do
				words[#words + 1] = w
			end
			if #words >= 2 then
				local f, l = words[1], words[#words]
				if not seen_f[f] then
					seen_f[f] = true
					firsts[#firsts + 1] = f
				end
				if not seen_l[l] then
					seen_l[l] = true
					lasts[#lasts + 1] = l
				end
			end
		end
		for _, v in pairs(t) do
			if type(v) == "table" then
				walk(v)
			end
		end
	end
	walk(credits)
	return firsts, lasts
end

credits_names.init = function(optional_credits)
	local credits = optional_credits
	if credits == nil then
		local ok, required = pcall(require, CREDITS_PATH)
		credits = ok and required or nil
	end
	first_pool, last_pool = credits_names.build(credits or {})
end

credits_names.random_name = function()
	if #first_pool == 0 or #last_pool == 0 then
		return "Unknown Subject"
	end
	return first_pool[math_random(#first_pool)] .. " " .. last_pool[math_random(#last_pool)]
end

credits_names.name_for = function(unit)
	if not unit then
		return credits_names.random_name()
	end
	local name = name_cache[unit]
	if not name then
		name = credits_names.random_name()
		name_cache[unit] = name
	end
	return name
end

return credits_names
