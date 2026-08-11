local CAE = CrutchAlertsExtensions
local Crutch = CrutchAlerts
local Draw = Crutch.Drawing


---------------------------------------------------------------------
local SHADOW_IMAGE_NAMES = {
    ["Gloom Wraith"] = true,
    -- TODO: other languages
}

-- Whether it's the right morph
local function IsShadowImage()
    for skillLineIndex = 1, GetNumSkillLines(SKILL_TYPE_CLASS) do
        local skillLineId = GetSkillLineId(SKILL_TYPE_CLASS, skillLineIndex)
        local _, _, isActive = GetSkillLineDynamicInfo(SKILL_TYPE_CLASS, skillLineIndex)
        -- TODO: get the skill line and progression IDs
        if (isActive and skillLineId == 22 or skillLineId == 218 or skillLineId == 131) then
            for skillIndex = 1, GetNumSkillAbilities(SKILL_TYPE_CLASS, skillLineIndex) do
                local progressionId = GetProgressionSkillProgressionId(SKILL_TYPE_CLASS, skillLineIndex, skillIndex)

                -- Fatecarver
                if (progressionId == 535) then
                    local _, _, _, _, _, purchased = GetSkillAbilityInfo(SKILL_TYPE_CLASS, skillLineIndex, skillIndex)
                    if (purchased) then
                        local morph = GetProgressionSkillCurrentMorphSlot(progressionId)
                        return morph == MORPH_SLOT_MORPH_2
                    end
                end
            end
        end
    end
end


---------------------------------------------------------------------
---------------------------------------------------------------------
local createdKeys = {} -- {[unitTag] = {key, key}}

local function OnUnitDestroyed(_, unitTag)
    if (createdKeys[unitTag]) then
        for _, key in ipairs(createdKeys[unitTag]) do
            Draw.RemoveGroundCircle(key)
        end
        ZO_ClearTable(createdKeys[unitTag])
    end
end

local function DrawThinCircle(x, y, z, orientation)
    return Draw.CreateOrientedTexture("CrutchAlerts/assets/floor/thincircle.dds",
        x, y, z, 28, {0.8, 0, 1, 0.5}, orientation, nil, true))
end

local function OnUnitCreated(_, unitTag)
    OnUnitDestroyed(nil, unitTag)

    -- Crutch.dbgSpam(unitTag .. " - " .. tostring(GetUnitName(unitTag)))
    if (SHADOW_IMAGE_NAMES[GetUnitName(unitTag)] and IsShadowImage()) then
        local _, x, y, z = GetUnitRawWorldPosition(unitTag)
        local depthBuffer = true

        if (not createdKeys[unitTag]) then
            createdKeys[unitTag] = {}
        end

        table.insert(createdKeys[unitTag], DrawThinCircle(x, y, z, nil))
        table.insert(createdKeys[unitTag], DrawThinCircle(x, y, z, {0, 0, 0}))
        table.insert(createdKeys[unitTag], DrawThinCircle(x, y, z, {0, math.pi/2, 0}))
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
