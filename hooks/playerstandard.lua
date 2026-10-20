-- Fast Switch: faster weapon swaps.
if PlayerStandard._get_swap_speed_multiplier then
	PlayerStandard.codwp_get_swap_speed_multiplier = PlayerStandard.codwp_get_swap_speed_multiplier or PlayerStandard._get_swap_speed_multiplier
	function PlayerStandard:_get_swap_speed_multiplier(...)
		local multiplier = self:codwp_get_swap_speed_multiplier(...)

		local stats = CODWP.stats_of(self._equipped_unit and self._equipped_unit:base())
		if stats and stats.cod_fast_switch then
			multiplier = multiplier * stats.cod_fast_switch.speed
		end

		return multiplier
	end
end
