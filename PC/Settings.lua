local CAE = CrutchAlertsExtensions


---------------------------------------------------------------------
local currentRgb = false
local currentColor = {1, 1, 1, 1}
local currentSize = 8
local currentWidth = 8
local currentHeight = 8
local currentYOffset = 5
local currentConditionalAbility
local currentConditionalSetId
local currentDepthBuffers = false

local currentShape

local profileNames = {}
local profileIds = {}
local function RefreshProfiles()
    ZO_ClearTable(profileNames)
    ZO_ClearTable(profileIds)
    for id, data in pairs(CAE.profiles) do
        table.insert(profileNames, data.profileName)
        table.insert(profileIds, id)
    end

    CAE_ProfilesDropdown:UpdateChoices(profileNames, profileIds)
end

local function ColorToHexString(color)
    return string.format("%02x%02x%02x",
        math.floor(color[1] * 255),
        math.floor(color[2] * 255),
        math.floor(color[3] * 255))
end

local function ColorCircleText(rgb, color, radius)
    if (rgb) then
        return "|cFF0000C" ..
               "|cFF7F00i" ..
               "|cFFFF00r" ..
               "|c00FF00c" ..
               "|c0000FFl" ..
               "|c2E2B5Fe" ..
               "|c8B00FF:|r " .. radius
    else
        return zo_strformat("|c<<1>>Circle|r: <<2>>", ColorToHexString(color), radius)
    end
end

local shapeNames = {}
local shapeIds = {}
local function RefreshShapes()
    ZO_ClearTable(shapeNames)
    ZO_ClearTable(shapeIds)
    local profile = CAE.profiles[CAE.csvs.currentProfile]
    for id, data in pairs(profile.circles) do
        table.insert(shapeNames, ColorCircleText(data.rgb, data.color, data.radius))
        table.insert(shapeIds, id)
    end

    CAE_ShapesDropdown:UpdateChoices(shapeNames, shapeIds)
end

---------------------------------------------------------------------
local currentLine, currentPlayer1, currentPlayer2
local currentLineColor = {1, 1, 1, 1}
local currentShowDistance = false

local lineNames = {}
local lineIds = {}
local function RefreshLines()
    ZO_ClearTable(lineNames)
    ZO_ClearTable(lineIds)

    local profile = CAE.profiles[CAE.csvs.currentProfile]
    for id, data in pairs(profile.lines) do
        table.insert(lineNames, zo_strformat("|c<<1>><<2>> - <<3>>", ColorToHexString(data.color), data.player1 or "self", data.player2 or "self"))
        table.insert(lineIds, id)
    end

    CAE_LinesDropdown:UpdateChoices(lineNames, lineIds)
end

---------------------------------------------------------------------
local function ResetCurrentValues()
    currentRgb = false
    currentColor = {1, 1, 1, 1}
    currentSize = 8
    currentWidth = 8
    currentHeight = 8
    currentYOffset = 5
    currentConditionalAbility = nil
    currentConditionalSetId = nil
    currentDepthBuffers = false
end

local function ResetCurrentLineValues()
    currentPlayer1 = nil
    currentPlayer2 = nil
    currentLineColor = {1, 1, 1, 1}
    currentShowDistance = false
end

local function ConcatTables(tab1, tab2)
    for _, v in ipairs(tab2) do
        table.insert(tab1, v)
    end
end


---------------------------------------------------------------------
function CAE.CreateSettingsMenu()
    local LAM = LibAddonMenu2
    local panelData = {
        type = "panel",
        name = "|c08BD1DCrutchAlerts Extensions|r",
        author = "Kyzeragon",
        version = CAE.version,
        registerForRefresh = true,
        registerForDefaults = true,
    }

    local optionsData = {
        {
            type = "description",
            text = "These are persistent settings that are saved in installation-wide profiles, which can be chosen on a per-character basis. The default <Empty> profile is provided for convenience, so you can turn off all shapes by loading the empty profile. In order to add shapes, create a new profile.",
            width = "full",
        },
        {
            type = "dropdown",
            name = "Current profile for " .. GetUnitDisplayName("player"),
            tooltip = "Choose a profile to edit, duplicate, or delete",
            choices = {},
            choicesValues = {},
            getFunc = function()
                RefreshProfiles()
                return CAE.csvs.currentProfile
            end,
            setFunc = function(value)
                CAE.csvs.currentProfile = value
                CAE.LoadCurrentProfile()
            end,
            width = "full",
            reference = "CAE_ProfilesDropdown",
        },
        {
            type = "editbox",
            name = "Rename current profile",
            tooltip = "Rename the profile by changing this text",
            getFunc = function() return CAE.profiles[CAE.csvs.currentProfile].profileName end,
            setFunc = function(name)
                if (not name or name == "") then return end

                CAE.profiles[CAE.csvs.currentProfile].profileName = name

                RefreshProfiles()
            end,
            isMultiline = false,
            isExtraWide = false,
            width = "full",
            disabled = function() return CAE.csvs.currentProfile == -1 end, -- Don't allow renaming default
        },
        {
            type = "button",
            name = "Create new profile",
            tooltip = "Create a new profile",
            func = function()
                CAE.CreateProfile()
                RefreshProfiles()
            end,
            width = "half",
        },
        {
            type = "button",
            name = "Duplicate profile",
            tooltip = "Duplicate the current profile",
            func = function()
                CAE.DuplicateProfile()
                RefreshProfiles()
            end,
            width = "half",
        },
        {
            type = "button",
            name = "Delete current profile",
            tooltip = "Delete the currently selected profile. This cannot be undone!",
            func = function()
                CAE.DeleteProfile(CAE.csvs.currentProfile)
                RefreshProfiles()
            end,
            warning = "Delete the currently selected profile. This cannot be undone!",
            isDangerous = true,
            width = "half",
            disabled = function() return CAE.csvs.currentProfile == -1 end, -- Don't allow deleting default
        },
    }
