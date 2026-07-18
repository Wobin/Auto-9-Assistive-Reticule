
local mod = get_mod("Auto-9 Assistive Reticule")

local ScriptUnit = ScriptUnit
local Managers = Managers

local eligibility = {}

local cached = nil

local function compute()
	local player = Managers.player:local_player_safe(1)
	local player_unit = player and player.player_unit
	if not player_unit then
		return nil
	end
	local profile = player:profile()
	if not (profile and profile.archetype) then
		return nil
	end
	if profile.archetype.name ~= "cryptic" then
		return false
	end
	local ability_extension = ScriptUnit.has_extension(player_unit, "ability_system")
	if not ability_extension then
		return nil
	end
	local abilities = ability_extension:equipped_abilities()
	if not abilities then
		return nil
	end
	local combat_ability = abilities.combat_ability
	return (combat_ability and combat_ability.name == "cryptic_precision_stance") or false
end

eligibility.get = function()
	if cached == nil then
		cached = compute()
	end
	return cached
end

eligibility.invalidate = function()
	cached = nil
end

eligibility.init = function()
	mod:hook_safe("PlayerUnitAbilityExtension", "equip_ability", function(_self, ability_type)
		if ability_type == "combat_ability" then
			eligibility.invalidate()
		end
	end)
end

return eligibility
