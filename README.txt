F/A-18C SEAD/DEAD Loadout Extension - v0.8 (final state)
====================================================

WHAT IT DOES
------------
Adds extra multi-munition options to the F/A-18C's wing stations
(2, 3, 7, 8):

  - BRU-55 with 2x AGM-88 HARM   ("{BRU55_2xAGM88}") - custom rack
  - LAU-88 with 3x AGM-65D       (real, unmodified stock CLSID,
    borrowed from the A-10/F-16's own weapon pack)

Mix freely in the loadout editor (e.g. 4 stations of HARM = 8x AGM-88;
4 of Maverick = 12x AGM-65D; or split them). No rearm-menu presets, no
Mission Editor payload templates - just pylon options. Use the game's
own "Save Payload" button if you want a named quick-select loadout.

HOW TO INSTALL / UNINSTALL
------------------------------
Install:  run Install.ps1 as Administrator (auto-detects DCS + Saved
          Games folders, or pass -DcsPath/-SavedGamesPath).
Uninstall: run Uninstall.ps1 the same way. Removes the marker block
          from FA-18C_hornet.lua and the CustomWeapons files from
          Saved Games; leaves any other mod's edits untouched.

HOW IT WORKS
---------------
Install.ps1 appends one tiny marker-wrapped block to the END of
FA-18C_hornet.lua:
  -- >>> SEAD_DEAD_MOD ... -- <<< SEAD_DEAD_MOD
That block loadfile()s this mod's CustomWeapons\dead_sead_racks.lua
(kept in Saved Games, not under the DCS install - loadfile() is plain
OS file access, doesn't go through DCS's mod/VFS system) and calls it,
passing in the local outboardLeft/outboardRight/inboardLeft/
inboardRight pylon-option tables as arguments - the only reason that
separate file can add options to them at all. This works because
make_FA_18C_hornet() (which builds the actual pylon list from those
tables) is only invoked from outside the file, later - by which point
dead_sead_racks.lua has already mutated them.

pcall() is NOT available in this Lua state (confirmed empirically), so
the loadfile() call is guarded by checking its own return value (nil +
error string on failure, it doesn't throw) instead of a true try/catch.

KNOWN LIMITATION: the HARM rack doesn't show on the SMS/stores page
------------------------------------------------------------------------
The AGM-88 HARM rack (custom, {BRU55_2xAGM88}) mounts and renders
correctly, but the cockpit's own MPCD "STORES" page doesn't show it as
tracked inventory. Extensive testing (see git history on this file for
the full trail) found no fix:
  - Tried kind_of_shipping=1 and adapter_type matching the real stock
    LAU-88 rack's fields - no change.
  - Tried switching from payload_CLSID+connector_name to plain
    ShapeName+connector_name (matching how stock lau_88()/lau_117()
    build their Elements) - this broke visual rendering entirely
    (missiles stopped appearing) without ever fixing SMS recognition,
    on two different rack bodies tried.
  - No real multi-item HARM CLSID exists anywhere in the stock game to
    borrow instead (unlike Maverick, where AGM-65D/E do have real
    LAU-88 combos - see below).
The F/A-18C's clickable-cockpit avionics are compiled, not exposed as
editable Lua at all (no Cockpit\Scripts folder for this aircraft), so
there's no further lever to pull from outside the game's own source.
The HARM rack still works for mounting/carrying/presumably firing via
manual delivery - it just won't show correctly on the SMS readout.

WHY MAVERICK USES A REAL BORROWED CLSID INSTEAD OF A CUSTOM RACK
-----------------------------------------------------------------------
After the same SMS problems affected an early custom Maverick rack, we
found that AGM-65D (and AGM-65E) already have a complete, unmodified
LAU-88 x3 rack declared in the stock AircraftWeaponPack (agm65_family.lua),
originally built for the A-10/F-16. Since it's 100% untouched Eagle
Dynamics data, it renders correctly AND is properly recognized by the
Hornet's SMS - no hack needed. Trade-off: it's whatever Maverick variant
already has a real triple rack (D, E, H, or K) - AGM-65F/G (the
variants people usually associate with the Hornet) have NO real
multi-item rack anywhere in the game, custom or otherwise, that we
could get working with SMS recognition; every attempt at building one
broke visual rendering. Currently set to AGM-65D (IIR-guided, same
"lock and forget" employment as F/G, just a slightly smaller warhead).
To swap the variant, change the CLSID string in dead_sead_racks.lua's
REAL_LAU88_3xAGM65D_CLSID (see agm65_family.lua's lau_88() calls for
the other available real combos: AGM-65E, AGM-65H, AGM-65K).

IMPORTANT
----------
- Gameplay mod, not a real Hornet loadout - HARM/Maverick don't really
  mount on multi-rail racks; visuals may look cramped.
- HARM's SMS/stores page limitation - see above.
- Breaks Integrity Check - offline/solo use only.
- A DCS update can revert FA-18C_hornet.lua - re-run Install.ps1 after
  updating (it backs up and patches again).
- HARM rack weight is an estimate, tune later if flight/fuel feels off.
