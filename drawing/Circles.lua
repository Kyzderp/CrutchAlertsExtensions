local CAE = CrutchAlertsExtensions
local Crutch = CrutchAlerts


---------------------------------------------------------------------
-- Profile data
---------------------------------------------------------------------
function CAE.AddCircleToProfile(rgb, color, radius, yOffset, conditionalAbilityId, conditionalSetId, depthBuffers)
    local profile = CAE.profiles[CAE.csvs.currentProfile]

    local index = CAE.FindFreeId(profile.circles)
    profile.circles[index] = {
        rgb = rgb,
        color = color,
        radius = radius,
        yOffset = yOffset,
        conditionalAbilityId = conditionalAbilityId,
        conditionalSetId = conditionalSetId,
        depthBuffers = depthBuffers,
    }

    CAE.msg(zo_strformat("Added circle of radius <<1>> to profile <<2>>", radius, profile.profileName))

    return index
end

function CAE.RemoveCircleFromProfile(index)
    local profile = CAE.profiles[CAE.csvs.currentProfile]
    CAE.msg(zo_strformat("Removing circle of radius <<1>> from profile <<2>>", profile.circles[index].radius, profile.profileName))
    profile.circles[index] = nil
end


---------------------------------------------------------------------
-- Loading / Drawing
---------------------------------------------------------------------
local currentKeys = {}
local function CleanShapes()
    for _, key in pairs(currentKeys) do
        Crutch.Drawing.RemoveWorldTexture(key)
    end
    ZO_ClearTable(currentKeys)
end

-- yOffset default 5
local function CreateCircle(id, radius, rgb, color, yOffset, depthBuffers)
    local _, x, y, z = GetUnitRawWorldPosition("player")

    -- Places circle at player's feet
    local function CircleFunc(icon)
        -- Make circle follow the player
        local _, x, y, z = GetUnitRawWorldPosition("player")
        icon:SetPosition(x, y + yOffset, z)

        -- Make color change every update
        if (rgb) then
            local time = GetGameTimeMilliseconds() % 2000 / 2000
            icon:SetColor(Crutch.ConvertHSLToRGB(time, 1, 0.5))
        end
    end

    currentKeys[id] = Crutch.Drawing.CreateWorldTexture(
        "CrutchAlerts/assets/floor/circle.dds",
        x,
        y + yOffset,
        z,
        radius * 2,
        radius * 2,
        color,
        depthBuffers,
        false,
        {math.pi/2, 0, 0},
        CircleFunc)
end

local function CreateShapeById(id)
    local profile = CAE.profiles[CAE.csvs.currentProfile]
    local shapeData = profile.circles[id]
    if (shapeData.type == CAE.CIRCLE) then
        CreateCircle(id, shapeData.radius, shapeData.rgb, shapeData.color, shapeData.yOffset, shapeData.depthBuffers)
    end
end

local function ShowShape(id)
    if (currentKeys[id]) then return end -- already showing
    CreateShapeById(id)
end

local function HideShape(id)
    if (not currentKeys[id]) then return end -- already hidden
    Crutch.Drawing.RemoveWorldTexture(currentKeys[id])
    currentKeys[id] = nil
end

local function UpdateShapes()
    local profile = CAE.profiles[CAE.csvs.currentProfile]
    for id, shapeData in pairs(profile.circles) do
        if (CAE.ShouldShapeBeShown(shapeData.conditionalAbilityId, shapeData.conditionalSetId)) then
            Crutch.dbgSpam("attempting to show shape " .. id)
            ShowShape(id)
        else
            Crutch.dbgSpam("attempting to hide shape " .. id)
            HideShape(id)
        end
    end
end
CAE.UpdateShapes = UpdateShapes


---------------------------------------------------------------------
-- Init
---------------------------------------------------------------------
local function LoadCurrentProfile()
    CleanShapes()
    UpdateShapes()

    local profile = CAE.profiles[CAE.csvs.currentProfile]
    CAE.msg("Loaded profile " .. profile.profileName)
end
CAE.LoadCurrentProfile = LoadCurrentProfile

function CAE.InitializeShapes()
    LoadCurrentProfile()
end
