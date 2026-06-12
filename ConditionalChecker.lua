local CAE = CrutchAlertsExtensions
local Crutch = CrutchAlerts


---------------------------------------------------------------------
local function IsSlotted(id)
    for i = 3, 8 do
        local abilityId = Crutch.GetSlotTrueBoundId(i, GetActiveHotbarCategory())
        if (abilityId == id) then return true end
    end

    -- FAB: Check the inactive bar too
    if (FancyActionBar) then
        local otherBar = (GetActiveHotbarCategory() == HOTBAR_CATEGORY_PRIMARY) and HOTBAR_CATEGORY_BACKUP or HOTBAR_CATEGORY_PRIMARY
        for i = 3, 8 do
            local otherBarAbilityId = Crutch.GetSlotTrueBoundId(i, otherBar)
            -- 20 offset gets the inactive bar's slot
            if (otherBarAbilityId == id) then return true end
        end
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
                CAE.ShowCircle(id)
            else
                CAE.HideCircle(id)
            end
        end
    end
end

function CAE.InitializeConditionalChecker()
    EVENT_MANAGER:RegisterForEvent(CAE.name .. "Conditional", EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED, OnHotbarsUpdated)
    -- TODO: check sets
end
