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
function CAE.AddCircleToProfile(rgb, color, radius, yOffset, conditionalAbilityId, conditionalSetId, depthBuffers)
    local profile = CAE.profiles[CAE.csvs.currentProfile]

    local index = FindFreeId(profile.circles)
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
-- TODO: prob move to line file
function CAE.AddLineToProfile(player1, player2, color)
    local profile = CAE.profiles[CAE.csvs.currentProfile]

    local index = FindFreeId(profile.lines)
    profile.lines[index] = {
        player1 = player1,
        player2 = player2,
        color = color,
    }

    CAE.msg(zo_strformat("Added line between <<1>> and <<2>> to profile <<3>>", player1, player2, profile.profileName))

    return index
end

function CAE.RemoveLineFromProfile(index)
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
        lines = {},
        hungerRequireModifier = false,
        lowerHunger = false,
        higherFrenzyAndAtro = false,
        iconsForKnownPets = false,
        iconsForPets = false,
        iconsForCompanions = false,
    }

    -- Select new
    CAE.csvs.currentProfile = id

    return id
end

function CAE.DuplicateProfile()
    local id = FindFreeId(CAE.profiles)

    CAE.profiles[id] = ZO_DeepTableCopy(CAE.profiles[CAE.csvs.currentProfile])
    CAE.profiles[id].profileName = "Copy of " .. CAE.profiles[id].profileName

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
