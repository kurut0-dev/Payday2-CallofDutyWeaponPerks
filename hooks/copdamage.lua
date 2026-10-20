-- FMJ and Disable modify the hit before CopDamage resolves it (host side).
Hooks:PreHook(CopDamage, "damage_bullet", "CODWP_DamageBullet", function(self, attack_data)
	if not attack_data or not managers.player or attack_data.attacker_unit ~= managers.player:player_unit() then
		return
	end

	local stats = CODWP.stats_of(CODWP.attack_weapon_base(attack_data))
	if not stats then
		return
	end

	-- FMJ: a little extra damage against armored enemies (Bulldozers, Shields) to make up for their armor.
	if stats.cod_fmj and attack_data.damage then
		local tweak_table = self._unit:base() and self._unit:base()._tweak_table or ""

		for _, pattern in ipairs(CODWP.ARMORED_PATTERNS) do
			if string.find(tweak_table, pattern, 1, true) then
				attack_data.damage = attack_data.damage * (1 + stats.cod_fmj.armor_damage)
				break
			end
		end
	end

	-- Disable: leg shots stagger enemies, standing in for the movement slow.
	local disable = stats.cod_disable
	if disable and attack_data.damage_effect and self._HEALTH_INIT then
		local hit_pos = attack_data.col_ray and attack_data.col_ray.position
		if hit_pos and hit_pos.z - self._unit:position().z < disable.height then
			attack_data.damage_effect = math.max(attack_data.damage_effect * disable.multiplier, self._HEALTH_INIT * disable.minimum)
		end
	end
end)
