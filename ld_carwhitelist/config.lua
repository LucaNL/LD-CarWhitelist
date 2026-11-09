--[[
    LD CarWhitelist - configuration

    Lock vehicles to jobs or ACE permissions. Players without access can't get in: the game stops them
    while they try to enter, and the server checks again and removes anyone who got in anyway.

    Works with ESX, QBCore and Qbox (detected automatically). Without a framework, use ACE permissions.
]]

Config = {}

----------------------------------------------------------------------------------------------------
-- General
----------------------------------------------------------------------------------------------------
Config.Locale = 'en'            -- en, nl, de, fr, es, pt, pl, tr
Config.VersionCheck = true      -- tell you in the server console when a new version is available
Config.Debug = false

-- Players with this ACE may use every vehicle (staff). `add_ace group.admin ldcw.bypass allow`
Config.BypassAce = 'ldcw.bypass'

----------------------------------------------------------------------------------------------------
-- Groups
--   models     spawn names. Checked by the game AND by the server.
--   classes    vehicle classes, e.g. { 18 } = all emergency vehicles. Checked by the game only
--              (the server can't read classes), so list important models under `models` as well.
--   jobs       job name = minimum grade (0 = every grade)
--   ace        players with this ACE permission may always use the group (nil = none)
--   onDuty     true = jobs only count while on duty (QBCore/Qbox duty, ESX when your ESX has it)
--   seats      'driver' = only driving is locked, passengers may get in (e.g. someone under arrest)
--              'all'    = every seat is locked
--   A vehicle in several groups may be used by anyone with access to one of them.
----------------------------------------------------------------------------------------------------
Config.Groups = {
    {
        label = 'Police',
        models = { 'police', 'police2', 'police3', 'police4', 'policeb', 'policet', 'policeold1', 'policeold2',
            'sheriff', 'sheriff2', 'fbi', 'fbi2', 'pranger', 'riot', 'riot2', 'polmav', 'predator' },
        classes = {},
        jobs = { police = 0, sheriff = 0 },
        ace = 'ldcw.police',
        onDuty = false,
        seats = 'driver',
    },
    {
        label = 'EMS',
        models = { 'ambulance', 'lguard' },
        jobs = { ambulance = 0, ems = 0 },
        ace = 'ldcw.ems',
        seats = 'driver',
    },
    {
        label = 'Fire department',
        models = { 'firetruk' },
        jobs = { fire = 0, firefighter = 0, ambulance = 0 },
        ace = 'ldcw.fire',
        seats = 'driver',
    },
    -- {
    --     label = 'Mechanic',
    --     models = { 'towtruck', 'towtruck2', 'flatbed' },
    --     jobs = { mechanic = 0 },
    -- },
}

----------------------------------------------------------------------------------------------------
-- Server check
--   Every few seconds the server looks at who is driving what, and removes players without access.
--   This also catches players who were put into a vehicle by a script or a cheat.
----------------------------------------------------------------------------------------------------
Config.ServerCheck = true
Config.ServerCheckInterval = 1500   -- milliseconds

----------------------------------------------------------------------------------------------------
-- Notifications
--   'auto' = ox_lib, then ESX, then QBCore/Qbox, then chat. Or 'ox_lib' | 'esx' | 'qb' | 'chat' | 'none'
----------------------------------------------------------------------------------------------------
Config.Notify = 'auto'

----------------------------------------------------------------------------------------------------
-- Discord log (optional): a message when the server had to remove someone, or someone tried to get in.
----------------------------------------------------------------------------------------------------
Config.Webhook = {
    Url = '',                   -- or `set ldcwl_webhook "..."` in server.cfg (that one wins)
    Cooldown = 60,              -- seconds between two messages about the same player
    LogAttempts = true,         -- also log blocked attempts to get in (not only removals)
}
