local CAE = CrutchAlertsExtensions
local Crutch = CrutchAlerts
---------------------------------------------------------------------
local currentKeys = {}
local function CleanCircles()
    for _, key in ipairs(currentKeys) do
        Crutch.Drawing.RemoveWorldTexture(key)
    end
    ZO_ClearTable(currentKeys)
end

-- yOffset default 5
local function CreateCircle(radius, rgb, color, yOffset)
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

    table.insert(currentKeys, Crutch.Drawing.CreateGroundCircle(x, y + yOffset, z, radius, color, nil, CircleFunc))
end

local function LoadCurrentProfile()
    CleanCircles()

    local profile = CAE.svs.profiles[CAE.svs.currentProfile]

    for _, circleData in ipairs(profile.circles) do
        CreateCircle(circleData.radius, circleData.rgb, circleData.color, circleData.yOffset)
    end
end


function CAE.InitializeCircles()
    LoadCurrentProfile()
end
