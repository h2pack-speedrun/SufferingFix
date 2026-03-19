local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods['SGG_Modding-ModUtil']
chalk = mods['SGG_Modding-Chalk']
reload = mods['SGG_Modding-ReLoad']
local lib = mods['adamant-Modpack_Lib']

config = chalk.auto('config.lua')
public.config = config

local backup, restore = lib.createBackupSystem()

-- =============================================================================
-- MODULE DEFINITION
-- =============================================================================

public.definition = {
    id       = "SufferingFix",
    name     = "Suffering Fix",
    category = "BugFixes",
    group    = "NPC & Encounters",
    tooltip  = "Fixes Suffering on Sight not bypassing Wards vow when dealing damage.",
    default  = true,
    dataMutation = false,
}

-- =============================================================================
-- MODULE LOGIC
-- =============================================================================

local function apply()
end

local function registerHooks()
    modutil.mod.Path.Wrap("CheckSpawnCurseDamage", function(baseFunc, enemy, traitArgs)
        if not lib.isEnabled(config) then return baseFunc(enemy, traitArgs) end

        if enemy.IsBoss or enemy.UseBossHealthBar or enemy.IgnoreCurseDamage or enemy.AlwaysTraitor then
            return
        end
        local damageAmount = 0
        for _, data in ipairs(traitArgs.DamageArgs) do
            if not data.Chance or RandomChance(data.Chance * GetTotalHeroTraitValue("LuckMultiplier", { IsMultiplier = true })) then
                damageAmount = RandomInt(data.MinDamage, data.MaxDamage)
                break
            end
        end
        thread(DoCurseDamage, enemy, traitArgs, damageAmount, true)
    end)
end

-- =============================================================================
-- Wiring
-- =============================================================================

public.definition.enable = apply
public.definition.disable = restore

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(function()
        import_as_fallback(rom.game)
        registerHooks()
        if lib.isEnabled(config) then apply() end
        if public.definition.dataMutation and not mods['adamant-Modpack_Core'] then
            SetupRunData()
        end
    end)
end)

local uiCallback = lib.standaloneUI(public.definition, config, apply, restore)
rom.gui.add_to_menu_bar(uiCallback)
