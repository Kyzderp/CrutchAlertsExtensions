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
}


---------------------------------------------------------------------
-- Zone change
---------------------------------------------------------------------
local function OnPlayerActivated()
end


---------------------------------------------------------------------
-- Initialize 
---------------------------------------------------------------------
local function Initialize()
    CAE.savedOptions = ZO_SavedVars:NewAccountWide("CrutchAlertsExtensionsSavedVariables", 1, "Options", defaultOptions)

    -- CAE.CreateSettingsMenu()

    EVENT_MANAGER:RegisterForEvent(CAE.name .. "Activated", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
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

