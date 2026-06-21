local CAE = CrutchAlertsExtensions
local Crutch = CrutchAlerts


---------------------------------------------------------------------
local function IsSlotted(id)
    -- If ww, check only ww and not regular bars
    if (IsPlayerInWerewolfForm()) then
        for i = 3, 8 do
            local abilityId = Crutch.GetSlotTrueBoundId(i, HOTBAR_CATEGORY_WEREWOLF)
            if (abilityId == id) then return true end
        end
        return false
    end

    local otherBar = (GetActiveHotbarCategory() == HOTBAR_CATEGORY_PRIMARY) and HOTBAR_CATEGORY_BACKUP or HOTBAR_CATEGORY_PRIMARY
    for i = 3, 8 do
        local abilityId = Crutch.GetSlotTrueBoundId(i, GetActiveHotbarCategory())
        if (abilityId == id) then return true end

        local otherBarAbilityId = Crutch.GetSlotTrueBoundId(i, otherBar)
        if (otherBarAbilityId == id) then return true end
    end
    return false
end
CAE.IsSlotted = IsSlotted

local function OnHotbarsUpdated()
    Crutch.dbgSpam("hotbars updated") -- TODO: needs debouncing?

    local profile = CAE.profiles[CAE.csvs.currentProfile]
    for id, circleData in pairs(profile.circles) do
        if (circleData.conditionalAbilityId) then
            if (IsSlotted(circleData.conditionalAbilityId)) then
                Crutch.dbgSpam(circleData.conditionalAbilityId .. " is slotted")
                CAE.ShowCircle(id)
            else
                Crutch.dbgSpam(circleData.conditionalAbilityId .. " is not slotted")
                CAE.HideCircle(id)
            end
        end
    end
end

function CAE.InitializeConditionalChecker()
    EVENT_MANAGER:RegisterForEvent(CAE.name .. "Conditional", EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED, OnHotbarsUpdated)
    EVENT_MANAGER:RegisterForEvent(CAE.name .. "ConditionalWW", EVENT_WEREWOLF_STATE_CHANGED, OnHotbarsUpdated)
    -- TODO: check sets
end
