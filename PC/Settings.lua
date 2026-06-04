local CAE = CrutchAlertsExtensions


---------------------------------------------------------------------
local currentRgb = false
local currentColor = {1, 1, 1, 1}
local currentSize = 8
local currentYOffset = 5

local profileNames = {}
local profileIds = {}
local function RefreshProfiles()
    ZO_ClearTable(profileNames)
    ZO_ClearTable(profileIds)
    for id, data in pairs(CAE.svs.profiles) do
        table.insert(profileNames, data.profileName)
        table.insert(profileIds, id)
    end

    CAE_ProfilesDropdown:UpdateChoices(profileNames, profileIds)
end

local shapeNames = {}
local shapeIds = {}
local function RefreshShapes()
    ZO_ClearTable(shapeNames)
    ZO_ClearTable(shapeIds)
    local profile = CAE.svs.profiles[CAE.svs.currentProfile]
    for id, data in pairs(profile.circles) do
        table.insert(shapeNames, "Circle: " .. data.size) -- TODO: color
        table.insert(shapeIds, id)
    end

    CAE_ShapesDropdown:UpdateChoices(shapeNames, shapeIds)
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
            name = "Profiles",
            tooltip = "Choose a profile. The default empty profile is provided for convenience, so you can turn off all shapes by loading the empty profile. In order to add shapes, create a new profile.",
            choices = {},
            choicesValues = {},
            getFunc = function()
                RefreshProfiles()
                return CAE.svs.currentProfile
            end,
            setFunc = function(value)
                CAE.svs.currentProfile = value
            end,
            width = "half",
            reference = "CAE_ProfilesDropdown",
        },
        {
            type = "editbox",
            name = "Profile name",
            tooltip = "Rename the profile by changing this text",
            getFunc = function() return CAE.svs.profiles[CAE.svs.currentProfile].profileName end,
            setFunc = function(name)
                if (not name or name == "") then return end

                CAE.svs.profiles[CAE.svs.currentProfile].profileName = name

                RefreshProfiles()
            end,
            isMultiline = false,
            isExtraWide = false,
            width = "half",
        },
        {
            type = "button",
            name = "Create profile",
            tooltip = "Create a new profile",
            func = function()
                CAE.CreateProfile()
                RefreshProfiles()
            end,
            width = "half",
        },
        {
            type = "button",
            name = "Delete profile",
            tooltip = "Delete the currently selected profile. This cannot be undone!",
            func = function()
                CAE.DeleteProfile(CAE.svs.currentProfile)
                RefreshProfiles()
            end,
            warning = "Delete the currently selected profile. This cannot be undone!",
            isDangerous = true,
            width = "half",
            disabled = function() return CAE.svs.currentProfile == -1 end, -- Don't allow deleting default
        },
        {
            type = "description",
            title = "|c08BD1DAdd Shape|r",
            text = "Add a shape here by adjusting the color and size, then clicking the Add button",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Use RGB",
            tooltip = "Whether to cycle through all colors instead of being a static color",
            default = false,
            getFunc = function() return currentRgb end,
            setFunc = function(value)
                currentRgb = value
            end,
            width = "half",
        },
        {
            type = "colorpicker",
            name = "Shape color",
            tooltip = "The color of the shape to add. Note that this color includes opacity, so it may appear darker in the settings menu than it actually is",
            default = ZO_ColorDef:New(1, 1, 1, 1),
            getFunc = function() return unpack(currentColor) end,
            setFunc = function(r, g, b, a)
                currentColor = {r, g, b, a}
            end,
            width = "half",
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
            end,
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
            end,
        },
        {
            type = "button",
            name = "Add Circle",
            tooltip = "Add a circle with the above color and radius to the current profile",
            func = function()
                CAE.AddCircleToProfile(currentRgb, currentColor, currentSize, currentYOffset)
            end,
            width = "full",
        },
        {
            type = "description",
            title = "|c08BD1DRemove Shape|r",
            text = "Remove a shape here by selecting it from the dropdown, then clicking the Remove button",
            width = "full",
        },
        {
            type = "dropdown",
            name = "Shapes",
            choices = {},
            choicesValues = {},
            getFunc = function()
                RefreshShapes()
                return currentShape
            end,
            setFunc = function(value)
                currentShape = value
            end,
            width = "half",
            reference = "CAE_ShapesDropdown",
        },
    }

    LAM:RegisterAddonPanel("CrutchAlertsExtensionsOptions", panelData)
    LAM:RegisterOptionControls("CrutchAlertsExtensionsOptions", optionsData)
end