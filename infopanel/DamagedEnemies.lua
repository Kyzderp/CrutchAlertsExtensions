local CAE = CrutchAlertsExtensions
local Crutch = CrutchAlerts


---------------------------------------------------------------------
-- Data
---------------------------------------------------------------------
local ABILITY_BLACKLIST = {
    [148800] = true, -- Sundered
    [17902] = true, -- Poisoned Weapon
    [17895] = true, -- Fiery Weapon
}
CAE.ABILITY_BLACKLIST = ABILITY_BLACKLIST -- /script CrutchAlertsExtensions.ABILITY_BLACKLIST[12345] = true

local RESULTS = {
    [ACTION_RESULT_DAMAGE] = "DAMAGE",
    [ACTION_RESULT_CRITICAL_DAMAGE] = "CRITICAL_DAMAGE",
    [ACTION_RESULT_DAMAGE_SHIELDED] = "|cFF0000DAMAGE_SHIELDED|r",
    [ACTION_RESULT_BLOCKED_DAMAGE] = "|cFF0000BLOCKED_DAMAGE|r",
}


---------------------------------------------------------------------
-- Display
---------------------------------------------------------------------
local BOSS_COLOR = "DD0000"
local OTHER_COLOR = "22CCFF"
local CUSTOM_COLORS = {
    ["Enraged Fragment"] = "ff6600",
}

local function GetColor(name, isBoss)
    local color = CUSTOM_COLORS[name]
    if (not color) then
        color = isBoss and BOSS_COLOR or OTHER_COLOR
    end
    return color
end


---------------------------------------------------------------------
-- UI
---------------------------------------------------------------------
local PANEL_HIT_BOSS_INDEX = 100
local PANEL_HIT_OTHER_INDEX = 110

local ALLOWED_TIME = 2000
local LINE_SCALE = 0.7

--[[
{
    [targetUnitId] = {
        targetName = "asdf",
        bossNum = 2,
        events = {
            [abilityId] = timestamp,
        },
    }
}
]]
local recentDamage = {}

local activeLines = {} -- {[index] = true}
local function OnUpdate()
    -- Clear current. TODO: maybe only hide if needed?
    for index, _ in pairs(activeLines) do
        Crutch.InfoPanel.RemoveLine(index)
        activeLines[index] = nil
    end

    local currTime = GetGameTimeMilliseconds()
    local numActiveLines = 0
    local otherOffset = 1
    -- TODO: does it need to be sorted?
    for targetUnitId, targetData in pairs(recentDamage) do
        local iconSuffix = ""

        -- Collect entries or clear any that are too old
        for abilityId, timestamp in pairs(targetData.events) do
            if (currTime - timestamp > ALLOWED_TIME) then
                targetData[abilityId] = nil -- just remove
            else
                iconSuffix = string.format("%s |t100%%:100%%:%s|t", iconSuffix, GetAbilityIcon(abilityId))
            end
        end

        if (iconSuffix ~= "") then
            local customColor = GetColor(targetData.targetName, targetData.bossNum)
            local lineText = zo_strformat("|c<<1>><<2>><<3>>|r", customColor, targetData.targetName, iconSuffix)

            local index
            if (targetData.bossNum) then
                index = PANEL_HIT_BOSS_INDEX + targetData.bossNum
            else
                index = PANEL_HIT_OTHER_INDEX + otherOffset
                otherOffset = otherOffset + 1
            end
            Crutch.InfoPanel.SetLine(index, lineText, LINE_SCALE)
            activeLines[index] = true
            numActiveLines = numActiveLines + 1
        end
    end

    if (numActiveLines > 0) then
        Crutch.InfoPanel.SetLine(PANEL_HIT_BOSS_INDEX, "|cCCCCCCRecent enemies hit:|r", 0.5)
    else
        Crutch.InfoPanel.RemoveLine(PANEL_HIT_BOSS_INDEX)
    end
end


---------------------------------------------------------------------
-- Events
---------------------------------------------------------------------
-- Just to cache boss unit IDs
local bossIds = {}
local function OnEffect(_, _, _, _, unitTag, _, _, _, _, _, _, _, _, _, unitId)
    bossIds[unitId] = tonumber(string.sub(unitId, 5))
