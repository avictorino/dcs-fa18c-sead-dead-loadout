--[[
	SEAD/DEAD Hornet Mod - custom multi-rack weapon declarations
	Reaproveita a arquitetura de rack do TALD (BRU-42A) e do JSOW (BRU-55)
	ja existentes no jogo (AircraftWeaponPack), so trocando o payload_CLSID
	de cada "Point0X" para AGM-88 (HARM) ou AGM-65E (Maverick).

	CLSIDs de munição reaproveitados do stock (ver FA-18C_hornet.lua original):
		AGM-88 on LAU-118  -> {B06DD79A-F21E-4EB9-BD9D-AB3844618C93}
		AGM-65E on LAU-117 -> {F16A4DE0-116C-4A71-97F0-2CF85B0313EC}

	This file is loaded via loadfile()+call (not dofile()) from
	FA-18C_hornet.lua, which passes its local pylon-option tables in as
	arguments - that's the only reason this file can add the new rack
	options to them, since they're normally out of reach (local to that
	other file's own chunk). Everything else the mod needs lives here.
]]

local outboardLeft, outboardRight, inboardLeft, inboardRight = ...

local HARM_CLSID     = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}"
local MAVERICK_CLSID = "{F16A4DE0-116C-4A71-97F0-2CF85B0313EC}"

local HARM_UNIT_MASS     = 361.7   -- kg, AGM-88 + LAU-118 combo (aprox.)
local MAVERICK_UNIT_MASS = 307.0   -- kg, AGM-65E + LAU-117 combo (aprox.)

local wsType_HARM     = {wsType_Weapon, wsType_Missile, wsType_AS_Missile, WSTYPE_PLACEHOLDER}
local wsType_Maverick = {wsType_Weapon, wsType_Missile, wsType_AS_Missile, WSTYPE_PLACEHOLDER}

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
-- Rack 2: BRU-42A (corpo do TALD triplo) com 3x AGM-65E Maverick
----------------------------------------------------------------
declare_loadout({
	category        = CAT_MISSILES,
	CLSID           = "{BRU42A_x3_AGM65E}",
	Picture         = "agm65.png",
	displayName     = _("BRU-42A - 3 x AGM-65E Maverick"),
	wsTypeOfWeapon  = wsType_Maverick,
	attribute       = {4, 4, 32, WSTYPE_PLACEHOLDER},
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
	table.insert(pylonOptionTable, { CLSID = "{BRU42A_x3_AGM65E}", Cx_gain_empty = 0.338, Cx_gain_item = 1.593 })
end

addOptions(outboardLeft)
addOptions(outboardRight)
addOptions(inboardLeft)
addOptions(inboardRight)
