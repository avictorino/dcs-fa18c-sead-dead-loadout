--[[
	SEAD/DEAD Hornet Mod - custom multi-rack weapon declarations
	Reaproveita a arquitetura de rack do JSOW (BRU-55) ja existente no
	jogo (AircraftWeaponPack) pro HARM. O Maverick usa um CLSID real e
	intocado do proprio jogo (ver abaixo) - nao precisa de rack custom.

	CLSID de munição reaproveitado do stock pro HARM:
		AGM-88 on LAU-118  -> {B06DD79A-F21E-4EB9-BD9D-AB3844618C93}

	This file is loaded via loadfile()+call (not dofile()) from
	FA-18C_hornet.lua, which passes its local pylon-option tables in as
	arguments - that's the only reason this file can add the new rack
	options to them, since they're normally out of reach (local to that
	other file's own chunk). Everything else the mod needs lives here.

	SMS/stores page - history:
	1) A REAL stock LAU-88 rack (3x AGM-65E, from agm65_family.lua) DOES
	   show up correctly on the Hornet's stores page - the avionics CAN
	   display multi-item racks, confirmed by testing.
	2) Tried building our OWN custom LAU-88-style rack (various bodies:
	   a real "LAU-88" shape, the BRU-55 body; various fields:
	   kind_of_shipping=1, adapter_type={...,4}, a real per-weapon
	   attribute id borrowed from AGM-65E or AGM-65G's own registered
	   id) for AGM-65F and AGM-65G. Every attempt either didn't show on
	   SMS, or the missiles stopped rendering visually entirely (only
	   the empty rack body appeared). Never found the missing piece.
	3) AGM-65D also has a real, complete, unmodified LAU-88 x3 combo in
	   the stock game (like AGM-65E) - IIR-guided, same sensor family as
	   F/G. Switched to reusing THAT CLSID directly, same as AGM-65E
	   before it: zero custom declare_loadout, guaranteed correct visual
	   AND SMS recognition, since it's 100% untouched Eagle Dynamics data.
	   HARM (Rack 1 below) still has no real multi-item CLSID anywhere in
	   the game to borrow, so it remains a custom rack with the SMS
	   limitation - see README's "known limitation" section.
]]

local outboardLeft, outboardRight, inboardLeft, inboardRight = ...

local HARM_CLSID = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}"

local HARM_UNIT_MASS = 361.7   -- kg, AGM-88 + LAU-118 combo (aprox.)

local wsType_HARM = {wsType_Weapon, wsType_Missile, wsType_AS_Missile}

-- "Support/adapter rack" type descriptor - kept even though it alone
-- didn't fix SMS recognition for the HARM rack, since it's harmless.
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
-- Rack 2 (Maverick): NAO declaramos nada nosso aqui. Reaproveitamos o
-- CLSID REAL, ja pronto e ja usado pelo A-10/F-16 (LAU-88 com 3x
-- AGM-65D, de agm65_family.lua) - IIR, mesma familia de sensor do
-- F/G, mount 100% intocado da ED, garantidamente reconhecido pela SMS.
----------------------------------------------------------------
local REAL_LAU88_3xAGM65D_CLSID = "{DAC53A2F-79CA-42FF-A77A-F5649B601308}"

----------------------------------------------------------------
-- Add both racks as options on all 4 wing stations
----------------------------------------------------------------
local function addOptions(pylonOptionTable)
	table.insert(pylonOptionTable, { CLSID = "{BRU55_2xAGM88}", Cx_gain_empty = 0.371, Cx_gain_item = 0.621 })
	table.insert(pylonOptionTable, { CLSID = REAL_LAU88_3xAGM65D_CLSID })
end

addOptions(outboardLeft)
addOptions(outboardRight)
addOptions(inboardLeft)
addOptions(inboardRight)
