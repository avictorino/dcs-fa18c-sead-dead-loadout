--[[
	SEAD/DEAD Hornet Mod - custom multi-rack weapon declarations
	Reaproveita a arquitetura de rack do JSOW (BRU-55) ja existente no
	jogo (AircraftWeaponPack), so trocando o payload_CLSID de cada
	"Point0X" para AGM-88 (HARM) ou AGM-65F (Maverick).

	CLSIDs de munição reaproveitados do stock:
		AGM-88 on LAU-118  -> {B06DD79A-F21E-4EB9-BD9D-AB3844618C93}
		AGM-65F on LAU-117 -> LAU_117_AGM_65F

	This file is loaded via loadfile()+call (not dofile()) from
	FA-18C_hornet.lua, which passes its local pylon-option tables in as
	arguments - that's the only reason this file can add the new rack
	options to them, since they're normally out of reach (local to that
	other file's own chunk). Everything else the mod needs lives here.

	SMS/stores page - history of what was tried and reverted:
	1) A REAL stock LAU-88 rack (3x AGM-65E, from agm65_family.lua) DOES
	   show up correctly on the Hornet's stores page, confirming the
	   avionics CAN display multi-item racks in principle.
	2) That rack sets kind_of_shipping = 1 (SUBMUNITION_AND_CONTAINER_
	   SEPARATELY) and adapter_type = {wsType_Weapon, wsType_GContainer,
	   wsType_Support, 4}. Both are kept below (harmless either way -
	   WSTYPE_PLACEHOLDER crashes the Mission Editor's warehouse code in
	   adapter_type/wsTypeOfWeapon, so adapter_type uses the literal id 4
	   instead; only `attribute` tolerates the placeholder).
	3) Tried switching Elements from payload_CLSID+connector_name (this
	   file's original, always-worked-visually technique) to plain
	   ShapeName+connector_name (matching stock lau_88()/lau_117()) on
	   two different rack bodies (a real "LAU-88" shape with hand-copied
	   Position/Rotation offsets, and this same BRU-55 body) - in BOTH
	   cases the missiles stopped rendering entirely (rack body visible,
	   no missile models), for BOTH HARM and Maverick, without SMS ever
	   showing anything either. Reverted to payload_CLSID below - it's
	   the technique that's reliably rendered correctly since this mod's
	   first version. SMS/stores recognition for these racks remains
	   unsolved; see README's "known limitation" section.
]]

local outboardLeft, outboardRight, inboardLeft, inboardRight = ...

local HARM_CLSID = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}"

local HARM_UNIT_MASS = 361.7   -- kg, AGM-88 + LAU-118 combo (aprox.)

local wsType_HARM = {wsType_Weapon, wsType_Missile, wsType_AS_Missile}

-- "Support/adapter rack" type descriptor (see history note above) - kept
-- even though it alone didn't fix SMS recognition, since it's harmless.
local ADAPTER_TYPE = {wsType_Weapon, wsType_GContainer, wsType_Support, 4}

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
-- Rack 2 (Maverick): custom BRU-55 rack with 2x AGM-65G (IIR, same
-- sensor family as F, bigger warhead - Air Force variant). Switched
-- from AGM-65F to AGM-65G specifically because G already has its OWN
-- REAL registered attribute id (126, from its stock LAU-117 single
-- mount) - F has none at all (WSTYPE_PLACEHOLDER even on its single
-- mount). Using G's own genuine id here instead of a borrowed one, to
-- test whether a real (not WSTYPE_PLACEHOLDER, not borrowed) attribute
-- id is what SMS recognition actually keys off - the one field we
-- hadn't varied in any earlier attempt. Also added Cx_item, which the
-- real lau_88()/lau_117() functions set and ours never did.
----------------------------------------------------------------
local MAVERICK_SHAPE = "agm-65g"  -- matches AGM_65G.model in agm65_family.lua
local wsType_Maverick = {wsType_Weapon, wsType_Missile, wsType_AS_Missile}

declare_loadout({
	category        = CAT_MISSILES,
	CLSID           = "{BRU55_2xAGM65G}",
	Picture         = "agm65.png",
	displayName     = _("BRU-55 - 2 x AGM-65G Maverick"),
	wsTypeOfWeapon  = wsType_Maverick,
	attribute       = {4, 4, 32, 126}, -- AGM-65G's own real registered id
	kind_of_shipping = 1, -- SUBMUNITION_AND_CONTAINER_SEPARATELY
	adapter_type     = ADAPTER_TYPE,
	Count           = 2,
	Weight          = 176.0 + 2 * 301.0,  -- real AGM-65G mass (M=301.0)
	Cx_pil          = 0.00244140625 + 2 * 0.001953125,
	Cx_item         = 0.001953125,
	Elements = {
		{ ShapeName = "BRU_55", IsAdapter = true, DrawArgs = {{3, 0.1}} },
		{ connector_name = "Point01", ShapeName = MAVERICK_SHAPE },
		{ connector_name = "Point02", ShapeName = MAVERICK_SHAPE },
	}
})

----------------------------------------------------------------
-- Add both racks as options on all 4 wing stations
----------------------------------------------------------------
local function addOptions(pylonOptionTable)
	table.insert(pylonOptionTable, { CLSID = "{BRU55_2xAGM88}",  Cx_gain_empty = 0.371, Cx_gain_item = 0.621 })
	table.insert(pylonOptionTable, { CLSID = "{BRU55_2xAGM65G}", Cx_gain_empty = 0.338, Cx_gain_item = 1.593 })
end

addOptions(outboardLeft)
addOptions(outboardRight)
addOptions(inboardLeft)
addOptions(inboardRight)
