local CAE = CrutchAlertsExtensions
local Crutch = CrutchAlerts


---------------------------------------------------------------------
local function FindFreeId(tab)
    local i = 1
    while (tab[i] ~= nil) do
        i = i + 1
    end
    return i
end


---------------------------------------------------------------------
function CAE.AddCircleToProfile(rgb, color, radius, yOffset)
    local profile = CAE.profiles[CAE.csvs.currentProfile]

    local index = FindFreeId(profile.circles)
    profile.circles[index] = {
        rgb = rgb,
        color = color,
        radius = radius,
        yOffset = yOffset,
    }

    CAE.msg(zo_strformat("Added circle of radius <<1>> to profile <<2>>", radius, profile.profileName))
end

function CAE.RemoveCircleFromProfile(index)
    local profile = CAE.profiles[CAE.csvs.currentProfile]
    CAE.msg(zo_strformat("Removing circle of radius <<1>> from profile <<2>>", profile.circles[index].radius, profile.profileName))
    profile.circles[index] = nil
end


---------------------------------------------------------------------
function CAE.CreateProfile()
    local id = FindFreeId(CAE.profiles)

    CAE.profiles[id] = {
        profileName = "Profile " .. id,
        circles = {},
    }

    -- Select new
    CAE.csvs.currentProfile = id

    return id
end

function CAE.DeleteProfile(id)
    CAE.profiles[id] = nil

    -- Change all that were using this profile to the default
    local svs = CrutchAlertsExtensionsSavedVariables
    for _, serverData in pairs(svs) do
        for _, accData in pairs(serverData) do
            for _, charData in pairs(accData) do
                if (charData.currentProfile == id) then
                    charData.currentProfile = -1
                end
            end
        end
    end
end
