--[[
	SEAD/DEAD Hornet Mod - Rearm/Refuel + Mission Editor presets.

	Loaded via loadfile()+call (not dofile()) from
	UnitPayloads\FA-18C_hornet.lua, which passes its own `unitPayloads`
	table in as an argument - that's the only reason this file can
	append to unitPayloads.payloads, since that table is normally out
	of reach (local to that other file's own chunk).
]]

local unitPayloads = ...

table.insert(unitPayloads.payloads, {
	["name"] = "[SEAD] AGM-88*8, FUEL*1",
	["pylons"] = {
		[1] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 2},
		[2] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 3},
		[3] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 7},
		[4] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 8},
		[5] = {["CLSID"] = "{FPU_8A_FUEL_TANK}", ["num"] = 5},
		[6] = {["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}", ["num"] = 1},
		[7] = {["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}", ["num"] = 9},
	},
	["tasks"] = { [1] = 19 },
})

table.insert(unitPayloads.payloads, {
	["name"] = "[SEAD+DEAD] AGM-88*4, AGM-65E*6, FUEL*1",
	["pylons"] = {
		[1] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 3},
		[2] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 7},
		[3] = {["CLSID"] = "{BRU42A_x3_AGM65E}", ["num"] = 2},
		[4] = {["CLSID"] = "{BRU42A_x3_AGM65E}", ["num"] = 8},
		[5] = {["CLSID"] = "{FPU_8A_FUEL_TANK}", ["num"] = 5},
		[6] = {["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}", ["num"] = 1},
		[7] = {["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}", ["num"] = 9},
	},
	["tasks"] = { [1] = 19 },
})

table.insert(unitPayloads.payloads, {
	["name"] = "[DEAD] AGM-65E*12, FUEL*1",
	["pylons"] = {
		[1] = {["CLSID"] = "{BRU42A_x3_AGM65E}", ["num"] = 2},
		[2] = {["CLSID"] = "{BRU42A_x3_AGM65E}", ["num"] = 3},
		[3] = {["CLSID"] = "{BRU42A_x3_AGM65E}", ["num"] = 7},
		[4] = {["CLSID"] = "{BRU42A_x3_AGM65E}", ["num"] = 8},
		[5] = {["CLSID"] = "{FPU_8A_FUEL_TANK}", ["num"] = 5},
		[6] = {["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}", ["num"] = 1},
		[7] = {["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}", ["num"] = 9},
	},
	["tasks"] = { [1] = 32 },
})
