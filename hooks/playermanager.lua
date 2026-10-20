Hooks:PostHook(PlayerManager, "on_killshot", "CODWP_OnKillshot", function(self, killed_unit, variant, headshot, weapon_id)
	local killed_base = alive(killed_unit) and killed_unit:base()
	if killed_base and killed_base._tweak_table and CopDamage.is_civilian(killed_base._tweak_table) then
		return
	end

	local weapon_base = CODWP.equipped_base()
	if weapon_base and weapon_base.codwp_on_kill then
		weapon_base:codwp_on_kill(killed_unit, variant)
	end
end)

-- Fast Reload Kill and Speed Up Kill trigger on every point of damage the local player deals.
Hooks:PostHook(PlayerManager, "on_damage_dealt", "CODWP_OnDamageDealt", function(self, unit, damage_info)
	if not damage_info or (damage_info.damage or 0) <= 0 then
		return
	end

	if damage_info.variant and damage_info.variant ~= "bullet" then
		return
	end

	local weapon_base = CODWP.equipped_base()
	if weapon_base and weapon_base.codwp_on_damage_dealt then
		weapon_base:codwp_on_damage_dealt()
	end
end)

-- Tough: a short burst of speed whenever you (re)spawn.
Hooks:PostHook(PlayerManager, "spawned_player", "CODWP_SpawnedPlayer", function(self, id, unit)
	DelayedCalls:Add("CODWP_Tough", 1, function()
		local stats = CODWP.stats_of(CODWP.equipped_base())
		if stats and stats.cod_tough then
			CODWP.boost_speed(stats.cod_tough.speed, stats.cod_tough.duration)
		end
	end)
end)

PlayerManager.codwp_movement_speed_multiplier = PlayerManager.codwp_movement_speed_multiplier or PlayerManager.movement_speed_multiplier
function PlayerManager:movement_speed_multiplier(...)
	local multiplier = self:codwp_movement_speed_multiplier(...)

	if CODWP and CODWP.now() < CODWP.speed_until then
		multiplier = multiplier * CODWP.speed_mult
	end

	return multiplier
end
