--[[
	SEAD/DEAD Hornet Mod - custom multi-rack weapon declarations
	Reaproveita a arquitetura de rack do TALD (BRU-42A) e do JSOW (BRU-55)
	ja existentes no jogo (AircraftWeaponPack), so trocando o payload_CLSID
	de cada "Point0X" para AGM-88 (HARM) ou AGM-65F (Maverick).

	CLSIDs de munição reaproveitados do stock (ver FA-18C_hornet.lua original):
		AGM-88 on LAU-118  -> {B06DD79A-F21E-4EB9-BD9D-AB3844618C93}
		AGM-65F on LAU-117 -> LAU_117_AGM_65F

	This file is loaded via loadfile()+call (not dofile()) from
	FA-18C_hornet.lua, which passes its local pylon-option tables in as
	arguments - that's the only reason this file can add the new rack
	options to them, since they're normally out of reach (local to that
	other file's own chunk). Everything else the mod needs lives here.

	SMS/stores page fix: confirmed in-game that a REAL stock LAU-88 rack
	(3x AGM-65E, {71AAB9B8-81C1-4925-BE50-1EF8E9899271} from
	agm65_family.lua) DOES show up correctly on the Hornet's stores page,
	so the avionics CAN display multi-item racks - it isn't a hard
	per-aircraft wall like we first thought. That entry (see the stock
	lau_88() function) sets two fields ours didn't:
		kind_of_shipping = 1  -- SUBMUNITION_AND_CONTAINER_SEPARATELY
		adapter_type = {wsType_Weapon, wsType_GContainer, wsType_Support, 4}
	adapter_type's "4" is the LAU-88 rack-body's own type id - it's the
	same across every AGM-65 variant's LAU-88 entry (not weapon-specific),
	so it's reused here too. Our racks now set both fields, still under
	our own CLSIDs (so AGM-65F, which has no real LAU-88 entry to borrow,
	stays available) - this is the next experiment, needs in-game
	confirmation either way.
]]

local outboardLeft, outboardRight, inboardLeft, inboardRight = ...

local HARM_CLSID     = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}"
local MAVERICK_CLSID = "LAU_117_AGM_65F"

local HARM_UNIT_MASS     = 361.7   -- kg, AGM-88 + LAU-118 combo (aprox.)
local MAVERICK_UNIT_MASS = 210.5   -- kg, AGM-65F + LAU-117 combo (aprox.)

-- NOTE: no WSTYPE_PLACEHOLDER in wsTypeOfWeapon. It only ever becomes a
-- real numeric ID via declare_weapon() - these two racks only
-- declare_loadout() (they're containers for already-existing munitions,
-- not new weapons), so an unresolved placeholder there stayed a raw
-- sentinel value and crashed the Mission Editor's warehouse code
-- (db_main.lua's wsTypeToString, via string.format expecting a number)
-- every time a map was opened. WSTYPE_PLACEHOLDER is fine in `attribute`
-- and `adapter_type` though - confirmed those don't get run through the
-- same formatter, unlike wsTypeOfWeapon.
local wsType_HARM     = {wsType_Weapon, wsType_Missile, wsType_AS_Missile}
local wsType_Maverick = {wsType_Weapon, wsType_Missile, wsType_AS_Missile}

-- Shared "this is a support/adapter rack" type descriptor, matching what
-- every stock LAU-88 AGM-65 entry uses (same tuple regardless of Maverick
-- variant or count - it describes the RACK, not the missile).
local ADAPTER_TYPE = {wsType_Weapon, wsType_GContainer, wsType_Support, WSTYPE_PLACEHOLDER}

----------------------------------------------------------------
-- Rack 1: BRU-55 (corpo do JSOW) com 2x AGM-88 HARM
----------------------------------------------------------------
declare_loadout({
	category        = CAT_MISSILES,
	CLSID           = "{BRU55_2xAGM88}",
	Picture         = "agm88.png",
	displayName     = _("BRU-55 - 2 x AGM-88 HARM"),
	wsTypeOfWeapon  = wsType_HARM,
	attribute       = {4, 4, 32, WSTYPE_PLACEHOLDER},
	kind_of_shipping = 1, -- SUBMUNITION_AND_CONTAINER_SEPARATELY
	adapter_type     = ADAPTER_TYPE,
	Count           = 2,
	Weight          = 176.0 + 2 * HARM_UNIT_MASS,
	Cx_pil          = 0.00244140625 + 2 * 0.001953125,
	Elements = {
		{ ShapeName = "BRU_55", IsAdapter = true, DrawArgs = {{3, 0.1}} },
		{ payload_CLSID = HARM_CLSID, connector_name = "Point01" },
		{ payload_CLSID = HARM_CLSID, connector_name = "Point02" },
	}
})

----------------------------------------------------------------
-- Rack 2: BRU-42A (corpo do TALD triplo) com 3x AGM-65F Maverick
----------------------------------------------------------------
declare_loadout({
	category        = CAT_MISSILES,
	CLSID           = "{BRU42A_x3_AGM65F}",
	Picture         = "agm65.png",
	displayName     = _("BRU-42A - 3 x AGM-65F Maverick"),
	wsTypeOfWeapon  = wsType_Maverick,
	attribute       = {4, 4, 32, WSTYPE_PLACEHOLDER},
	kind_of_shipping = 1, -- SUBMUNITION_AND_CONTAINER_SEPARATELY
	adapter_type     = ADAPTER_TYPE,
	Count           = 3,
	Weight          = 50.80 + 3 * MAVERICK_UNIT_MASS,
	Cx_pil          = 0.00244140625 + 3 * 0.001953125,
	Elements = {
		{ ShapeName = "BRU_42A", IsAdapter = true },
		{ payload_CLSID = MAVERICK_CLSID, connector_name = "Point01" },
		{ payload_CLSID = MAVERICK_CLSID, connector_name = "Point02" },
		{ payload_CLSID = MAVERICK_CLSID, connector_name = "Point03" },
	}
})

----------------------------------------------------------------
-- Add both racks as options on all 4 wing stations
----------------------------------------------------------------
local function addOptions(pylonOptionTable)
	table.insert(pylonOptionTable, { CLSID = "{BRU55_2xAGM88}",    Cx_gain_empty = 0.371, Cx_gain_item = 0.621 })
	table.insert(pylonOptionTable, { CLSID = "{BRU42A_x3_AGM65F}", Cx_gain_empty = 0.338, Cx_gain_item = 1.593 })
end

addOptions(outboardLeft)
addOptions(outboardRight)
addOptions(inboardLeft)
addOptions(inboardRight)
