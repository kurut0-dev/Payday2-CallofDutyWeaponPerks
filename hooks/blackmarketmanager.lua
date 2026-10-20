-- Final pass once every mod has had the chance to register its weapons.
Hooks:PostHook(BlackMarketManager, "init", "CODWP_BlackMarketInit", function()
	if CODWP_ApplyPerks then
		CODWP_ApplyPerks()
	end
end)