end

local function OnDamaged(_, result, _, _, _, _, _, _, targetName, _, hitValue, _, _, _, _, targetUnitId, abilityId)
    if (ABILITY_BLACKLIST[abilityId]) then return end

    Crutch.dbgSpam(string.format("[%s] %s (%d) -> %s (%d) for %d", RESULTS[result], GetAbilityName(abilityId), abilityId, targetName, targetUnitId, hitValue))

    if (not recentDamage[targetUnitId]) then
        recentDamage[targetUnitId] = {
            targetName = zo_strformat("<<1>>", targetName),
            bossNum = bossIds[targetUnitId],
            events = {},
        }
    end

    recentDamage[targetUnitId].events[abilityId] = GetGameTimeMilliseconds()

    OnUpdate()
end

local function CleanUp()
    ZO_ClearTable(bossIds)
    ZO_ClearTable(recentDamage)
    OnUpdate()
end


---------------------------------------------------------------------
-- Init
---------------------------------------------------------------------
local function InitializeDamagedEnemies()
    -- TODO: need pet for cro or something?
    Crutch.RegisterForCombatEvent("CAEDamagedEnemiesDamage", OnDamaged, ACTION_RESULT_DAMAGE, nil, COMBAT_UNIT_TYPE_PLAYER)
    Crutch.RegisterForCombatEvent("CAEDamagedEnemiesCritDamage", OnDamaged, ACTION_RESULT_CRITICAL_DAMAGE, nil, COMBAT_UNIT_TYPE_PLAYER)
    Crutch.RegisterForCombatEvent("CAEDamagedEnemiesShielded", OnDamaged, ACTION_RESULT_DAMAGE_SHIELDED, nil, COMBAT_UNIT_TYPE_PLAYER) -- TODO: ?
    Crutch.RegisterForCombatEvent("CAEDamagedEnemiesBlocked", OnDamaged, ACTION_RESULT_BLOCKED_DAMAGE, nil, COMBAT_UNIT_TYPE_PLAYER) -- TODO: ?
    Crutch.RegisterForEffectChanged("CAEDamagedEnemiesEffect", OnEffect, nil, "boss")

    Crutch.RegisterUpdateListener("CrutchAlertsExtensionsDamagedEnemies", OnUpdate)

    Crutch.RegisterExitedGroupCombatListener("CrutchAlertsExtensionsDamagedEnemies", CleanUp)
end
CAE.InitializeDamagedEnemies = InitializeDamagedEnemies

local function UnregisterDamagedEnemies()
    Crutch.UnregisterForCombatEvent("CAEDamagedEnemiesDamage")
    Crutch.UnregisterForCombatEvent("CAEDamagedEnemiesCritDamage")
    Crutch.UnregisterForCombatEvent("CAEDamagedEnemiesShielded")
    Crutch.UnregisterForCombatEvent("CAEDamagedEnemiesBlocked")
    Crutch.UnregisterForEffectChanged("CAEDamagedEnemiesEffect")

    Crutch.UnregisterUpdateListener("CrutchAlertsExtensionsDamagedEnemies")

    Crutch.UnregisterExitedGroupCombatListener("CrutchAlertsExtensionsDamagedEnemies")
end


---------------------------------------------------------------------
function CAE.GetDamagedEnemiesSettings()
    return {
        {
            type = "description",
            title = "|c08BD1DDamaged Enemies|r",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Show recently damaged enemies",
            tooltip = "Uses the Crutch info panel to show enemies you have damaged with direct damage abilities in the last 2 seconds and what you damaged them with",
            default = false,
            getFunc = function() return CAE.profiles[CAE.csvs.currentProfile].damagedEnemies end,
            setFunc = function(value)
                CAE.profiles[CAE.csvs.currentProfile].damagedEnemies = value
                UnregisterDamagedEnemies()
                InitializeDamagedEnemies()
            end,
            width = "full",
        },
    }
end
