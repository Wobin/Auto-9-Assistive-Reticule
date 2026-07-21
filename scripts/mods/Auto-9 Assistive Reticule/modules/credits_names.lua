local math_random = math.random

local credits_names = {}

local CREDITS_PATH = "scripts/ui/views/credits_view/credits"

local HOUND_BREEDS = {
	chaos_hound = true,
	chaos_armored_hound = true,
	chaos_hound_mutator = true,
	companion_dog = true,
}

local first_pool = {}
local last_pool = {}
local pet_pool = {}

local name_cache = setmetatable({}, { __mode = "k" })

local function is_pet_text(text)
	return text:find(",", 1, true) ~= nil or text:find("&", 1, true) ~= nil
end

credits_names.build = function(credits)
	local firsts, lasts, pets = {}, {}, {}
	local seen_f, seen_l, seen_p = {}, {}, {}
	local function walk(t)
		if type(t) ~= "table" then
			return
		end
		if t.type == "person" and type(t.text) == "string" then
			if is_pet_text(t.text) then
				for chunk in t.text:gmatch("[^,&]+") do
					local pet = chunk:match("^%s*(.-)%s*$")
					if pet ~= "" and not seen_p[pet] then
						seen_p[pet] = true
						pets[#pets + 1] = pet
					end
				end
			else
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
		end
		for _, v in pairs(t) do
			if type(v) == "table" then
				walk(v)
			end
		end
	end
	walk(credits)
	return firsts, lasts, pets
end

credits_names.style_for = function(breed)
	if not breed then
		return "full"
	end
	local tags = breed.tags
	if tags and tags.ogryn then
		return "surname"
	end
	local name = breed.name
	if name and HOUND_BREEDS[name] then
		return "pet"
	end
	return "full"
end

credits_names.init = function(optional_credits)
	local credits = optional_credits
	if credits == nil then
		local ok, required = pcall(require, CREDITS_PATH)
		credits = ok and required or nil
	end
	first_pool, last_pool, pet_pool = credits_names.build(credits or {})
end

credits_names.random_name = function(style)
	if style == "surname" then
		if #last_pool == 0 then
			return "Unknown Subject"
		end
		return last_pool[math_random(#last_pool)]
	end
	if style == "pet" then
		if #pet_pool == 0 then
			return "Unknown Subject"
		end
		return pet_pool[math_random(#pet_pool)]
	end
	if #first_pool == 0 or #last_pool == 0 then
		return "Unknown Subject"
	end
	return first_pool[math_random(#first_pool)] .. " " .. last_pool[math_random(#last_pool)]
end

credits_names.name_for = function(unit, breed)
	local style = credits_names.style_for(breed)
	if not unit then
		return credits_names.random_name(style)
	end
	local name = name_cache[unit]
	if not name then
		name = credits_names.random_name(style)
		name_cache[unit] = name
	end
	return name
end

return credits_names
