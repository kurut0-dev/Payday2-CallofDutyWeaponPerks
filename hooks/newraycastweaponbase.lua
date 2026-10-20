CODWP = CODWP or {}

-- Player-wide timed speed buff (Tough, Speed Up Kill).
CODWP.speed_until = CODWP.speed_until or 0
CODWP.speed_mult = CODWP.speed_mult or 1

CODWP.ARMORED_PATTERNS = { "tank", "shield", "phalanx" }

function CODWP.now()
	return TimerManager:game():time()
end

function CODWP.stats_of(weapon_base)
	return weapon_base and weapon_base._codwp_stats
end

function CODWP.equipped_base()
	if not managers.player then
		return nil
	end

	local weapon_unit = managers.player:equipped_weapon_unit()
	return alive(weapon_unit) and weapon_unit:base() or nil
end

-- The weapon that dealt the damage if known, else whatever the player holds.
function CODWP.attack_weapon_base(attack_data)
	local weapon_unit = attack_data and attack_data.weapon_unit
	if alive(weapon_unit) and weapon_unit:base() and weapon_unit:base()._codwp_stats then
		return weapon_unit:base()
	end

	return CODWP.equipped_base()
end

function CODWP.boost_speed(speed, duration)
	CODWP.speed_until = CODWP.now() + duration
	CODWP.speed_mult = speed
end

Hooks:PostHook(NewRaycastWeaponBase, "_update_stats_values", "CODWP_UpdateStats", function(self, disallow_replenish)
	self._codwp_stats = {}
	self._codwp_state = {
		last_kill = 0,
		reload_until = 0
	}

	local custom_stats = managers.weapon_factory:get_custom_stats_from_weapon(self._factory_id, self._blueprint)
	for part_id, stats in pairs(custom_stats) do
		for key, value in pairs(stats) do
			if type(key) == "string" and string.begins(key, "cod_") then
				self._codwp_stats[key] = value
			end
		end
	end

	-- FMJ: full metal jacket rounds punch through enemy shields.
	if self._codwp_stats.cod_fmj then
		self._can_shoot_through_shield = true
	end
end)

-- Some versions read this through a method rather than the _can_shoot_through_shield field.
-- Only wrap it when it exists, so a missing original is never called.
if NewRaycastWeaponBase.can_shoot_through_shield and not NewRaycastWeaponBase.codwp_can_shoot_through_shield then
	NewRaycastWeaponBase.codwp_can_shoot_through_shield = NewRaycastWeaponBase.can_shoot_through_shield
	function NewRaycastWeaponBase:can_shoot_through_shield(...)
		if self._codwp_stats and self._codwp_stats.cod_fmj then
			return true
		end

		return self:codwp_can_shoot_through_shield(...)
	end
end

-- Sleight of Hand, Empty Reload and Fast Reload Kill all scale reload speed.
NewRaycastWeaponBase.codwp_reload_speed_multiplier = NewRaycastWeaponBase.codwp_reload_speed_multiplier or NewRaycastWeaponBase.reload_speed_multiplier
function NewRaycastWeaponBase:reload_speed_multiplier(...)
	local multiplier = self:codwp_reload_speed_multiplier(...)
	local stats = self._codwp_stats
	if not stats or not next(stats) then
		return multiplier
	end

	if stats.cod_sleight_of_hand then
		multiplier = multiplier * stats.cod_sleight_of_hand.reload
	end

	if stats.cod_empty_reload and self:get_ammo_remaining_in_clip() <= 0 then
		multiplier = multiplier * stats.cod_empty_reload.reload
	end

	if stats.cod_fast_reload_kill and CODWP.now() < self._codwp_state.reload_until then
		multiplier = multiplier * stats.cod_fast_reload_kill.reload
	end

	return multiplier
end

-- Puts bullets straight back into the magazine, capped at its size.
function NewRaycastWeaponBase:codwp_refill_clip(amount)
	local max_clip = self:get_ammo_max_per_clip()
	local new_amount = math.min(max_clip, self:get_ammo_remaining_in_clip() + (amount or max_clip))

	self:set_ammo_remaining_in_clip(new_amount)

	if managers.hud and self.selection_index and self.ammo_info then
		pcall(managers.hud.set_ammo_amount, managers.hud, self:selection_index(), self:ammo_info())
	end
end

function NewRaycastWeaponBase:codwp_on_damage_dealt()
	local stats = self._codwp_stats
	if not stats then
		return
	end

	if stats.cod_fast_reload_kill then
		self._codwp_state.reload_until = CODWP.now() + stats.cod_fast_reload_kill.duration
	end

	if stats.cod_speed_up_kill then
		CODWP.boost_speed(stats.cod_speed_up_kill.speed, stats.cod_speed_up_kill.duration)
	end
end

function NewRaycastWeaponBase:codwp_on_kill(killed_unit, variant)
	local stats = self._codwp_stats
	if not stats or not next(stats) then
		return
	end

	local t = CODWP.now()
	local state = self._codwp_state

	if stats.cod_melee_master then
		local player_unit = managers.player:player_unit()
		local close = variant == "melee"
		if not close and alive(killed_unit) and alive(player_unit) then
			close = mvector3.distance(player_unit:position(), killed_unit:position()) <= stats.cod_melee_master.range
		end

		if close then
			self:codwp_refill_clip(stats.cod_melee_master.bullets)
		end
	end

	if variant ~= "melee" and stats.cod_bullet_return and math.random() < stats.cod_bullet_return.chance then
		self:codwp_refill_clip()
	end

	if variant ~= "melee" and stats.cod_double_kill then
		if t - state.last_kill <= stats.cod_double_kill.window then
			state.last_kill = 0
			self:codwp_refill_clip()
		else
			state.last_kill = t
		end
	end
end
