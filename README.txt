F/A-18C SEAD/DEAD Loadout Extension - v0.2
====================================================

WHAT IT DOES
------------
Adds two new multi-munition racks to the F/A-18C, reusing the same
adapter architecture already used by the TALD (BRU-42A) and the
JSOW (BRU-55) in the stock game:

  - BRU-55 with 2x AGM-88 HARM      ("{BRU55_2xAGM88}")
  - BRU-42A with 3x AGM-65E Mav     ("{BRU42A_x3_AGM65E}")

These options are freely available on wing stations 2, 3, 7 and 8
in the DCS loadout editor (Mission Editor and the in-campaign
rearm screen), letting the player freely choose position and
combination:

  - 4 stations with HARM  -> 8x AGM-88
  - 4 stations with Mav   -> 12x AGM-65E
  - any mix of the two (e.g. 2+2 HARM / 2+2 Mav = 4 HARM + 6 Mav)

In addition, two PRESETS show up in the Rearm/Refuel menu (F8 ->
Ground Crew -> Request Loadout) and in the Mission Editor dropdown:

  [26] "[SEAD] AGM-88*8, FUEL*1"
  [27] "[SEAD+DEAD] AGM-88*4, AGM-65E*6, FUEL*1"

WHY THIS INSTALLS INTO THE GAME FOLDER (NOT Saved Games\Mods)
----------------------------------------------------------------
DCS's per-user "Saved Games\DCS\Mods\aircraft\<name>" folder is
scanned as an INDEPENDENT PLUGIN (it needs its own entry.lua and
registers as a whole new aircraft/module). It is NOT a transparent
file-level override for an existing CoreMods aircraft's pylon or
payload-preset Lua files. Those files (FA-18C_hornet.lua and
UnitPayloads/FA-18C_hornet.lua) are loaded directly from the
install path via plain dofile(), which does not go through any
Saved-Games shadowing. This was confirmed empirically: a copy
placed under Saved Games\DCS\Mods\aircraft\FA-18C\ produced no
effect and no error - it was simply never read.
Cockpit *display* scripts (indicator Lua under Cockpit\Scripts\...)
are a different, VFS-aware loading path and CAN be overridden from
Saved Games - that's how cosmetic mods (MPD/HUD/JHMCS reskins) work.
Pylon/payload files cannot, in the current DCS version. So this mod
must replace files directly under the DCS install directory.

HOW TO INSTALL (fresh install, from scratch)
-----------------------------------------------
1. Close DCS completely.
2. BACK UP these 2 files from your DCS install before overwriting
   them (so you can always roll back):
     <DCS install>\CoreMods\aircraft\FA-18C\FA-18C_hornet.lua
     <DCS install>\CoreMods\aircraft\FA-18C\UnitPayloads\FA-18C_hornet.lua
   (<DCS install> is usually "C:\Program Files\Eagle Dynamics\DCS World")
3. Copy the "DROP CONTENTS IN MAIN DIRECTORY" folder's contents
   straight into <DCS install> (an elevated/Administrator terminal
   is required, since Program Files is UAC-protected). Example:

     $src = "<path to this package>\DROP CONTENTS IN MAIN DIRECTORY"
     $dst = "C:\Program Files\Eagle Dynamics\DCS World"
     robocopy "$src" "$dst" /E

4. Open DCS, go to the Mission Editor, place an F/A-18C and check
   that the new rack options show up in the loadout editor (missile
   category, on stations 2/3/7/8), and that presets [26]/[27] show
   up in the payload dropdown / rearm menu.
5. Check <SavedGames>\DCS\Logs\dcs.log if something doesn't show up
   (look for "LUA" or "error" around the time the aircraft loaded).

MERGING WITH OTHER MODS THAT ALSO TOUCH FA-18C_hornet.lua
--------------------------------------------------------------
Because this mod replaces the whole FA-18C_hornet.lua file, ANY
other mod that also ships its own copy of that file will conflict
with this one - whichever is installed last simply overwrites the
other's changes. There is no automatic way around this: you must
manually merge the two sets of edits into one file.

General procedure:
  1. Keep a pristine backup of the STOCK FA-18C_hornet.lua (before
     any mod touches it). This is your merge baseline.
  2. Take the diff of each mod against that stock baseline
     separately (e.g. `diff stock.lua mod_A.lua` and
     `diff stock.lua mod_B.lua`).
  3. Apply both sets of changes by hand onto a fresh copy of the
     stock file. Since most weapon mods only touch the CLSID option
     lists for a couple of specific pylon entries (not the whole
     file), the two diffs usually land on different lines and can
     be combined without real conflicts - just copy both mods'
     added/changed lines into the same base file.
  4. If both mods touch the exact same line (a true conflict), you
     have to decide which behavior you want and edit it by hand -
     there's no way to have two different CLSID definitions for the
     literal same rack CLSID string.

WORKED EXAMPLE: merging with the "SVG Modern Air-to-Air Missiles" pack
------------------------------------------------------------------------
That mod (which replaces AIM-120B/AIM-120C with AIM-174B/AIM-260A)
also ships its own FA-18C_hornet.lua. Diffing it against stock shows
it ONLY changes a handful of AIM-120B/C pylon CLSID option lines
(new single-rail variants like "LAU-127_1x_AIM-120B",
"AIM-120C_NO_RAIL_L/R", etc.) on stations 2/3/4/6/7/8. This mod
(SEAD/DEAD Loadout Extension) only touches the AGM-65/AGM-88/BRU-42A/
BRU-55 lines on stations 2/3/7/8. The two sets of edits are on
different lines, so merging is simple:
  1. Start from a fresh copy of the STOCK FA-18C_hornet.lua.
  2. Paste in this mod's two new option lines (BRU55_2xAGM88 and
     BRU42A_x3_AGM65E) into the outboard/inboard pylon tables, and
     add the dofile() line for CustomWeapons/dead_sead_racks.lua
     near the top of the file (see this mod's own FA-18C_hornet.lua
     for the exact lines to copy).
  3. Paste in the SVG pack's AIM-120B/C CLSID line replacements in
     the same tables.
  4. Save the merged file over <DCS install>\CoreMods\aircraft\
     FA-18C\FA-18C_hornet.lua, and also copy this mod's
     CustomWeapons\dead_sead_racks.lua into place (that file has no
     conflict with the SVG pack, since it's a separate file).
Note: the SVG pack does NOT ship its own UnitPayloads\FA-18C_hornet.lua,
so this mod's copy of that file can be installed as-is with no merge
needed.

IMPORTANT NOTES
----------------
- This is a GAMEPLAY mod, not a real-world Hornet loadout. HARM and
  Maverick are never mounted on multi-munition racks on the real
  aircraft; here we reuse the TALD/JSOW 3D rack geometry purely for
  gameplay purposes. Visually the missiles may look a bit cramped.
- Breaks Integrity Check (IC). Multiplayer servers with IC enabled
  will reject or kick the client. Use offline / solo campaign only,
  or on servers that explicitly allow third-party mods.
- A DCS update can silently restore the stock FA-18C_hornet.lua and
  UnitPayloads file, removing this mod - reinstall after updates.
- Rack weights are estimates; adjust after testing flight behavior
  and fuel consumption if needed.

NEXT STEPS (for a DCS User Files release)
-------------------------------------------
- Replace the placeholder Picture with proper rack icons.
- Test on multiplayer without IC to confirm there's no crash.
- Write a changelog and take screenshots for the upload page.
- Finalize the name/versioning before the first upload.
