# LD CarWhitelist

**Free vehicle whitelist for FiveM.** Lock police cars, ambulances or any vehicle to jobs or permissions. Players without access are stopped while they try to get in, and the server checks again and removes anyone who got in anyway.

Works with ESX, QBCore and Qbox (detected automatically), or standalone with ACE permissions.

## Features

- **Groups of vehicles with their own access:** Police for `police` and `sheriff`, EMS for `ambulance`, your own groups for mechanics, taxis, gangs ...
- **Access by job and minimum grade**, optionally **only while on duty**, or by **ACE permission** (works without a framework, and with Discord-role-to-ACE scripts).
- **Only the driver seat is locked by default:** passengers can get in, like someone under arrest in the back. Per group you can lock every seat.
- **Stopped before the door opens:** no getting in and being thrown out again.
- **Enforced by the server too:** players put into a vehicle by a script or a cheat are removed. The client is not the only safeguard.
- **Exceptions for other scripts:** set the `ldCarwhitelistBypass` state bag on a vehicle (e.g. a test drive at the dealer).
- **Staff bypass** with one ACE: `ldcw.bypass`.
- Optional **Discord log** when someone tries to take or gets removed from a locked vehicle.
- Notifications through ox_lib, ESX, QBCore/Qbox or chat (auto-detected), 8 languages, update check.

## Install

1. Download the latest release and put the `ld_carwhitelist` folder in your `resources` folder.
2. Add to `server.cfg` (after your framework):
   ```cfg
   ensure ld_carwhitelist
   add_ace group.admin ldcw.bypass allow
   ```
3. Restart the server. Police, EMS and fire vehicles are locked to those jobs out of the box; change the groups in `config.lua`.

Using vehicle classes (`classes = { 18 }`)? Those are checked by the game only, because the server can't read a vehicle's class. For players with access to a class group, the server leaves the decision to the game, so it never removes someone the game allows. List the important models under `models` as well, so the server checks them too.

The server never throws anyone out of a flying aircraft or a moving vehicle: it waits until the vehicle (nearly) stands still.

## For developers

```lua
-- server
local allowed, group = exports.ld_carwhitelist:hasAccess(source, 'police')   -- model name, hash or vehicle entity
exports.ld_carwhitelist:refreshPlayer(source)  -- after you changed a job or permission in your own script

-- client
local allowed, group = exports.ld_carwhitelist:canUse(vehicle, seat)        -- seat defaults to -1 (driver)

-- any side: let everyone use one vehicle (e.g. a test drive)
Entity(vehicle).state:set('ldCarwhitelistBypass', true, true)
```

## Support

Questions or ideas: open an issue, or join the LD Scripts Discord: https://discord.ldscripts.com

## More from LD Scripts

- **LD Queue**: a reliable, fair connection queue with priority, restart protection and a live queue card.
- **LD Refunds**: refunds and compensation for players, with a Discord bot and web dashboard.
- Free: **LD CarWipe** (automatic vehicle cleanup) and **LD TimeDisplay** (real-life clock).

See https://store.ldscripts.com

## License

MIT. Free to use and change on your server.
