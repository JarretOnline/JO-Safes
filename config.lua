Config = {}

Config.SafeRobbable = true -- Set this to "false" if you don't want other players to be able to crack the safe and steal other people items

Config.SafeStorage = { -- Default storage limit for all safes
    maxweight = 4000000,
    slots = 500
}

Config.PoliceJobs = { -- Jobs which can remove a safe incase of placement in wrong locations
"fbi",
}

Config.Objects = {
    [`p_v_43_safe_s`] = { -- Prop Name
        maxweight = 4000000,
        slots = 500,
        pickable = true -- Ability to carry the safe
    },
    [`prop_ld_int_safe_01`] = {
        maxweight = 2000000,
        slots = 250,
        pickable = true -- Ability to carry the safe
    },
}

Config.Safes = { -- The default safes with object
    ['safe1'] = "p_v_43_safe_s", -- ['item name'] = "object name"
    ['safe2'] = "prop_ld_int_safe_01"
}