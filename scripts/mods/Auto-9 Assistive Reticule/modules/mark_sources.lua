local mark_sources = {}

mark_sources.ROWS = {
	{
		outline = "adamant_mark_target",
		archetype = "adamant",
		kind = "passive",
		setting = "mark_arbites",
	},
	{
		outline = "psyker_marked_target",
		archetype = "psyker",
		kind = "passive",
		setting = "mark_psyker",
	},
	{
		outline = "broker_proximity_target",
		archetype = "cryptic",
		kind = "passive",
		setting = "mark_skitarii",
	},
	{
		outline = "broker_proximity_target",
		archetype = "broker",
		kind = "stance",
		keyword = "broker_combat_ability_focus",
		setting = "mark_broker",
	},
}

mark_sources.NAMES = {}
for i = 1, #mark_sources.ROWS do
	mark_sources.NAMES[mark_sources.ROWS[i].outline] = true
end

mark_sources.row_for = function(outline_name, archetype)
	if not outline_name or not archetype then
		return nil
	end
	local rows = mark_sources.ROWS
	for i = 1, #rows do
		local row = rows[i]
		if row.outline == outline_name and row.archetype == archetype then
			return row
		end
	end
	return nil
end

return mark_sources
