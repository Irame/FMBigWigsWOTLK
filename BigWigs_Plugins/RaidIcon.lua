-------------------------------------------------------------------------------
-- Module Declaration
--

local plugin = BigWigs:NewPlugin("Raid Icons")
if not plugin then return end

-------------------------------------------------------------------------------
-- Locals
--

local markedUnits = {}
local iconsUsed = {}

local L = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Plugins")
local icons = {
	L["Star"],
	L["Circle"],
	L["Diamond"],
	L["Triangle"],
	L["Moon"],
	L["Square"],
	L["Cross"],
	L["Skull"],
	L["|cffff0000Disable|r"],
}

--------------------------------------------------------------------------------
-- Options
--

plugin.defaultDB = {
	prios = {3, 4, 6, 1, 5, 2, 7, 8}
}

local function get(info)
	local key = info[#info]
	if not plugin.db.profile[key] then return 9
	else return plugin.db.profile[key] end
end
local function set(info, index)
	plugin.db.profile[info[#info]] = index > 8 and nil or index
end

plugin.pluginOptions = {
	type = "group",
	name = L["Icons"],
	get = get,
	set = set,
	args = {
		description = {
			type = "description",
			name = L.raidIconDescription,
			order = 1,
			width = "full",
			fontSize = "medium",
		},
		iconPrios = {
			type = "group",
			name = "Icon Priorities",
			order = 2,
			inline = true,
			args = {}
		}
	},
}

do
	local prios = plugin.pluginOptions.args.iconPrios.args
	for i = 1, 8 do
		prios["prio"..i] = {
			type = "group",
			name = "",
			inline = true,
			order = i,
			args = {
				-- enabled = {
					-- type = "toggle",
					-- name = "",
					-- width = "half",
					-- order = 1,
				-- },
				icon = {
					type = "description",
					arg = i,
					name = function(info) return ("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:32|t ".._G["RAID_TARGET_"..plugin.db.profile.prios[info.arg]]):format(plugin.db.profile.prios[info.arg]) end,
					fontSize = "medium",
					width = "half",
					order = 2,
				},
				moveDown = {
					type = i < 8 and "execute" or "description",
					arg = i,
					name = "",
					image = i < 8 and "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up" or nil,
					width = "half",
					order = 3,
					func = i < 8 and function(info)
						local temp = plugin.db.profile.prios[info.arg]
						plugin.db.profile.prios[info.arg] = plugin.db.profile.prios[info.arg+1]
						plugin.db.profile.prios[info.arg+1] = temp
					end or nil
				},
				moveUp = {
					type = i > 1 and "execute" or "description",
					arg = i,
					name = "",
					image = i > 1 and "Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up" or nil,
					width = "half",
					order = 4,
					func = i > 1 and function(info)
						local temp = plugin.db.profile.prios[info.arg]
						plugin.db.profile.prios[info.arg] = plugin.db.profile.prios[info.arg-1]
						plugin.db.profile.prios[info.arg-1] = temp
					end or nil
				},
			}
		}
	end
end

-------------------------------------------------------------------------------
-- Initialization
--

function plugin:OnPluginEnable()
	self:RegisterMessage("BigWigs_SetRaidIcon")
	self:RegisterMessage("BigWigs_RemoveRaidIcon")
	self:RegisterMessage("BigWigs_OnBossDisable")
end

-------------------------------------------------------------------------------
-- Functions
--

local additionalValidTrackUnits = {"boss1", "boss2", "boss3"}
local function shouldTrackUnit(unit) 
	if plugin:UnitInGroup() then return true end
	for _, u in pairs(additionalValidTrackUnits) do
		if UnitIsUnit(u,unit) then return true end
	end
end

local function getNextUsableIcon(key, unit, offset)
	local pos = 0
	for prio, icon in pairs(plugin.db.profile.prios) do
		pos = pos + 1
		if pos >= offset and not iconsUsed[icon] then
			if shouldTrackUnit(unit) then
				iconsUsed[icon] = unit
				markedUnits[unit] = {key=key, icon=icon}
			end
			return icon
		end
	end
end

local function freeIcon(input)
	local unit, icon
	if type(input) == "number" then 
		icon = input
		unit = iconsUsed[icon] 
	elseif type(input) == "string" then 
		unit = input
		icon = markedUnits[unit].icon
	end
	if icon then iconsUsed[icon] = nil end
	if unit then markedUnits[unit] = nil end
end

local function unmark(input)
	if type(input) == "number" then
		if iconsUsed[input] then
			SetRaidTarget(iconsUsed[input], 0)
		end
	elseif type(input) == "string" then 
		if markedUnits[input] then
			SetRaidTarget(input, 0)
		end
	end
	freeIcon(input)
end

local function unmarkByKey(key)
	for unit, ki in pairs(markedUnits) do
		if ki.key == key then
			unmark(unit)
		end
	end
end

local function unmarkAll()
	for unit, _ in pairs(markedUnits) do
		SetRaidTarget(unit, 0)
	end
	wipe(markedUnits)
	wipe(iconsUsed)
end

local function markUnit(unit, offset)
	if not GetRaidTargetIndex(unit) or markedUnits[unit] then
		freeIcon(unit)
		SetRaidTarget(unit, getNextUsableIcon(unit, offset))
	end
end

-------------------------------------------------------------------------------
-- Event Handlers
--

function plugin:BigWigs_SetRaidIcon(message, key, unit, icon)
	if not BigWigs.db.profile.raidicon then return end
	if not unit then return end
	if type(unit) == "table" then
		for _, u in pairs(unit) do
			markUnit(u, icon or 1)
		end
	else
		markUnit(unit, icon or 1)
	end
end

function plugin:BigWigs_RemoveRaidIcon(message, key, input)
	if not BigWigs.db.profile.raidicon then return end
	if not input then
		unmarkByKey(key)
	else
		unmark(input)
	end
end

function plugin:BigWigs_OnBossDisable()
	unmarkAll()
end
