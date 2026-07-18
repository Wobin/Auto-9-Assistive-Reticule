local tag = {}

local ENEMY_GROUPS = {
	enemy = true,
	double_tag_enemy = true,
}

local tags = {}
local seq = 0

tag.on_create = function(tag_id, group, tagger_unit, target_unit)
	if not tag_id or not target_unit or not ENEMY_GROUPS[group] then
		return
	end
	seq = seq + 1
	tags[tag_id] = { unit = target_unit, tagger = tagger_unit, seq = seq }
end

tag.on_remove = function(tag_id)
	if tag_id then
		tags[tag_id] = nil
	end
end

tag.reset = function()
	tags = {}
	seq = 0
end

tag.current_unit = function(own_only, local_player_unit)
	local best_seq = -1
	local best_unit = nil
	for _, rec in pairs(tags) do
		if rec.seq > best_seq and (not own_only or rec.tagger == local_player_unit) then
			best_seq = rec.seq
			best_unit = rec.unit
		end
	end
	return best_unit
end

tag.init = function(owner_mod)
	local ok, SmartTagSettings = pcall(require, "scripts/settings/smart_tag/smart_tag_settings")
	if not ok then
		SmartTagSettings = nil
	end
	local function group_of(template_name)
		local templates = SmartTagSettings and SmartTagSettings.templates
		local t = templates and templates[template_name]
		return t and t.group or nil
	end
	owner_mod:hook_safe("SmartTagSystem", "_create_tag_locally", function(_self, tag_id, template_name, tagger_unit, target_unit)
		tag.on_create(tag_id, group_of(template_name), tagger_unit, target_unit)
	end)
	owner_mod:hook_safe("SmartTagSystem", "_remove_tag_locally", function(_self, tag_id)
		tag.on_remove(tag_id)
	end)
end

return tag
