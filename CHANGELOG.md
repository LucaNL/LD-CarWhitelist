# Changelog

## 2.1.0

- **Security:** the server no longer trusts the `ldCarwhitelistBypass` state bag. The driver of a vehicle can write that vehicle's state bag, so a cheater could unlock a whitelisted vehicle for himself. Use the new server export instead: `exports.ld_carwhitelist:setVehicleBypass(vehicle, true)`. Setting the state bag yourself no longer lets players past the server check.

## 2.0.0 (rewrite)

Completely rewritten as **LD CarWhitelist** (resource `ld_carwhitelist`). Remove the old `CarWhitelist-FiveM` resource before installing.

- Works with ESX, QBCore and Qbox (auto-detected), or standalone with ACE permissions. Before: ESX only.
- Groups of vehicles, each with their own jobs, minimum grade, on-duty option and ACE permission. Before: one list of jobs for all vehicles.
- Players are stopped while they try to get in, instead of being thrown out after getting in.
- The server checks too and removes players without access (also when put in by a script or a cheat).
- Only the driver seat is locked by default; passengers may get in. Per group every seat can be locked.
- Vehicle classes, a state bag exception for other scripts, a staff bypass ACE.
- Optional Discord log, notifications for ox_lib/ESX/QBCore/chat, 8 languages, update check, exports.

## 1.2.0 and older

The original CarWhitelist. Still available as the `v1-legacy` tag.
