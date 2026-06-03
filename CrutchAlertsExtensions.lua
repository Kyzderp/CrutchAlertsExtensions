-----------------------------------------------------------
-- CrutchAlerts Extensions
-- @author Kyzeragon
-----------------------------------------------------------
CrutchAlertsExtensions = {
    name = "CrutchAlerts Extensions",
    version = "0.0.0",
}
local CAE = CrutchAlertsExtensions

-- Defaults
local defaultOptions = {
    --[[
    {
        [profileId] = {
            profileName = "Default",
            circles = {}, -- {[1] = {rgb = false, color = {1, 1, 1}, radius = 5, yOffset = 0}}
        },
    }
    ]]
    profiles = {
        [1] = {
            profileName = "Default",
            circles = {}
        },
    },
    currentProfile = 1,
}


---------------------------------------------------------------------
-- Zone change
---------------------------------------------------------------------
local function OnPlayerActivatedFirstTime()
    EVENT_MANAGER:UnregisterForEvent(CAE.name .. "ActivatedFirstTime", EVENT_PLAYER_ACTIVATED)

    CAE.InitializeCircles()
end


---------------------------------------------------------------------
-- Initialize 
---------------------------------------------------------------------
local function Initialize()
    CAE.svs = ZO_SavedVars:NewAccountWide("CrutchAlertsExtensionsSavedVariables", 1, "Options", defaultOptions)

    -- CAE.CreateSettingsMenu()

    EVENT_MANAGER:RegisterForEvent(CAE.name .. "ActivatedFirstTime", EVENT_PLAYER_ACTIVATED, OnPlayerActivatedFirstTime)
end


---------------------------------------------------------------------
-- On load
local function OnAddOnLoaded(_, addonName)
    if (addonName == CAE.name) then
        EVENT_MANAGER:UnregisterForEvent(CAE.name, EVENT_ADD_ON_LOADED)
        Initialize()
    end
end
 
EVENT_MANAGER:RegisterForEvent(CAE.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

