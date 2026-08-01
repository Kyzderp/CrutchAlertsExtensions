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


---------------------------------------------------------------------
-- generic?
---------------------------------------------------------------------
local genericPool
local first
-- /script control, key = CrutchAlertsExtensions.genericPool:AcquireObject()

local function CreateRect(x, y, z, pitch, yaw, roll, width, height, color, texture, text)
    if (not genericPool) then
        genericPool = ZO_ControlPool:New("CrutchAlertsExtensionsGenericTexture", CrutchAlertsSpace)
        CAE.genericPool = genericPool
        -- TODO: reset function?
    end

    local control, key = genericPool:AcquireObject()

    if (first) then
        control:SetParent(first)
        control:SetAnchor(CENTER, first, CENTER)
        control:SetTransformScale(0.01)
    else
        control:SetAnchor(CENTER, GuiRoot, CENTER)
    end

    control:SetSpace(SPACE_WORLD)
    control:SetTransformNormalizedOriginPoint(0.5, 0.5)
    control:SetHidden(false)
    control:SetColor(unpack(color))

    control:SetDimensions(width * 100, height * 100)
    control:SetTexture(texture or "CrutchAlerts/assets/floor/square.dds")
    -- control:SetTexture("/art/fx/texture/modelfxtextures/sovengardetablet_d.dds")
    -- control:SetTexture("CrutchAlerts/assets/shape/diamond_blue_" .. key .. ".dds")

    -- local oX, oY, oZ = GuiRender3DPositionToWorldPosition(0, 0, 0)
    -- local tX = (x - oX) / 100
    -- local tY = y / 100
    -- local tZ = (z - oZ) / 100
    -- control:SetTransformOffset(tX, tY, tZ)
    control:SetTransformOffset(x, y, z)

    control:SetTransformRotation(pitch, yaw, roll)

    if (text) then
        local label = WINDOW_MANAGER:CreateControl("$(parent)Label", control, CT_LABEL)
        label:SetFont("$(STONE_TABLET_FONT)|20|soft-shadow-thick")
        label:SetText("Here lies\nKyzeragon\n\nAug 1, 2026")
        label:SetColor(.1, .1, .1, 1)
        label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
        label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
        d(label:GetName())
        label:SetAnchorFill(control)
    end
    

    return control, key
end

local function CalculateValues(x1, y1, z1, x2, y2, z2, x3, y3, z3)
    -- Midpoint
    local oX = (x1 + x2) / 2
    local oY = (y1 + y2) / 2
    local oZ = (z1 + z2) / 2

    local height = math.sqrt((x3 - x2)^2 + (y3 - y2)^2 + (z3 - z2)^2)
    local width = math.sqrt((x3 - x1)^2 + (y3 - y1)^2 + (z3 - z1)^2)
    local pitch = math.atan2(z3 - z2, y3 - y2)
    local yaw = math.atan2(z3 - z1, x3 - x1)
    local roll = -math.atan2(x3 - x2, y3 - y2)

    d("---",
        "oX " .. oX,
        "oY " .. oY,
        "oZ " .. oZ,
        "pitch " .. pitch,
        "yaw " .. yaw,
        "roll " .. roll,
        "width " .. width,
        "height " .. height)

    -- return CreateRect(oX, oY, oZ, pitch, yaw, roll, width, height)
    return oX, oY, oZ, pitch, yaw, roll, width, height
end

local elements = {
    -- top left, bottom right, top right
    {coords = {0, 0, 0, 0, 0, 0, 0, 0, 0}, color = {.9, .9, .9, 1}, texture = "CrutchAlerts/assets/floor/square.dds"},
    {coords = {-.8, 2, .3, .8, 0, .3, .8, 2, .3}, color = {.5, .5, .5, 1}, texture = "/art/fx/texture/modelfxtextures/sovengardetablet_d.dds", text = true},
    {coords = {-.8, 2, 0, .8, 0, 0, .8, 2, 0}, color = {.5, .5, .5, 1}, texture = "/art/fx/texture/modelfxtextures/sovengardetablet_d.dds"},

    -- {coords = {-.8, 2, 0, -.8, 0, .3, -.8, 2, .3}, color = {.4, .4, .4, 1}, texture = "/art/fx/texture/modelfxtextures/sovengardetablet_s.dds"},
    -- {coords = {-.8, 2, 0, .8, 2, .3, .8, 2, 0}, color = {.45, .45, .45, 1}, texture = "/art/fx/texture/modelfxtextures/sovengardetablet_s.dds"},
    -- {coords = {.8, 2, .3, .8, 0, 0, .8, 2, 0}, color = {.4, .4, .4, 1}, texture = "/art/fx/texture/modelfxtextures/sovengardetablet_s.dds"},

    {coords = {-.8, 2, 0, -.8, 0, .3, -.8, 2, .3}, color = {1, 1, 1, 1}, texture = "/art/fx/texture/modelfxtextures/sovengardetablet_s.dds"},
    {coords = {-.8, 2, 0, .8, 2, .3, .8, 2, 0}, color = {1, 1, 1, 1}, texture = "/art/fx/texture/modelfxtextures/sovengardetablet_s.dds"},
    {coords = {.8, 2, .3, .8, 0, 0, .8, 2, 0}, color = {1, 1, 1, 1}, texture = "/art/fx/texture/modelfxtextures/sovengardetablet_s.dds"},

    -- {-.5, .5, 0, .5, -5, 0, .5, .5, 0},
    -- {-1, 3, 0, 1, 0, 0, 1, 3, 0},
    -- {-1, 3, 0, 1, 0, 1, 1, 3, 1},
    -- {-1, 0, -.5, 0, 1, .5, -1, 0, .5},
}
local function Test()
    local num = 1
    for _, rect in ipairs(elements) do

        -- local oX, oY, oZ, pitch, yaw, roll, width, height = CalculateValues(unpack(coord))
        local oX, oY, oZ, pitch, yaw, roll, width, height = CalculateValues(unpack(rect.coords))
        local control, key = CreateRect(oX, oY, oZ, pitch, yaw, roll, width, height, rect.color, rect.texture, rect.text)
        
        if (not first) then
            first = control
        end
    end

    local _, x, y, z = GetUnitRawWorldPosition("player")
    local oX, oY, oZ = GuiRender3DPositionToWorldPosition(0, 0, 0)
    local tX = (x - oX) / 100
    local tY = y / 100
    local tZ = (z - oZ) / 100
    first:SetTransformOffset(tX, tY, tZ)
end
CAE.Test = Test
--[[
/script CrutchAlertsExtensions.Test()
/script CrutchAlerts.Drawing.RemoveWorldTexture("2")
/script CrutchAlertsDrawingCrutchAlertsDrawingTexture1:Set3DRenderSpaceOrientation(0, 0, 0)
/script CrutchAlertsDrawingCrutchAlertsDrawingTexture3:Set3DRenderSpaceOrientation(math.pi, math.pi/2, -2.356)
/script CrutchAlerts.Drawing.AttachControl(CrutchAlertsSpaceCrutchAlertsExtensionsGenericTexture1, "player", "TestKey")
/script CrutchAlerts.Drawing.UnattachControl(CrutchAlertsSpaceCrutchAlertsExtensionsGenericTexture1, "TestKey")

]]
