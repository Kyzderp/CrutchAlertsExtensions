local CAE = CrutchAlertsExtensions
local Crutch = CrutchAlerts


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
        Crutch.InfoPanel.SetLine(PANEL_HIT_BOSS_INDEX, "")
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
function CAE.InitializeDamagedEnemies()
    -- TODO: need pet for cro or something?
    -- TODO: ACTION_RESULT_DAMAGE_SHIELDED, ACTION_RESULT_BLOCKED_DAMAGE ?
    Crutch.RegisterForCombatEvent("DamagedEnemiesDamage", OnDamaged, ACTION_RESULT_DAMAGE, nil, COMBAT_UNIT_TYPE_PLAYER)
    Crutch.RegisterForCombatEvent("DamagedEnemiesCritDamage", OnDamaged, ACTION_RESULT_CRITICAL_DAMAGE, nil, COMBAT_UNIT_TYPE_PLAYER)

    Crutch.RegisterForEffectChanged("CrutchAlertsExtensionsDamagedEnemiesEffect", OnEffect, nil, "boss")
    Crutch.RegisterUpdateListener("CrutchAlertsExtensionsDamagedEnemies", OnUpdate)

    Crutch.RegisterExitedGroupCombatListener("CrutchAlertsExtensionsDamagedEnemies", CleanUp)
end
