local CAE = CrutchAlertsExtensions


---------------------------------------------------------------------
-- Presets that can be added with a button
---------------------------------------------------------------------
CAE.PresetShapes = {
    ["Ferocious Roar"] = {
        type = CAE.CIRCLE,
        rgb = false,
        color = {1, 1, 1, 0.1},
        radius = 10,
        yOffset = 5,
        forwardOffset = 0,
        conditionalAbilityId = 39113,
        depthBuffers = false,
    },
    ["Roar of Alkosh"] = {
        type = CAE.RECTANGLE,
        rgb = false,
        color = {0, 0.8, 1, 0.1},
        fillColor = {1, 1, 1, 0},
        radius = 9,
        height = 15,
        yOffset = 5,
        forwardOffset = 750,
        conditionalSetId = 232,
        activeBarOnly = true,
    },
    ["Pragmatic Fatecarver"] = {
        type = CAE.RECTANGLE,
        rgb = false,
        color = {0, 1, 0, 0.2},
        fillColor = {1, 1, 1, 0},
        radius = 3,
        height = 23.5,
        yOffset = 5,
        forwardOffset = 1025,
        conditionalAbilityId = 193398,
        activeBarOnly = true,
    },
}
