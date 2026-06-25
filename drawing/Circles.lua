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
local function CleanCircles()
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

local function CreateCircleById(id)
    local profile = CAE.profiles[CAE.csvs.currentProfile]
    local circleData = profile.circles[id]
    CreateCircle(id, circleData.radius, circleData.rgb, circleData.color, circleData.yOffset, circleData.depthBuffers)
end

local function ShowCircle(id)
    if (currentKeys[id]) then return end -- already showing
    CreateCircleById(id)
end
CAE.ShowCircle = ShowCircle

local function HideCircle(id)
    if (not currentKeys[id]) then return end -- already hidden
    Crutch.Drawing.RemoveWorldTexture(currentKeys[id])
    currentKeys[id] = nil
end
CAE.HideCircle = HideCircle

local function UpdateCircles()
    local profile = CAE.profiles[CAE.csvs.currentProfile]
    for id, circleData in pairs(profile.circles) do
        if (CAE.ShouldCircleBeShown(circleData.conditionalAbilityId, circleData.conditionalSetId)) then
            Crutch.dbgSpam("attempting to show circle " .. id)
            ShowCircle(id)
        else
            Crutch.dbgSpam("attempting to hide circle " .. id)
            HideCircle(id)
        end
    end
end
CAE.UpdateCircles = UpdateCircles


---------------------------------------------------------------------
-- Init
---------------------------------------------------------------------
local function LoadCurrentProfile()
    CleanCircles()
    UpdateCircles()

    local profile = CAE.profiles[CAE.csvs.currentProfile]
    CAE.msg("Loaded profile " .. profile.profileName)
end
CAE.LoadCurrentProfile = LoadCurrentProfile

function CAE.InitializeCircles()
    LoadCurrentProfile()
end
