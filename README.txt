F/A-18C SEAD/DEAD Loadout Extension - v0.7
====================================================

WHAT IT DOES
------------
Adds two new multi-munition racks to the F/A-18C, reusing the TALD
(BRU-42A) and JSOW (BRU-55) rack architecture already in the game:

  - BRU-55 with 2x AGM-88 HARM     ("{BRU55_2xAGM88}")
  - BRU-42A with 3x AGM-65E Mav    ("{BRU42A_x3_AGM65E}")

Available on wing stations 2, 3, 7, 8 - mix freely in the loadout
editor (e.g. 4 stations of HARM = 8x AGM-88; 4 of Maverick = 12x
AGM-65E; or split them, e.g. 2+2 = 4 HARM + 6 Maverick). That's it -
no rearm-menu presets, no Mission Editor payload templates, just the
two new pylon options. If you want a named quick-select loadout, use
the game's own "Save Payload" button after building it once.

HOW TO INSTALL
---------------
1. Close DCS.
2. Right-click Install.ps1 -> Run with PowerShell as Administrator
   (or open an elevated PowerShell and run `.\Install.ps1`).
   It will try to auto-detect your DCS folder and your Saved Games
   folder, ask you to confirm, and let you type a custom path if it
   can't find (or you decline) either one.
3. Launch DCS, check the F/A-18C loadout editor (stations 2/3/7/8)
   for the two new rack options.

To remove it: run Uninstall.ps1 the same way (as Administrator).

Both scripts also accept explicit paths to skip the prompts:
  .\Install.ps1 -DcsPath "C:\..." -SavedGamesPath "C:\..."

HOW THE SCRIPT WORKS (minimal footprint in the stock file)
-------------------------------------------------------------
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

NOTE: pcall() is NOT available in this Lua state (DCS's aircraft/
weapon database loader) - confirmed empirically. So the call isn't
wrapped in a true try/catch; instead it checks loadfile()'s own
return value (nil + an error string on failure, it doesn't throw),
logging via log.write (falling back to print) if something's wrong
with dead_sead_racks.lua, instead of crashing anything.

The loadfile() path is an absolute path baked in by Install.ps1 at
install time (not current_mod_path or lfs.currentdir()), since
there's no guarantee that global is valid in every Lua state that
might load this file.

Because loadfile() is plain Lua/OS file access - it doesn't go through
DCS's own mod/VFS system - dead_sead_racks.lua doesn't need to live
under the DCS install at all. Install.ps1 places it in your SAVED
GAMES folder instead:
  <Saved Games>\DCS\Mods\aircraft\FA-18C\CustomWeapons\dead_sead_racks.lua
using the same Saved Games path it already resolved (auto-detected or
typed in) at the start of the script - not Program Files. This keeps
the mod's own logic out of the game install folder entirely, so a DCS
repair/verify pass has no reason to ever touch or flag it. Only the
tiny loader block still has to go into FA-18C_hornet.lua itself,
since that's where the anchor we patch against lives.

Uninstall.ps1 deletes the marker block from FA-18C_hornet.lua (and,
for anyone upgrading from an older version of this mod that also
touched UnitPayloads\FA-18C_hornet.lua and/or placed files under
Program Files, cleans those up too). Any other mod's edits to the
same file are left untouched. The original is backed up to
.\backups\<timestamp>\ before the first patch, as a safety net.

Patching the stock file directly (instead of overriding it from
Saved Games\DCS\Mods) is required because that override folder only
works for cockpit display scripts, not pylon/payload Lua files -
confirmed by testing. This mod's OWN logic file doesn't have that
restriction (see above), since it's reached via a plain absolute
loadfile() path, not through DCS's override/VFS system at all.

MERGING WITH OTHER MODS
-------------------------
Because this only appends near a stable, structural anchor (end of
file) instead of touching the middle of the file, it plays nicely
with most other mods by default - it doesn't matter what they changed
elsewhere. It only breaks if another mod also uses this exact same
marker comment (won't happen) or renames the outboardLeft/
outboardRight/inboardLeft/inboardRight locals (essentially never
happens - those are core Hornet pylon-table names).

IMPORTANT
----------
- Gameplay mod, not a real Hornet loadout - HARM/Maverick don't
  really mount on multi-rail racks; visuals may look cramped.
- Breaks Integrity Check - offline/solo use only.
- A DCS update can revert FA-18C_hornet.lua - just re-run Install.ps1
  after updating (it backs up and patches again).
- Rack weight is an estimate, tune later if flight/fuel feels off.

TODO before a DCS User Files release
--------------------------------------
- Proper rack icons instead of placeholders.
- Multiplayer test without IC.
- Screenshots + changelog for the upload page.
