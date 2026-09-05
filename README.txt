F/A-18C SEAD/DEAD Loadout Extension - v0.2
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
2. Back up these 2 files from your DCS install folder:
     CoreMods\aircraft\FA-18C\FA-18C_hornet.lua
     CoreMods\aircraft\FA-18C\UnitPayloads\FA-18C_hornet.lua
3. Copy the contents of "DROP CONTENTS IN MAIN DIRECTORY" into your
   DCS install folder (e.g. C:\Program Files\Eagle Dynamics\DCS World).
   Needs an elevated/Administrator terminal (Program Files is UAC-
   protected):
     robocopy "<this package>\DROP CONTENTS IN MAIN DIRECTORY" "C:\Program Files\Eagle Dynamics\DCS World" /E
4. Launch DCS, check the F/A-18C loadout editor (stations 2/3/7/8)
   and the rearm menu for the new options.

Note: this must be installed straight into the game folder, not
Saved Games\DCS\Mods - that folder only overrides cockpit display
scripts, not pylon/payload Lua (confirmed by testing).

MERGING WITH OTHER MODS
-------------------------
This mod replaces FA-18C_hornet.lua whole, so any other mod that
also ships that file will conflict (last one installed wins). To
use both: diff each mod against a pristine stock FA-18C_hornet.lua,
then combine both sets of added/changed lines by hand into one file.
Most weapon mods only touch a few CLSID lines for specific pylons,
so this is usually a clean merge (e.g. this mod's AGM-65/AGM-88
lines don't overlap with the "SVG Modern Air-to-Air Missiles" pack's
AIM-120B/C lines).

IMPORTANT
----------
- Gameplay mod, not a real Hornet loadout - HARM/Maverick don't
  really mount on multi-rail racks; visuals may look cramped.
- Breaks Integrity Check - offline/solo use only.
- A DCS update can revert these files - reinstall after updating.
- Rack weights are estimates, tune later if flight/fuel feels off.

TODO before a DCS User Files release
--------------------------------------
- Proper rack icons instead of placeholders.
- Multiplayer test without IC.
- Screenshots + changelog for the upload page.
