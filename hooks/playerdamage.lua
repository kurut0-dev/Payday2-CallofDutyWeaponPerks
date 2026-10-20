local damage_functions = { "damage_bullet", "damage_melee", "damage_explosion", "damage_fire" }

-- PAYDAY 2 has no slide, so Slide Flak Jacket applies while crouched.
local function scale_incoming_damage(self, attack_data)
	if not attack_data or not attack_data.damage then
		return
	end

	local stats = CODWP.stats_of(CODWP.equipped_base())
	local flak = stats and stats.cod_slide_flak_jacket
	if not flak then
		return
	end

	local movement = self._unit:movement()
	local state = movement and movement:current_state()
	if state and state._state_data and state._state_data.ducking then
		attack_data.damage = attack_data.damage * flak.taken
	end
end

for _, name in ipairs(damage_functions) do
	if PlayerDamage[name] then
		Hooks:PreHook(PlayerDamage, name, "CODWP_Pre_" .. name, scale_incoming_damage)
	end
end
