local CAE = CrutchAlertsExtensions
local Crutch = CrutchAlerts


---------------------------------------------------------------------
local LINE_NUM = 3 -- TODO: check if this clashes but probably not
function CAE.DrawLine(tag1, tag2)
    if (not tag1 or not tag2) then return end

    Crutch.SetLineColor(1, 0, 0, 1, 1, Crutch.savedOptions.debugLineDistance, LINE_NUM)
    Crutch.DrawLineBetweenPlayers(tag1, tag2, LINE_NUM)
end
