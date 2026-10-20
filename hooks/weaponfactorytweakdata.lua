local perk_template = {
	custom = true,
	exclude_from_challenge = true,
	texture_bundle_folder = "codperks",
	global_value = "codperks",
	third_unit = "units/payday2/weapons/wpn_upg_dummy/wpn_upg_dummy",
	a_obj = "a_body",
	type = "perk",
	internal_part = true,
	unit = "units/payday2/weapons/wpn_upg_dummy/wpn_upg_dummy",
	pcs = {
		10,
		20,
		30,
		40
	},
	stats = {
		value = 10
	},
	drop = false
}

local function setup_perk(id, data)
	local output = deep_clone(perk_template)
	output.name_id = "bm_menu_perk_cod_" .. id
	output.desc_id = "bm_menu_perk_cod_" .. id .. "_desc"
	output.has_description = true
	output.custom_stats = data.custom_stats

	-- Extra weapon stats (accuracy, total ammo...) sit next to the template's value stat.
	for key, value in pairs(data.stats or {}) do
		output.stats[key] = value
	end

	return output
end

-- Ported from the weapon perks of CoD: Modern Warfare (2019) and CoD: Mobile. Akimbo is left out on purpose:
-- PAYDAY 2 has its own akimbo weapons.
-- Perks present in both games use the MW2019 icon, the rest use their CoD: Mobile icon.
-- "categories" follows the weapon classes CoD: Mobile offers each perk on (AR = assault_rifle, SMG = smg,
-- sniper = snp, LMG = lmg, shotgun = shotgun). Pistols count as SMGs and revolvers as snipers.
-- Perks without "categories" (Sleight of Hand, FMJ, Full Ammo) are offered on every weapon.
local perks = {
	-- In both games
	sleight_of_hand = {
		custom_stats = { cod_sleight_of_hand = { reload = 1.25 } }
	},
	fmj = {
		-- The can_shoot_through_shield flag is the one the game and weapon preview mods look for on a part.
		custom_stats = { cod_fmj = { armor_damage = 0.1 }, can_shoot_through_shield = true }
	},
	full_ammo = {
		stats = { total_ammo_mod = 8 }
	},
	disable = {
		categories = { "assault_rifle" },
		custom_stats = { cod_disable = { height = 70, multiplier = 2, minimum = 0.15 } }
	},

	-- CoD: Mobile only
	tough = {
		categories = { "assault_rifle" },
		custom_stats = { cod_tough = { speed = 1.15, duration = 10 } }
	},
	long_shot = {
		categories = { "assault_rifle" },
		stats = { spread = 3 }
	},
	melee_master = {
		categories = { "assault_rifle" },
		custom_stats = { cod_melee_master = { bullets = 3, range = 300 } }
	},
	bullet_return = {
		categories = { "snp", "revolver" },
		custom_stats = { cod_bullet_return = { chance = 0.15 } }
	},
	fast_switch = {
		categories = { "snp", "revolver" },
		custom_stats = { cod_fast_switch = { speed = 1.4 } }
	},
	empty_reload = {
		categories = { "lmg" },
		custom_stats = { cod_empty_reload = { reload = 1.3 } }
	},
	wild_hip_fire = {
		categories = { "smg", "pistol" },
		stats = { spread_moving = 6 }
	},
	double_kill = {
		categories = { "smg", "pistol" },
		custom_stats = { cod_double_kill = { window = 2 } }
	},
	fast_reload_kill = {
		categories = { "smg", "pistol" },
		custom_stats = { cod_fast_reload_kill = { reload = 1.3, duration = 3 } }
	},
	speed_up_kill = {
		categories = { "shotgun" },
		custom_stats = { cod_speed_up_kill = { speed = 1.15, duration = 2 } }
	},
	slide_flak_jacket = {
		categories = { "shotgun" },
		custom_stats = { cod_slide_flak_jacket = { taken = 0.85 } }
	}
}

local function add_part(factory, part_id)
	if factory and factory.uses_parts and not table.contains(factory.uses_parts, part_id) then
		table.insert(factory.uses_parts, part_id)
	end
end

-- Safe to run repeatedly: parts are only created once and never added to a weapon twice.
-- Addon weapons that register after create_bonuses are picked up by the later passes.
local function apply_perks(factory_data, tweak_data)
	for id, perk in pairs(perks) do
		local part_id = "wpn_fps_upg_perk_cod_" .. id
		if not factory_data.parts[part_id] then
			factory_data.parts[part_id] = setup_perk(id, perk)
		end
	end

	for _, data in pairs(tweak_data.upgrades.definitions) do
		if data.weapon_id and data.factory_id and factory_data[data.factory_id] then
			local weapon_tweak = tweak_data.weapon[data.weapon_id]
			local categories = weapon_tweak and weapon_tweak.categories or {}

			for id, perk in pairs(perks) do
				if not perk.categories or table.contains_any(perk.categories, categories) then
					local part_id = "wpn_fps_upg_perk_cod_" .. id
					add_part(factory_data[data.factory_id], part_id)
					add_part(factory_data[data.factory_id .. "_npc"], part_id)
				end
			end
		end
	end
end

CODWP_ApplyPerks = function()
	if tweak_data and tweak_data.weapon_factory then
		apply_perks(tweak_data.weapon_factory, tweak_data)
	end
end

Hooks:PostHook(WeaponFactoryTweakData, "create_bonuses", "CODWP_CreateBonuses", function(self, tweak_data, weapon_skins)
	apply_perks(self, tweak_data)
end)
