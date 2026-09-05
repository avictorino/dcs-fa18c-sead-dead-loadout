F/A-18C SEAD/DEAD Loadout Extension - v0.1 (draft)
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

HOW TO INSTALL (local testing)
-------------------------------
1. Close DCS completely.
2. Copy the "Mods" folder from this package into:
     %USERPROFILE%\Saved Games\DCS\               (stable version)
   or
     %USERPROFILE%\Saved Games\DCS.openbeta\       (OpenBeta version)
   Expected result:
     Saved Games\DCS\Mods\aircraft\FA-18C\FA-18C_hornet.lua
     Saved Games\DCS\Mods\aircraft\FA-18C\CustomWeapons\dead_sead_racks.lua
     Saved Games\DCS\Mods\aircraft\FA-18C\UnitPayloads\FA-18C_hornet.lua
3. Open DCS, go to the Mission Editor, place an F/A-18C and check
   whether the new options show up in the loadout editor (missile
   category, on stations 2/3/7/8).
4. Check %USERPROFILE%\Saved Games\DCS\Logs\dcs.log if something
   doesn't show up (look for "LUA" or "error" around the time the
   Mission Editor loaded the aircraft).

IMPORTANT NOTES
----------------
- This is a GAMEPLAY mod, not a real-world Hornet loadout. HARM and
  Maverick are never mounted on multi-munition racks on the real
  aircraft; here we reuse the TALD/JSOW 3D rack geometry purely for
  gameplay purposes. Visually the missiles may look a bit cramped.
- Breaks Integrity Check (IC). Multiplayer servers with IC enabled
  will reject or kick the client. Use offline / solo campaign only,
  or on servers that explicitly allow third-party mods.
- Back up your setup before testing on top of an install that
  already has other F/A-18C mods (e.g. packages that also override
  FA-18C_hornet.lua) - there can be a "last one written wins"
  conflict depending on install order.
- Rack weights are estimates; adjust after testing flight behavior
  and fuel consumption if needed.

NEXT STEPS (for a DCS User Files release)
-------------------------------------------
- Replace the placeholder Picture with proper rack icons.
- Test on multiplayer without IC to confirm there's no crash.
- Write a changelog and take screenshots for the upload page.
- Finalize the name/versioning before the first upload.
