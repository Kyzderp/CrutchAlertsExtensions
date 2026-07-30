local CAE = CrutchAlertsExtensions
local Crutch = CrutchAlerts


---------------------------------------------------------------------
local graveyard

local function RemoveGrave(graveKey)
    Draw.activeIcons[graveKey] = nil
    Draw.MaybeStopPolling()

    local realKey = tonumber(string.sub(graveKey, 6))
    graveyard:ReleaseObject(realKey)
end

-- returns key
local function CreateGrave(text)
    if (not graveyard) then
        graveyard = ZO_ControlPool:New("CrutchAlertsExtensionsGrave", CrutchAlertsSpace)
        graveyard:SetResetFunction(function(control)
            control:SetHidden(true)
        end)
    end

    local control, key = graveyard:AcquireObject()
    control:SetTransformNormalizedOriginPoint(0.5, 0.5)
    control:SetHidden(false)
    control:SetTransformScale(0.01)
    control:SetAnchor(CENTER, GuiRoot, CENTER)

    -- To not clash with normal keys when put in Draw.activeIcons together
    local graveKey = "Grave" .. key

    local _, x, y, z = GetUnitRawWorldPosition("player")
    text = text or "YOUR AD HERE"

    local label = control:GetNamedChild("Label")
    label:SetText(text)
    control:SetDimensions(2000, 2000)
    control:SetWidth(math.max(label:GetTextWidth() + 50, 300))
    local height = math.max(label:GetTextHeight() + 30, 60)
    control:SetHeight(height)

    local function UpdateFunc(icon)
        local _, x, y, z = GetUnitRawWorldPosition("player")
        icon:SetPosition(x, y, z)
    end

    Crutch.Drawing.CreateControlCommon(
        true, -- isSpace
        control,
        graveKey,
        "CrutchAlerts/assets/jetplane.dds", -- texture
        x, y, z,
        false, -- faceCamera
        pitch, yaw, roll,
        UpdateFunc,
        Crutch.Drawing.SetPosition,
        Crutch.Drawing.SetOrientation)

    return graveKey
end
CAE.CreateGrave = CreateGrave
-- /script CrutchAlertsExtensions.CreateGrave("asdf")

local function CreateRect(x, y, z, pitch, yaw, roll)
end

local function CalculateValues(x1, y1, z1, x2, y2, z2, x3, y3, z3)
    -- Midpoint
    local oX = (x1 + x2) / 2
    local oY = (y1 + y2) / 2
    local oZ = (z1 + z2) / 2

    local height = math.sqrt((x3 - x1)^2 + (y3 - y1)^2 + (z3 - z1)^2)
    local width = math.sqrt((x3 - x2)^2 + (y3 - y2)^2 + (z3 - z2)^2)
    local pitch = math.atan2(z3 - z1, y3 - y1)
    local yaw = math.atan2(z3 - z1, x3 - x1)
    local roll = math.atan2(x3 - x1, y3 - y1)

    return oX, oY, oZ, pitch, yaw, roll, width, height
end

local coords = {
    -- {-1, -3, 0, 1, 0, 0, -1, 0, 0},
    {-1, 0, -.5, 1, 0, .5, 1, 0, -.5},
    -- {-1, 0, -.5, 0, 1, .5, -1, 0, .5},
}
local function Test()
    local first
    for _, coord in ipairs(coords) do
        local function UpdateFunctionWrapper(icon)
            local _, x, y, z = GetUnitRawWorldPosition("player")
            icon:SetPosition(x, y, z)
        end

        local oX, oY, oZ, pitch, yaw, roll, width, height = CalculateValues(unpack(coord))
        d("---",
            "oX " .. oX,
            "oY " .. oY,
            "oZ " .. oZ,
            "pitch " .. pitch,
            "yaw " .. yaw,
            "roll " .. roll,
            "width " .. width,
            "height " .. height)

        -- TODO: don't use crutch, put under first
        local rect = Crutch.Drawing.CreateWorldTexture(
            "CrutchAlerts/assets/shape/diamond_orange_2.dds",
            oX, oY, oZ,
            width or 1,
            height,
            {1, 1, 1, 0.5},
            false, -- depth buffer
            false, -- face camera
            {pitch, yaw, roll},
            UpdateFunctionWrapper)

        if (not first) then
            first = rect
        end
    end
end
CAE.Test = Test -- /script CrutchAlertsExtensions.Test()
--[[
/script CrutchAlerts.Drawing.RemoveWorldTexture("2")
/script CrutchAlertsDrawingCrutchAlertsDrawingTexture1:Set3DRenderSpaceOrientation(0, 0, 0)


]]
