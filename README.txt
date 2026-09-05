F/A-18C SEAD/DEAD Loadout Extension - v0.4
====================================================

WHAT IT DOES
------------
Adds two new multi-munition racks to the F/A-18C, reusing the TALD
(BRU-42A) and JSOW (BRU-55) rack architecture already in the game:

  - BRU-55 with 2x AGM-88 HARM     ("{BRU55_2xAGM88}")
  - BRU-42A with 3x AGM-65E Mav    ("{BRU42A_x3_AGM65E}")

Available on wing stations 2, 3, 7, 8 - mix freely (e.g. 4 stations
of HARM = 8x AGM-88; 4 of Maverick = 12x AGM-65E; or split them).

Two ready-made presets also show up in the Rearm/Refuel menu and
Mission Editor dropdown:
  [26] "[SEAD] AGM-88*8, FUEL*1"
  [27] "[SEAD+DEAD] AGM-88*4, AGM-65E*6, FUEL*1"

HOW TO INSTALL
---------------
1. Close DCS.
2. Right-click Install.ps1 -> Run with PowerShell as Administrator
   (or open an elevated PowerShell and run `.\Install.ps1`).
   It will try to auto-detect your DCS folder and your Saved Games
   folder, ask you to confirm, and let you type a custom path if it
   can't find (or you decline) either one.
3. Launch DCS, check the F/A-18C loadout editor (stations 2/3/7/8)
   and the rearm menu for the new options.

To remove it: run Uninstall.ps1 the same way (as Administrator).

Both scripts also accept explicit paths to skip the prompts:
  .\Install.ps1 -DcsPath "C:\..." -SavedGamesPath "C:\..."

HOW THE SCRIPTS WORK (no whole-file overwrite)
--------------------------------------------------
Instead of replacing FA-18C_hornet.lua wholesale, Install.ps1 APPENDS
a small block to the END of the file, wrapped in marker comments:
  -- >>> SEAD_DEAD_MOD ... -- <<< SEAD_DEAD_MOD
This works because outboardLeft/outboardRight/inboardLeft/inboardRight
are `local` tables declared earlier in that same file - code appended
at the end of the file still sees them (same Lua chunk) and runs
before make_FA_18C_hornet() is ever called (that happens later, from
outside the file), so the new options are present by the time the
pylon list is built. The new dofile() call that loads this mod's
weapon declarations is wrapped in pcall, so if that file ever fails
to load, it logs the error instead of breaking aircraft loading.
The rearm presets are added to UnitPayloads\FA-18C_hornet.lua the
same way, inserted right before its mandatory "return unitPayloads"
line.
Uninstall.ps1 just deletes everything between the markers, so both
scripts leave any other mod's edits to the same files untouched.
Originals are backed up to .\backups\<timestamp>\ before the first
patch, as a safety net.

This install method (patching CoreMods directly) is required because
Saved Games\DCS\Mods only overrides cockpit display scripts, not
pylon/payload Lua files - confirmed by testing.

MERGING WITH OTHER MODS
-------------------------
Because this only appends near stable, structural anchors (end of
file / the return statement) instead of touching the middle of the
file, it plays nicely with most other mods by default - it doesn't
matter what they changed elsewhere. It only breaks if another mod
also uses these exact same marker comments (won't happen) or renames
the outboardLeft/outboardRight/inboardLeft/inboardRight locals
(essentially never happens - those are core Hornet pylon-table names).

IMPORTANT
----------
- Gameplay mod, not a real Hornet loadout - HARM/Maverick don't
  really mount on multi-rail racks; visuals may look cramped.
- Breaks Integrity Check - offline/solo use only.
- A DCS update can revert these files - just re-run Install.ps1
  after updating (it backs up and patches again).
- Rack weights are estimates, tune later if flight/fuel feels off.

TODO before a DCS User Files release
--------------------------------------
- Proper rack icons instead of placeholders.
- Multiplayer test without IC.
- Screenshots + changelog for the upload page.
