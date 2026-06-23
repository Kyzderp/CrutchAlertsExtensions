-----------------------------------------------------------
-- CrutchAlerts Extensions
-- @author Kyzeragon
-----------------------------------------------------------
CrutchAlertsExtensions = {
    name = "CrutchAlertsExtensions",
    version = "0.1.0",
}
local CAE = CrutchAlertsExtensions

-- Defaults
local defaultGlobalOptions = {
    --[[
    {
        [profileId] = {
            profileName = "Default",
            circles = {}, -- {[1] = {rgb = false, color = {1, 1, 1}, radius = 5, yOffset = 0}}
        },
    }
    ]]
    profiles = {
        [-1] = {
            profileName = "<Empty>",
            circles = {},
            hungerRequireModifier = false,
            lowerHunger = false,
            higherFrenzyAndAtro = false,
            iconsForKnownPets = false, -- hardcoded ones
            iconsForPets = false, -- fallback poop
            iconsForCompanions = false,
        },
    },
}

local defaultCharOptions = {
    currentProfile = -1,
}


---------------------------------------------------------------------
function CAE.msg(msg)
    if (not msg) then return end
    msg = "|c3bdb5e[CAE]|caaaaaa " .. tostring(msg)
    if (CHAT_ROUTER) then
        CHAT_ROUTER:AddSystemMessage(msg)
    end
end


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
local function FillAllDefaults(tab, defaults)
    for k, v in pairs(defaults) do
        if (tab[k] == nil) then
            if (type(v) == "table") then
                tab[k] = ZO_DeepTableCopy(v)
            else
                tab[k] = v
            end
        end
    end
end

local function Initialize()
    CrutchAlertsExtensionsSavedProfiles = CrutchAlertsExtensionsSavedProfiles or {}
    FillAllDefaults(CrutchAlertsExtensionsSavedProfiles, defaultGlobalOptions)
    CAE.profiles = CrutchAlertsExtensionsSavedProfiles.profiles

    CAE.csvs = ZO_SavedVars:NewCharacterIdSettings("CrutchAlertsExtensionsSavedVariables", 1, nil, defaultCharOptions)

    CAE.CreateSettingsMenu()
    CAE.CreateUtilsSettingsMenu()
    CAE.InitializeConditionalChecker()
    CAE.InitializeSynergy()
    CAE.InitializeUnitIcons()

    EVENT_MANAGER:RegisterForEvent(CAE.name .. "ActivatedFirstTime", EVENT_PLAYER_ACTIVATED, OnPlayerActivatedFirstTime)

    ZO_CreateStringId("SI_BINDING_NAME_CAE_SYNERGY_MODIFIER", "Werewolf Synergy Modifier")
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

