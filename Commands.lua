local CAE = CrutchAlertsExtensions


---------------------------------------------------------------------
local function PrintUsage()
    CAE.msg([[Usage:
|cAAAAAA/cae settings
|cAAAAAA/cae utils
|cAAAAAA/cae]])
end

---------------------------------------------------------------------
SLASH_COMMANDS["/cae"] = function(argString)
    local args = {}
    for word in string.gmatch(argString, "%S+") do
        table.insert(args, word)
    end

    if (#args == 0) then
        PrintUsage()
        return
    end
    local cmd = string.lower(args[1])

    ------------
    if (args[1] == "settings") then
        LibAddonMenu2:OpenToPanel(CrutchAlertsExtensionsOptions)

    elseif (args[1] == "utils") then
        LibAddonMenu2:OpenToPanel(CrutchAlertsExtensionsUtils)

    else
        PrintUsage()
    end
end

