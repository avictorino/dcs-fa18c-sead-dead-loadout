F/A-18C SEAD/DEAD Loadout Extension - v0.5
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

HOW THE SCRIPTS WORK (minimal footprint in the stock files)
------------------------------------------------------------
Instead of replacing FA-18C_hornet.lua wholesale, or even inlining
this mod's logic into it, Install.ps1 appends ONE tiny marker-wrapped
block to the END of the file:
  -- >>> SEAD_DEAD_MOD ... -- <<< SEAD_DEAD_MOD
That block does nothing but loadfile() this mod's own
CustomWeapons\dead_sead_racks.lua and call it, passing in the file's
local outboardLeft/outboardRight/inboardLeft/inboardRight pylon-option
tables as arguments (loadfile()+call is used instead of dofile()
specifically so those tables can be passed in - dead_sead_racks.lua
is otherwise a separate Lua chunk with no access to another file's
locals). ALL of the actual mod logic - the two declare_loadout() rack
definitions and the table.insert() calls that add them as pylon
options - lives in that one file, not in FA-18C_hornet.lua. This
still works because make_FA_18C_hornet() is only invoked from outside
the file, later, by which point dead_sead_racks.lua has already
mutated those tables.
The call is wrapped in pcall, so if dead_sead_racks.lua ever fails to
load, it logs the error (log.write, falling back to print) instead
of breaking aircraft loading.
UnitPayloads\FA-18C_hornet.lua gets the same treatment: one tiny block
inserted right before its mandatory "return unitPayloads" line, which
loadfile()+calls CustomWeapons\dead_sead_presets.lua, passing in the
local `unitPayloads` table - that file does the actual
table.insert(unitPayloads.payloads, ...) for the two rearm presets.
Both loadfile() calls use an absolute path baked in by Install.ps1 at
install time (not current_mod_path or lfs.currentdir()), since
there's no guarantee either of those globals is valid in whatever Lua
state loads the payloads file.
Uninstall.ps1 deletes everything between the markers in both files
(each checked/skipped independently, so a partially-applied previous
install can't cause a double-insert) and removes both CustomWeapons
files it added - leaving any other mod's edits to the same files
untouched. Originals are backed up to .\backups\<timestamp>\ before
the first patch, as a safety net.

UPGRADING FROM AN OLDER VERSION OF THIS MOD
-----------------------------------------------
Older versions of Install.ps1 inlined the rack options and rearm
presets directly into FA-18C_hornet.lua / UnitPayloads\FA-18C_hornet.lua
instead of delegating to CustomWeapons\dead_sead_racks.lua /
dead_sead_presets.lua. If you installed one of those earlier versions,
run this version's Uninstall.ps1 first (it strips the old marker
block just as well as the new one), then run Install.ps1 again to get
the current, minimal-footprint version.

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
