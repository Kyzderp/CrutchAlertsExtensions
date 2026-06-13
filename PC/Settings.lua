local CAE = CrutchAlertsExtensions


---------------------------------------------------------------------
local currentRgb = false
local currentColor = {1, 1, 1, 1}
local currentSize = 8
local currentYOffset = 5
local currentConditionalAbility

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
local lineTag1, lineTag2
local groupMemberTags = {}
local groupMemberNames = {}
local function RefreshGroupMembers()
    ZO_ClearTable(groupMemberTags)
    ZO_ClearTable(groupMemberNames)
    for i = 1, GetGroupSize() do
        local tag = GetGroupUnitTagByIndex(i)
        if (tag and IsUnitOnline(tag)) then
            table.insert(groupMemberTags, tag)
            table.insert(groupMemberNames, zo_strformat("<<1>> <<2>> (<<3>>)", GetUnitName(tag), GetUnitDisplayName(tag), tag))
        end
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
            type = "dropdown",
            name = "Current profile for " .. GetUnitDisplayName("player"),
            tooltip = "Choose a profile. The default <Empty> profile is provided for convenience, so you can turn off all shapes by loading the empty profile. In order to add shapes, create a new profile.",
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
                    currentYOffset = profile.circles[value].yOffset
                    currentConditionalAbility = profile.circles[value].conditionalAbilityId
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
                CAE.LoadCurrentProfile()
                RefreshShapes()
            end,
            warning = "Remove the selected shape from the profile",
            isDangerous = true,
            width = "full",
            disabled = function() return CAE.csvs.currentProfile == -1 or currentShape == nil end, -- Don't allow editing default
        },
        {
            type = "button",
            name = "Add circle",
            tooltip = "Add a circle with the below color and radius to the current profile. The properties can be edited later",
            func = function()
                local id = CAE.AddCircleToProfile(currentRgb, currentColor, currentSize, currentYOffset, currentConditionalAbility)
                CAE.LoadCurrentProfile()
                RefreshShapes()
                currentShape = id
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
---------------------------------------------------------------------
        {
            type = "description",
            title = "|c08BD1DOther Utilities|r",
            text = "These \"settings\" are not part of the settings profile above.",
            width = "full",
        },
        {
            type = "dropdown",
            name = "Draw line player 1",
            tooltip = "Choose group members to draw a line between. Because M0R really wants this in a dropdown. Hint: you can show the distance in the main CrutchAlerts settings > Debug > Show line distance. Note that this is assigned by unit tag, so the players connected by the line may change when unit tags change",
            choices = {},
            choicesValues = {},
            getFunc = function()
                RefreshGroupMembers()
                CAE_Line1Dropdown:UpdateChoices(groupMemberNames, groupMemberTags)
                return lineTag1
            end,
            setFunc = function(value)
                lineTag1 = value
                CAE.DrawLine(lineTag1, lineTag2)
            end,
            width = "full",
            reference = "CAE_Line1Dropdown",
        },
        {
            type = "dropdown",
            name = "Draw line player 2",
            tooltip = "Choose group members to draw a line between. Because M0R really wants this in a dropdown. Hint: you can show the distance in the main CrutchAlerts settings > Debug > Show line distance. Note that this is assigned by unit tag, so the players connected by the line may change when unit tags change",
            choices = {},
            choicesValues = {},
            getFunc = function()
                RefreshGroupMembers()
                CAE_Line2Dropdown:UpdateChoices(groupMemberNames, groupMemberTags)
                return lineTag2
            end,
            setFunc = function(value)
                lineTag2 = value
                CAE.DrawLine(lineTag1, lineTag2)
            end,
            width = "full",
            reference = "CAE_Line2Dropdown",
        },
        {
            type = "button",
            name = "Remove line",
            tooltip = "Remove the line if there is one",
            func = function()
                CAE.RemoveLine()
            end,
            width = "full",
        },
    }

    LAM:RegisterAddonPanel("CrutchAlertsExtensionsOptions", panelData)
    LAM:RegisterOptionControls("CrutchAlertsExtensionsOptions", optionsData)
end