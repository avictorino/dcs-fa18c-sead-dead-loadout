--[[
	SEAD/DEAD Hornet Mod - custom multi-rack weapon declarations

	CLSIDs de munição reaproveitados do stock:
		AGM-88 on LAU-118  -> {B06DD79A-F21E-4EB9-BD9D-AB3844618C93}
		AGM-65F on LAU-117 -> LAU_117_AGM_65F

	This file is loaded via loadfile()+call (not dofile()) from
	FA-18C_hornet.lua, which passes its local pylon-option tables in as
	arguments - that's the only reason this file can add the new rack
	options to them, since they're normally out of reach (local to that
	other file's own chunk). Everything else the mod needs lives here.

	SMS/stores page - full history of what we learned getting this to work:
	1) A REAL stock LAU-88 rack (3x AGM-65E, from agm65_family.lua) DOES
	   show up correctly on the Hornet's stores page, so the avionics CAN
	   display multi-item racks - it isn't a hard per-aircraft wall.
	2) That rack sets kind_of_shipping = 1 (SUBMUNITION_AND_CONTAINER_
	   SEPARATELY) and adapter_type = {wsType_Weapon, wsType_GContainer,
	   wsType_Support, 4} - id 4 identifies the LAU-88 rack body itself,
	   shared across every AGM-65 variant's LAU-88 entry, not weapon-
	   specific. Both are now set below. WSTYPE_PLACEHOLDER crashes the
	   Mission Editor's warehouse code if left in adapter_type OR
	   wsTypeOfWeapon (same string.format bug, confirmed twice the hard
	   way) - only `attribute` tolerates it.
	3) Even with both of those fields set, the SMS still didn't show our
	   racks. The real structural difference: stock lau_88()/lau_117()
	   build each missile Element with a plain `ShapeName` (a decorative
	   model matched by name/convention to the already-declared weapon),
	   NOT `payload_CLSID` (which creates a separate, independently-
	   tracked weapon object - the TALD/JSOW pattern we originally copied
	   this whole mod's rack technique from). Switched to ShapeName -
	   "AGM-65F" (matches AGM_65F's own `model` field in agm65_family.lua)
	   and "agm-88" (matches Bazar/World/Shapes/agm-88.edm).
	4) Tried rebuilding the Maverick rack around the real "LAU-88" shape
	   with the exact Position/Rotation offsets stock lau_88() uses - the
	   rack body rendered but the 3 missiles didn't (empty rack visually).
	   Reverted to the BRU-42A body via connector_name (Point01/02/03),
	   which we already know positions correctly (used successfully by
	   this mod since its first version) - same ShapeName-based Elements,
	   just on a body/placement method we know works. Needs in-game
	   confirmation both for rendering and for SMS recognition.
]]

local outboardLeft, outboardRight, inboardLeft, inboardRight = ...

local HARM_SHAPE     = "agm-88"    -- matches Bazar/World/Shapes/agm-88.edm
local MAVERICK_SHAPE = "AGM-65F"   -- matches AGM_65F.model in agm65_family.lua

local HARM_UNIT_MASS     = 361.7   -- kg, AGM-88 + LAU-118 combo (aprox.)
local MAVERICK_UNIT_MASS = 301.0   -- kg, real AGM-65F mass (M=301.0 in AGM_65F's own declare_weapon table) - was 210.5 (a guess), which undercounted vs the real weight the engine now attributes to each ShapeName="AGM-65F" element, causing a "negative weight" warning

local wsType_HARM     = {wsType_Weapon, wsType_Missile, wsType_AS_Missile}
local wsType_Maverick = {wsType_Weapon, wsType_Missile, wsType_AS_Missile}

-- Shared "this is a support/adapter rack" type descriptor, matching what
-- every stock LAU-88 AGM-65 entry uses (same tuple regardless of Maverick
-- variant or count - it describes the RACK, not the missile). Literal id
-- 4, not WSTYPE_PLACEHOLDER (see history note above).
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
		{ connector_name = "Point01", ShapeName = HARM_SHAPE },
		{ connector_name = "Point02", ShapeName = HARM_SHAPE },
	}
})

----------------------------------------------------------------
-- Rack 2: BRU-55 (mesmo corpo do rack de HARM acima, ja comprovado que
-- renderiza certo) com 2x AGM-65F Maverick - so os 2 pontos de conexao
-- confirmados (Point01/Point02, os mesmos que o JSOW stock usa).
----------------------------------------------------------------
declare_loadout({
	category        = CAT_MISSILES,
	CLSID           = "{BRU55_2xAGM65F}",
	Picture         = "agm65.png",
	displayName     = _("BRU-55 - 2 x AGM-65F Maverick"),
	wsTypeOfWeapon  = wsType_Maverick,
	attribute       = {4, 4, 32, WSTYPE_PLACEHOLDER},
	kind_of_shipping = 1, -- SUBMUNITION_AND_CONTAINER_SEPARATELY
	adapter_type     = ADAPTER_TYPE,
	Count           = 2,
	Weight          = 176.0 + 2 * MAVERICK_UNIT_MASS,
	Cx_pil          = 0.00244140625 + 2 * 0.001953125,
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
	table.insert(pylonOptionTable, { CLSID = "{BRU55_2xAGM88}",      Cx_gain_empty = 0.371, Cx_gain_item = 0.621 })
	table.insert(pylonOptionTable, { CLSID = "{BRU55_2xAGM65F}",     Cx_gain_empty = 0.338, Cx_gain_item = 1.593 })
end

addOptions(outboardLeft)
addOptions(outboardRight)
addOptions(inboardLeft)
addOptions(inboardRight)