---------------------------------------------------------------------
    ConcatTables(optionsData, CAE.GetSynergySettings())
    ConcatTables(optionsData, CAE.GetUnitIconsSettings())
---------------------------------------------------------------------
    ConcatTables(optionsData, {
        {
            type = "description",
            title = "|c08BD1DShapes|r",
            text = "Add or edit a shape here by clicking the Add button or selecting from the dropdown, then editing the properties.",
            width = "full",
        },
        {
            type = "dropdown",
            name = "Current shape",
            choices = {},
            choicesValues = {},
            getFunc = function()
                RefreshShapes()
                return currentShape
            end,
            setFunc = function(value)
                currentShape = value
                local profile = CAE.profiles[CAE.csvs.currentProfile]
                if (value and profile.circles[value]) then
                    currentRgb = profile.circles[value].rgb
                    currentColor = profile.circles[value].color
                    currentSize = profile.circles[value].radius
                    currentWidth = profile.circles[value].width
                    currentHeight = profile.circles[value].height
                    currentYOffset = profile.circles[value].yOffset
                    currentConditionalAbility = profile.circles[value].conditionalAbilityId
                    currentConditionalSetId = profile.circles[value].conditionalSetId
                    currentDepthBuffers = profile.circles[value].depthBuffers
                end
            end,
            width = "full",
            reference = "CAE_ShapesDropdown",
            disabled = function() return CAE.csvs.currentProfile == -1 end, -- Don't allow editing default
        },
        {
            type = "button",
            name = "Remove shape",
            tooltip = "Remove the currently selected shape",
            func = function()
                CAE.RemoveCircleFromProfile(currentShape)
                currentShape = nil
                CAE.LoadCurrentProfile()
                RefreshShapes()
                ResetCurrentValues()
            end,
            warning = "Remove the selected shape from the profile?",
            isDangerous = true,
            width = "full",
            disabled = function() return CAE.csvs.currentProfile == -1 or currentShape == nil end, -- Don't allow editing default
        },
        {
            type = "button",
            name = "Add circle",
            tooltip = "Add a new circle to the current profile. The properties can be edited later",
            func = function()
                ResetCurrentValues()
                local id = CAE.AddCircleToProfile(currentRgb, currentColor, currentSize, currentYOffset, currentConditionalAbility, currentConditionalSetId, currentDepthBuffers)
                CAE.LoadCurrentProfile()
                currentShape = id
                RefreshShapes()
            end,
            width = "full",
            disabled = function() return CAE.csvs.currentProfile == -1 end, -- Don't allow editing default
        },
        {
            type = "button",
            name = "Add rectangle",
            tooltip = "Add a new rectangle to the current profile. The properties can be edited later",
            func = function()
                ResetCurrentValues()
                local id = CAE.AddRectangleToProfile(currentRgb, currentColor, currentWidth, currentHeight, currentYOffset, currentConditionalAbility, currentConditionalSetId)
                CAE.LoadCurrentProfile()
                currentShape = id
                RefreshShapes()
            end,
            width = "full",
            disabled = function() return CAE.csvs.currentProfile == -1 end, -- Don't allow editing default
        },
        {
            type = "checkbox",
            name = "Use RGB",
            tooltip = "Whether to cycle through all colors instead of being a static color",
            default = false,
            getFunc = function() return currentRgb end,
            setFunc = function(value)
                currentRgb = value
                CAE.profiles[CAE.csvs.currentProfile].circles[currentShape].rgb = currentRgb
                CAE.LoadCurrentProfile()
                RefreshShapes()
            end,
            width = "half",
            disabled = function() return CAE.csvs.currentProfile == -1 or currentShape == nil end, -- Don't allow editing default
        },
        {
            type = "slider",
            name = "Size (cm)",
            tooltip = "The size in centimeters of the shape. For circles, this indicates the radius",
            min = 0,
            max = 4800,
            step = 50,
            default = 800,
            width = "half",
            getFunc = function() return currentSize * 100 end,
            setFunc = function(value)
                currentSize = value / 100
                CAE.profiles[CAE.csvs.currentProfile].circles[currentShape].radius = currentSize
                CAE.LoadCurrentProfile()
                RefreshShapes()
            end,
            disabled = function() return CAE.csvs.currentProfile == -1 or currentShape == nil end, -- Don't allow editing default
        },
        {
            type = "colorpicker",
            name = "Shape color",
            tooltip = "The color of the shape to add. Note that this color includes opacity, so it may appear darker in the settings menu than it actually is",
            default = ZO_ColorDef:New(1, 1, 1, 1),
            getFunc = function() return unpack(currentColor) end,
            setFunc = function(r, g, b, a)
                currentColor = {r, g, b, a}
                CAE.profiles[CAE.csvs.currentProfile].circles[currentShape].color = currentColor
                CAE.LoadCurrentProfile()
                RefreshShapes()
            end,
            width = "half",
            disabled = function() return CAE.csvs.currentProfile == -1 or currentShape == nil end, -- Don't allow editing default
        },
        {
            type = "slider",
            name = "Y offset (cm)",
            tooltip = "The elevation offset from your feet",
            min = -100,
            max = 100,
            step = 5,
            default = 5,
            width = "half",
            getFunc = function() return currentYOffset end,
            setFunc = function(value)
                currentYOffset = value
                CAE.profiles[CAE.csvs.currentProfile].circles[currentShape].yOffset = currentYOffset
                CAE.LoadCurrentProfile()
                RefreshShapes()
            end,
            disabled = function() return CAE.csvs.currentProfile == -1 or currentShape == nil end, -- Don't allow editing default
        },
        {
            type = "checkbox",
            name = "Hide behind objects",
            tooltip = "Whether to use depth buffers to have icons be hidden by objects. For example, if this is ON, parts of the circle can be covered by hills. In order for this setting to work while ON, you must have \"SubSampling Quality\" set to \"High\" in your Video settings",
            default = false,
            getFunc = function() return currentDepthBuffers end,
            setFunc = function(value)
                currentDepthBuffers = value
                CAE.profiles[CAE.csvs.currentProfile].circles[currentShape].depthBuffers = currentDepthBuffers
                CAE.LoadCurrentProfile()
                RefreshShapes()
            end,
            width = "half",
            disabled = function() return CAE.csvs.currentProfile == -1 or currentShape == nil or 
                CAE.profiles[CAE.csvs.currentProfile].circles[currentShape].type == CAE.RECTANGLE end, -- Don't allow editing default
        },
        {
            type = "editbox",
            name = "Conditional ability ID",
            tooltip = "If specified, this shape will only show when this ability is slotted. Use |c99FF99/crutch printskills|r to see currently slotted IDs",
            getFunc = function() return currentConditionalAbility end,
            setFunc = function(value)
                currentConditionalAbility = tonumber(value)
                CAE.profiles[CAE.csvs.currentProfile].circles[currentShape].conditionalAbilityId = currentConditionalAbility
                CAE.LoadCurrentProfile()
                RefreshShapes()
            end,
            isMultiline = false,
            isExtraWide = false,
            width = "full",
            disabled = function() return CAE.csvs.currentProfile == -1 or currentShape == nil end, -- Don't allow editing default
        },
        {
            type = "editbox",
            name = "Conditional set ID",
            tooltip = "If specified, this shape will only show when this set is equipped with the max bonus (front or back bar). Use |c99FF99/cae printsets|r to see currently equipped set IDs",
            getFunc = function() return currentConditionalSetId end,
            setFunc = function(value)
                currentConditionalSetId = tonumber(value)
                CAE.profiles[CAE.csvs.currentProfile].circles[currentShape].conditionalSetId = currentConditionalSetId
                CAE.LoadCurrentProfile()
                RefreshShapes()
            end,
            isMultiline = false,
            isExtraWide = false,
            width = "full",
            disabled = function() return CAE.csvs.currentProfile == -1 or currentShape == nil end, -- Don't allow editing default
        },
---------------------------------------------------------------------
        {
            type = "description",
            title = "|c08BD1DLines|r",
            text = "Add or edit a line between players here by clicking the Add button or selecting from the dropdown, then editing the properties.",
            width = "full",
        },
        {
            type = "dropdown",
            name = "Current line",
            choices = {},
            choicesValues = {},
            getFunc = function()
                RefreshLines()
                return currentLine
            end,
            setFunc = function(value)
                currentLine = value
                local profile = CAE.profiles[CAE.csvs.currentProfile]
                if (value and profile.lines[value]) then
                    currentPlayer1 = profile.lines[value].player1
                    currentPlayer2 = profile.lines[value].player2
                    currentLineColor = profile.lines[value].color
                    currentShowDistance = profile.lines[value].showDistance
                end
            end,
            width = "full",
            reference = "CAE_LinesDropdown",
            disabled = function() return CAE.csvs.currentProfile == -1 end, -- Don't allow editing default
        },
        {
            type = "button",
            name = "Remove line",
            tooltip = "Remove the currently selected line",
            func = function()
                CAE.RemoveLineFromProfile(currentLine)
                currentLine = nil
                CAE.LoadCurrentLines()
                RefreshLines()
                ResetCurrentLineValues()
            end,
            warning = "Remove the selected line from the profile?",
            isDangerous = true,
            width = "full",
            disabled = function() return CAE.csvs.currentProfile == -1 or currentLine == nil end, -- Don't allow editing default
        },
        {
            type = "button",
            name = "Add line",
            tooltip = "Add a new line to the current profile. The properties can be edited later",
            func = function()
                ResetCurrentLineValues()
                local id = CAE.AddLineToProfile(currentPlayer1, currentPlayer2, currentLineColor, currentShowDistance)
                CAE.LoadCurrentLines()
                currentLine = id
                RefreshLines()
            end,
            width = "full",
            disabled = function() return CAE.csvs.currentProfile == -1 end, -- Don't allow editing default
        },
        {
            type = "editbox",
            name = "Line player 1",
            tooltip = "One of the two account names to draw a line between, when they are in your group. Case sensitive! Leave blank to set it as yourself",
            getFunc = function() return currentPlayer1 end,
            setFunc = function(value)
                if (value == "") then value = nil end
                currentPlayer1 = value
                CAE.profiles[CAE.csvs.currentProfile].lines[currentLine].player1 = currentPlayer1
                CAE.LoadCurrentLines()
                RefreshLines()
            end,
            isMultiline = false,
            isExtraWide = false,
            width = "full",
            disabled = function() return CAE.csvs.currentProfile == -1 or currentLine == nil end, -- Don't allow editing default
        },
        {
            type = "editbox",
            name = "Line player 2",
            tooltip = "One of the two account names to draw a line between, when they are in your group. Case sensitive! Leave blank to set it as yourself",
            getFunc = function() return currentPlayer2 end,
            setFunc = function(value)
                if (value == "") then value = nil end
                currentPlayer2 = value
                CAE.profiles[CAE.csvs.currentProfile].lines[currentLine].player2 = currentPlayer2
                CAE.LoadCurrentLines()
                RefreshLines()
            end,
            isMultiline = false,
            isExtraWide = false,
            width = "full",
            disabled = function() return CAE.csvs.currentProfile == -1 or currentLine == nil end, -- Don't allow editing default
        },
        {
            type = "colorpicker",
            name = "Line color",
            tooltip = "The color of the line to add. Note that this color includes opacity, so it may appear darker in the settings menu than it actually is",
            default = ZO_ColorDef:New(1, 1, 1, 1),
            getFunc = function() return unpack(currentLineColor) end,
            setFunc = function(r, g, b, a)
                currentLineColor = {r, g, b, a}
                CAE.profiles[CAE.csvs.currentProfile].lines[currentLine].color = currentLineColor
                CAE.LoadCurrentLines()
                RefreshLines()
            end,
            width = "full",
            disabled = function() return CAE.csvs.currentProfile == -1 or currentLine == nil end, -- Don't allow editing default
        },
        {
            type = "checkbox",
            name = "Show distance",
            tooltip = "Show the distance in meters attached to the line",
            default = false,
            getFunc = function() return currentShowDistance end,
            setFunc = function(value)
                currentShowDistance = value
                CAE.profiles[CAE.csvs.currentProfile].lines[currentLine].showDistance = currentShowDistance
                CAE.LoadCurrentLines()
                RefreshLines()
            end,
            width = "full",
            disabled = function() return CAE.csvs.currentProfile == -1 or currentLine == nil end, -- Don't allow editing default
        },
    })

    LAM:RegisterAddonPanel("CrutchAlertsExtensionsOptions", panelData)
    LAM:RegisterOptionControls("CrutchAlertsExtensionsOptions", optionsData)
end