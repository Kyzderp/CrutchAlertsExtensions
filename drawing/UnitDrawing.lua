local CAE = CrutchAlertsExtensions
local Crutch = CrutchAlerts


---------------------------------------------------------------------
local KNOWN_PETS = {
    ["Gloom Wraith"] = "esoui/art/icons/ability_nightblade_001_a.dds",
}


---------------------------------------------------------------------
---------------------------------------------------------------------
-- TODO: clean this up
local createdTags = {} -- Keep track of all possible in case of unregistering
local createdTags2 = {} -- Keep track of all possible in case of unregistering
local createdTags3 = {} -- Keep track of all possible in case of unregistering

local function OnUnitCreated(_, unitTag)
    if (createdTags[unitTag]) then
        Crutch.Drawing.RemoveGroundCircle(createdTags[unitTag])
        Crutch.Drawing.RemoveGroundCircle(createdTags2[unitTag])
        Crutch.Drawing.RemoveGroundCircle(createdTags3[unitTag])
    end
    -- Crutch.dbgSpam(unitTag .. " - " .. tostring(GetUnitName(unitTag)))
    if (KNOWN_PETS[GetUnitName(unitTag)]) then
        local _, x, y, z = GetUnitRawWorldPosition(unitTag)
        local depthBuffer = true
        createdTags[unitTag] = Crutch.Drawing.CreateGroundCircle(x, y, z, 28, {0.8, 0, 1, 0.5}, nil, nil, depthBuffer)
        createdTags2[unitTag] = Crutch.Drawing.CreateGroundCircle(x, y, z, 28, {0.8, 0, 1, 0.5}, {0, 0, 0}, nil, depthBuffer)
        createdTags3[unitTag] = Crutch.Drawing.CreateGroundCircle(x, y, z, 28, {0.8, 0, 1, 0.5}, {0, math.pi/2, 0}, nil, depthBuffer)
    end
end

local function OnUnitDestroyed(_, unitTag)
    if (createdTags[unitTag]) then
        Crutch.Drawing.RemoveGroundCircle(createdTags[unitTag])
        Crutch.Drawing.RemoveGroundCircle(createdTags2[unitTag])
        Crutch.Drawing.RemoveGroundCircle(createdTags3[unitTag])
        createdTags[unitTag] = nil
        createdTags2[unitTag] = nil
        createdTags3[unitTag] = nil
    end
end

-- Units can change when going into another zone, e.g. with a banker
-- summoned as playerpet1, we don't get unit destroyed event after
-- rezoning. So clean up all the pets and redo them.
local function OnPlayerActivated()
    local profile = CAE.profiles[CAE.csvs.currentProfile]
    for i = 1, MAX_PET_UNIT_TAGS do
        local tag = "playerpet" .. i
        OnUnitDestroyed(nil, tag)
        if (DoesUnitExist(tag)) then
            OnUnitCreated(nil, tag)
        end
    end
end


---------------------------------------------------------------------
---------------------------------------------------------------------
local function InitializeUnitDrawing()
    local profile = CAE.profiles[CAE.csvs.currentProfile]

    -- if (profile.iconsForPets or profile.iconsForKnownPets) then
        EVENT_MANAGER:RegisterForEvent(CAE.name .. "UDUnitCreated", EVENT_UNIT_CREATED, OnUnitCreated)
        EVENT_MANAGER:RegisterForEvent(CAE.name .. "UDUnitDestroyed", EVENT_UNIT_DESTROYED, OnUnitDestroyed)
    -- end


    EVENT_MANAGER:RegisterForEvent(CAE.name .. "UDPlayerActivated", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end
CAE.InitializeUnitDrawing = InitializeUnitDrawing

local function UnregisterUnitDrawing()
    EVENT_MANAGER:UnregisterForEvent(CAE.name .. "UDUnitCreated", EVENT_UNIT_CREATED)
    EVENT_MANAGER:UnregisterForEvent(CAE.name .. "UDUnitDestroyed", EVENT_UNIT_DESTROYED)
end


---------------------------------------------------------------------
function CAE.GetUnitDrawingSettings()
    return {
    }
end
