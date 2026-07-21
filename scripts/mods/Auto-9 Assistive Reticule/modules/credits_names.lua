local math_random = math.random

local credits_names = {}

local CREDITS_PATH = "scripts/ui/views/credits_view/credits"

local OGRYN_NAMES = {
	"Agg", "Ank", "Barth", "Bertol", "Blor", "Bogra", "Bron", "Brug", "Dagg", "Dent", "Drabba", "Dragbo",
	"Drog", "Frug", "Hak", "Horg", "Igron", "Jabb", "Kront", "Nork", "Orod", "Punt", "Smasha", "Thuddo",
	"Torb", "Tug", "Vogg", "Vohn", "Yordo",
}

local MASTIFF_NAMES = {
	"Rogal", "Mell-0", "Relentless", "Nero", "Nalle", "Shadow", "Edd-3", "Russ", "M-01133", "Devil",
	"Deathbite", "J4-ZZ", "Justicar", "Charl-3", "Kill-Dog", "CHI-2", "Irontooth", "Foe-Mauler", "Judge",
	"Princeps", "Deadeye-IV", "41-F13", "Growler", "Ravager", "Macharius", "Sentinel-III", "Rex", "Irisi",
	"Freja", "Lex", "Arya", "8-UDD-4", "Apol-1O", "Oll-IV", "L3a", "Howler", "Ros-13", "Necksnapper",
	"Xheva", "Rashuns", "Adamant", "Eviscerator", "Regg-II", "Killer", "Mauler", "Blackmane", "Fury",
	"Zorin", "Nisa", "Throatripper", "Feral", "Puck", "Sir-I", "Harbinger", "H4-Vanna", "Dibu", "Dai-Z",
	"Sku-B3", "Smoke", "Grimm", "S4-NCH0", "Snarler", "Timor", "Champion", "Carrion", "Judgement-V",
	"Rampage", "Sal-II", "Wrath", "Hunter", "Iron-Death", "Rasp", "Unit-749", "Ludde", "Justice", "81-U3",
	"Aflor", "Raptor", "Else", "Executioner", "Grimnar", "Fangmaw", "Redclaw", "Dante", "Tracker-III",
	"Cerberus", "Harri", "Unni", "Gore", "Henroi", "Terror", "Deadmutt", "Monster", "Kira", "Gunnar",
	"Unit-392", "Woll-II", "Bjorn", "Fenrir", "Pursuit-IV", "Arrow", "Gut-Shredder", "Reine", "M15-CH4",
	"D13-G0", "Biter", "Håkan", "Bloodfang", "Deathgrip", "Kosm-05", "Steelmaw", "Signe", "Killripper",
	"Slaughter", "Gruff", "Cadia", "Bane", "Reeva", "Elin",
}

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
		return "ogryn"
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
	local seen = {}
	for i = 1, #pet_pool do
		seen[pet_pool[i]] = true
	end
	for i = 1, #MASTIFF_NAMES do
		local name = MASTIFF_NAMES[i]
		if not seen[name] then
			seen[name] = true
			pet_pool[#pet_pool + 1] = name
		end
	end
end

credits_names.random_name = function(style)
	if style == "ogryn" then
		return OGRYN_NAMES[math_random(#OGRYN_NAMES)]
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
