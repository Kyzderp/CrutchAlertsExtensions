local CAE = CrutchAlertsExtensions
local Crutch = CrutchAlerts


---------------------------------------------------------------------
local function GetBossName(id)
    return Crutch.GetCapitalizedString(id)
end


---------------------------------------------------------------------
-- Hide boss bar at the Scavenging Maw
---------------------------------------------------------------------
local hideBossBar = false
local hooked = false
local function CheckScavengingMaw()
    local bossName = GetUnitName("boss1")
    hideBossBar = (bossName == GetBossName(CRUTCH_BHB_THE_SCAVENGING_MAW))

    if (hideBossBar and not hooked) then
        ZO_PreHook(COMPASS_FRAME, "SetBossBarActive", function(self, ...)
            self.bossBarActive = not hideBossBar
            return hideBossBar
        end)
        hooked = true
    end
end


---------------------------------------------------------------------
---------------------------------------------------------------------
local function OnBossesChanged()
    CheckScavengingMaw()
end


---------------------------------------------------------------------
---------------------------------------------------------------------
local function InitializeBossTriggers()
    local profile = CAE.profiles[CAE.csvs.currentProfile]

    if (profile.hideBossBarScavengingMaw) then
        Crutch.RegisterBossChangedListener("CrutchAlertsExtensionsBossTriggers", OnBossesChanged)
    else
        Crutch.UnregisterBossChangedListener("CrutchAlertsExtensionsBossTriggers")
    end

    OnBossesChanged()
end
CAE.InitializeBossTriggers = InitializeBossTriggers


---------------------------------------------------------------------
---------------------------------------------------------------------
function CAE.GetBossTriggersSettings()
    return {
        {
            type = "description",
            title = "|c08BD1DSpecific Bosses|r",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Hide boss bar at the Scavenging Maw",
            tooltip = "Prevents the base game boss health bar from showing while at the Scavenging Maw encounter in Depths of Malatar, so that the compass will be visible for identifying enemy location",
            default = false,
            getFunc = function() return CAE.profiles[CAE.csvs.currentProfile].hideBossBarScavengingMaw end,
            setFunc = function(value)
                CAE.profiles[CAE.csvs.currentProfile].hideBossBarScavengingMaw = value
                InitializeBossTriggers()
            end,
            width = "full",
        },
    }
end
