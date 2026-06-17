local CAE = CrutchAlertsExtensions
local Crutch = CrutchAlerts


---------------------------------------------------------------------
local KNOWN_PETS = { -- TODO: gender tags?
    ["Feral Guardian"] = "esoui/art/icons/ability_warden_018.dds",
    ["Eternal Guardian"] = "esoui/art/icons/ability_warden_018_b.dds",
    ["Wild Guardian"] = "esoui/art/icons/ability_warden_018_c.dds",
    ["Gloom Wraith"] = "esoui/art/icons/ability_nightblade_001_a.dds",
    -- TODO: other nb might be named the same
}

local KNOWN_TITLES = {
    ["Banker"] = "esoui/art/icons/servicemappins/servicepin_bank.dds",
    ["Merchant"] = "esoui/art/icons/servicemappins/servicepin_vendor.dds",
}

local function GetKnownTexture(unitTag)
    local knownTexture = KNOWN_PETS[GetUnitName(unitTag)]
    if (knownTexture) then return knownTexture end

    local title = GetUnitTitle(unitTag)
    if (title) then -- probably an assistant
        local knownTitleTexture = KNOWN_TITLES[title]
        if (knownTitleTexture) then return knownTitleTexture end
        return "esoui/art/icons/targetdummy_voriplasm_01.dds" -- TODO: ally or something icon
    end
end


---------------------------------------------------------------------
local function StartsWith(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
end

local function GetIconTexture(unitTag)
    if (unitTag == "companion") then
        return "esoui/art/mappins/activecompanion_pin.dds"
    end

    if (not StartsWith(unitTag, "playerpet")) then return nil end

    local knownTexture = GetKnownTexture(unitTag)
    local profile = CAE.profiles[CAE.csvs.currentProfile]

    if (knownTexture) then
        if (not profile.iconsForKnownPets) then return nil end
        return knownTexture
    end

    if (profile.iconsForPets) then
        return "CrutchAlerts/assets/poop.dds"
    end

    return nil
end


---------------------------------------------------------------------
---------------------------------------------------------------------
local UNIT_ICON_UNIQUE_NAME = "CrutchAlertsExtensionsUnitIcon"
local createdTags = {} -- Keep track of all possible in case of unregistering

local function OnUnitCreated(_, unitTag)
    local texture = GetIconTexture(unitTag)
    if (texture) then
        Crutch.SetAttachedIconForUnit(unitTag, UNIT_ICON_UNIQUE_NAME, 50, texture, nil, nil, true)
        createdTags[unitTag] = true
    end
end

local function OnUnitDestroyed(_, unitTag)
    Crutch.RemoveAttachedIconForUnit(unitTag, UNIT_ICON_UNIQUE_NAME)
end


---------------------------------------------------------------------
---------------------------------------------------------------------
local function InitializeUnitIcons()
    -- TODO: refresh all on player activation too
    local profile = CAE.profiles[CAE.csvs.currentProfile]

    if (profile.iconsForPets or profile.iconsForKnownPets) then
        EVENT_MANAGER:RegisterForEvent(CAE.name .. "UnitCreated", EVENT_UNIT_CREATED, OnUnitCreated)
        EVENT_MANAGER:RegisterForEvent(CAE.name .. "UnitDestroyed", EVENT_UNIT_DESTROYED, OnUnitDestroyed)
    end

    if (profile.iconsForCompanions) then
        EVENT_MANAGER:RegisterForEvent(CAE.name .. "CompanionActivated", EVENT_COMPANION_ACTIVATED, function() OnUnitCreated(nil, "companion") end)
        EVENT_MANAGER:RegisterForEvent(CAE.name .. "CompanionDeactivated", EVENT_COMPANION_DEACTIVATED, function() OnUnitDestroyed(nil, "companion") end)
    end
end
CAE.InitializeUnitIcons = InitializeUnitIcons

local function UnregisterUnitIcons()
    EVENT_MANAGER:UnregisterForEvent(CAE.name .. "UnitCreated", EVENT_UNIT_CREATED)
    EVENT_MANAGER:UnregisterForEvent(CAE.name .. "UnitDestroyed", EVENT_UNIT_DESTROYED)
    EVENT_MANAGER:UnregisterForEvent(CAE.name .. "CompanionActivated", EVENT_COMPANION_ACTIVATED)
    EVENT_MANAGER:UnregisterForEvent(CAE.name .. "CompanionDeactivated", EVENT_COMPANION_DEACTIVATED)

    for tag, _ in pairs(createdTags) do
        Crutch.RemoveAttachedIconForUnit(tag, UNIT_ICON_UNIQUE_NAME)
    end
end


---------------------------------------------------------------------
function CAE.GetUnitIconsSettings()
    return {
        {
            type = "description",
            title = "|c08BD1DWorld Drawing Tools|r",
            -- text = "",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Show icons on companions",
            tooltip = "Shows companion icons above your companions",
            default = false,
            getFunc = function() return CAE.profiles[CAE.csvs.currentProfile].iconsForCompanions end,
            setFunc = function(value)
                CAE.profiles[CAE.csvs.currentProfile].iconsForCompanions = value
                UnregisterUnitIcons()
                InitializeUnitIcons()
            end,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Show icons on specific known \"pets\"",
            tooltip = "Shows icons above your \"pets\" with specific names. Your assistants are considered playerpets, as well as permanent pets. This relies partially on text detection, so some client languages may not be supported, in which case they will be detected as other pets below",
            default = false,
            getFunc = function() return CAE.profiles[CAE.csvs.currentProfile].iconsForKnownPets end,
            setFunc = function(value)
                CAE.profiles[CAE.csvs.currentProfile].iconsForKnownPets = value
                UnregisterUnitIcons()
                InitializeUnitIcons()
            end,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Show icons on other \"pets\"",
            tooltip = "Shows generic poop icons above your other \"pets.\" This will put icons on any of your playerpets that are NOT from the list above, meaning temporary summons (including from game mechanics like IA verses) and anything that's generally... not worth putting an icon on",
            default = false,
            getFunc = function() return CAE.profiles[CAE.csvs.currentProfile].iconsForPets end,
            setFunc = function(value)
                CAE.profiles[CAE.csvs.currentProfile].iconsForPets = value
                UnregisterUnitIcons()
                InitializeUnitIcons()
            end,
            width = "full",
        },
    }
end
