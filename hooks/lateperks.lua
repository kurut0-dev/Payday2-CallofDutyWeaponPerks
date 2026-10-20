-- Second pass for addon weapons that register their upgrade definitions after
-- WeaponFactoryTweakData:create_bonuses has already run.
Hooks:PostHook(TweakData, "init", "CODWP_TweakDataInit", function()
	if CODWP_ApplyPerks then
		CODWP_ApplyPerks()
	end
end)
