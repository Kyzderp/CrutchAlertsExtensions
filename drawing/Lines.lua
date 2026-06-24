local CAE = CrutchAlertsExtensions
local Crutch = CrutchAlerts


---------------------------------------------------------------------
local activeLines = {}

-- Gets the unit tag for account name in group, or player if name is nil
local function GetUnitTagForName(name)
    if (name == nil) then return "player" end

    for i = 1, GetGroupSize() do
        local tag = GetGroupUnitTagByIndex(i)
        if (tag and IsUnitOnline(tag)) then
            return tag
        end
    end

    return nil
end

local function UpdateLines()
    local profile = CAE.profiles[CAE.csvs.currentProfile]

    for id, lineData in pairs(profile.lines) do
        local tag1 = GetUnitTagForName(lineData.player1)
        local tag2 = GetUnitTagForName(lineData.player2)
        if (tag1 and tag2) then
            local lineNum = "CAELine" .. id
            local color = lineData.color
            Crutch.DrawLineBetweenPlayers(tag1, tag2, nil, lineNum)
            Crutch.SetLineColor(color[1], color[2], color[3], color[4], 1, Crutch.savedOptions.debugLineDistance, lineNum)
            table.insert(activeLines, lineNum)
        end
    end
end

local function CleanLines()
    for _, lineNum in ipairs(activeLines) do
        Crutch.RemoveLine(lineNum)
    end
    ZO_ClearTable(activeLines)
end

local function LoadCurrentLines()
    CleanLines()
    UpdateLines()
end
CAE.LoadCurrentLines = LoadCurrentLines

function CAE.InitializeLines()
    LoadCurrentLines()

    EVENT_MANAGER:RegisterForEvent(CAE.name .. "LinesPlayerActivated", EVENT_PLAYER_ACTIVATED, LoadCurrentLines)
end
