-------------------------------------------------------------------------------
-- Prototype
--

local debug = nil -- Set to true to get (very spammy) debug messages.
local dbgStr = "[DBG:%s] %s"
local function dbg(self, msg) print(dbgStr:format(self.displayName, msg)) end

local AL = LibStub("AceLocale-3.0")
local core = BigWigs
local C = core.C
local pName = UnitName("player")
local UpdateZoneData, UpdateRoleData, UpdateInstanceDifficulty, UpdateDispelStatus, UpdateInterruptStatus
local updateData = function()
	UpdateZoneData()
	UpdateRoleData()
	UpdateInstanceDifficulty()
	UpdateDispelStatus()
	UpdateInterruptStatus()
end

-------------------------------------------------------------------------------
-- Metatables
--
local metaMap = {__index = function(t, k) t[k] = {} return t[k] end}
local combatLogMap = setmetatable({}, metaMap)
local yellMap = setmetatable({}, metaMap)
local emoteMap = setmetatable({}, metaMap)
local deathMap = setmetatable({}, metaMap)
local icons = setmetatable({}, {__index =
	function(self, key)
		if not key then return end
		local value = nil
		if type(key) == "number" then value = select(3, GetSpellInfo(key))
		else value = "Interface\\Icons\\" .. key end
		self[key] = value
		return value
	end
})
local spells = setmetatable({}, {__index =
	function(self, key)
		local value = GetSpellInfo(key)
		self[key] = value
		return value
	end
})

-------------------------------------------------------------------------------
-- Core module functionality
--
local boss = {}
core.bossCore:SetDefaultModulePrototype(boss)
function boss:IsBossModule() return true end
function boss:OnInitialize() core:RegisterBossModule(self) end
function boss:OnEnable()
	if debug then dbg(self, "OnEnable()") end
	if type(self.OnBossEnable) == "function" then self:OnBossEnable() end
	self:SendMessage("BigWigs_OnBossEnable", self)
	updateData()
end
function boss:OnDisable()
	if debug then dbg(self, "OnDisable()") end
	if type(self.OnBossDisable) == "function" then self:OnBossDisable() end

	wipe(combatLogMap[self])
	wipe(yellMap[self])
	wipe(emoteMap[self])
	wipe(deathMap[self])

	self:SendMessage("BigWigs_OnBossDisable", self)
end
function boss:GetOption(spellId)
	return self.db.profile[(GetSpellInfo(spellId))]
end
function boss:Reboot()
	if debug then dbg(self, ":Reboot()") end
	self:Disable()
	self:Enable()
end

-------------------------------------------------------------------------------
-- Localization
--
function boss:NewLocale(locale, default) return AL:NewLocale(self.name, locale, default) end
function boss:GetLocale() return AL:GetLocale(self.name) end

-------------------------------------------------------------------------------
-- Enable triggers
--
function boss:RegisterEnableMob(...) core:RegisterEnableMob(self, ...) end
function boss:RegisterEnableYell(...) core:RegisterEnableYell(self, ...) end

-------------------------------------------------------------------------------
-- Locals
--

local L = AL:GetLocale("Big Wigs: Common")
local UnitExists = UnitExists
local UnitAffectingCombat = UnitAffectingCombat
local UnitName = UnitName
local GetSpellInfo = GetSpellInfo
local fmt = string.format

-------------------------------------------------------------------------------
-- Combat log related code
--

do
	local modMissingFunction = "Module %q got the event %q (%d), but it doesn't know how to handle it."
	local missingArgument = "Missing required argument when adding a listener to %q."
	local missingFunction = "%q tried to register a listener to method %q, but it doesn't exist in the module."

	function boss:CHAT_MSG_MONSTER_YELL(_, msg, ...)
		if yellMap[self][msg] then
			self[yellMap[self][msg]](self, msg, ...)
		else
			for yell, func in pairs(yellMap[self]) do
				if msg:find(yell) then
					self[func](self, msg, ...)
				end
			end
		end
	end
	function boss:CHAT_MSG_RAID_BOSS_EMOTE(_, msg, ...)
		if emoteMap[self][msg] then
			self[emoteMap[self][msg]](self, msg, ...)
		else
			for yell, func in pairs(emoteMap[self]) do
				if msg:find(yell) then
					self[func](self, msg, ...)
				end
			end
		end
	end

	function boss:COMBAT_LOG_EVENT_UNFILTERED(_, _, event, sGUID, source, sFlags, dGUID, player, dFlags, spellId, spellName, _, secSpellId, buffStack)
		if event == "UNIT_DIED" then
			local numericId = tonumber(dGUID:sub(-12, -7), 16)
			local d = deathMap[self][numericId]
			if not d then return end
			if type(d) == "function" then d(numericId, dGUID, player, dFlags)
			else self[d](self, numericId, dGUID, player, dFlags) end
		else
			local m = combatLogMap[self][event]
			if m and m[spellId] then
				local func = m[spellId]
				if type(func) == "function" then
					func(player, spellId, source, secSpellId, spellName, buffStack, event, sFlags, dFlags, dGUID)
				else
					self[func](self, player, spellId, source, secSpellId, spellName, buffStack, event, sFlags, dFlags, dGUID)
				end
			end
		end
	end

	function boss:Emote(func, ...)
		if not func then error(missingArgument:format(self.moduleName)) end
		if not self[func] then error(missingFunction:format(self.moduleName, func)) end
		for i = 1, select("#", ...) do
			emoteMap[self][(select(i, ...))] = func
		end
		self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	end
	function boss:Yell(func, ...)
		if not func then error(missingArgument:format(self.moduleName)) end
		if not self[func] then error(missingFunction:format(self.moduleName, func)) end
		for i = 1, select("#", ...) do
			yellMap[self][(select(i, ...))] = func
		end
		self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	end
	function boss:Log(event, func, ...)
		if not event or not func then error(missingArgument:format(self.moduleName)) end
		if type(func) ~= "function" and not self[func] then error(missingFunction:format(self.moduleName, func)) end
		if not combatLogMap[self][event] then combatLogMap[self][event] = {} end
		for i = 1, select("#", ...) do
			combatLogMap[self][event][(select(i, ...))] = func
		end
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
	function boss:Death(func, ...)
		if not func then error(missingArgument:format(self.moduleName)) end
		if type(func) ~= "function" and not self[func] then error(missingFunction:format(self.moduleName, func)) end
		for i = 1, select("#", ...) do
			deathMap[self][(select(i, ...))] = func
		end
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

-------------------------------------------------------------------------------
-- Engage / wipe checking + unit scanning
--

boss.GetMobIdByGUID = setmetatable({}, {__index = function(t, k)
	local id = (k and tonumber(k:sub(9, 12), 16)) or 0
	rawset(t, k, id)
	return id	
end})

do
	local t = {"target", "targettarget", "focus", "focustarget", "mouseover", "mouseovertarget"}
	for i = 1, 4 do t[#t+1] = fmt("boss%d", i) end
	for i = 1, 4 do t[#t+1] = fmt("party%dtarget", i) end
	for i = 1, 40 do t[#t+1] = fmt("raid%dtarget", i) end
	local function findTargetByGUID(id)
		local idType = type(id)
		for i, unit in next, t do
			if UnitExists(unit) and not UnitIsPlayer(unit) then
				local unitId = UnitGUID(unit)
				if idType == "number" then unitId = tonumber(unitId:sub(-12, -7), 16) end
				if unitId == id then return unit end
			end
		end
	end
	function boss:GetUnitIdByGUID(mob) return findTargetByGUID(mob) end

	local scan = nil
	if debug then
		function scan(self)
			local mobs = {}
			local found = nil
			for mobId, entry in pairs(core:GetEnableMobs()) do
				if type(entry) == "table" then
					for i, module in next, entry do
						if module == self.moduleName then
							local unit = findTargetByGUID(mobId)
							if unit and UnitAffectingCombat(unit) then
								mobs[#mobs + 1] = tostring(mobId) .. ":" .. unit
								found = true
							else
								mobs[#mobs + 1] = tostring(mobId) .. ":no target"
								mobs[mobId] = "no target"
							end
						end
					end
				elseif entry == self.moduleName then
					local unit = findTargetByGUID(mobId)
					if unit and UnitAffectingCombat(unit) then
						mobs[#mobs + 1] = tostring(mobId) .. ":" .. unit
						found = true
					else
						mobs[#mobs + 1] = tostring(mobId) .. ":no target"
					end
				end
			end
			dbg(self, "scan data: " .. table.concat(mobs, ","))
			mobs = nil
			return found
		end
	else
		function scan(self)
			for mobId, entry in pairs(core:GetEnableMobs()) do
				if type(entry) == "table" then
					for i, module in next, entry do
						if module == self.moduleName then
							local unit = findTargetByGUID(mobId)
							if unit and UnitAffectingCombat(unit) then return unit end
							break
						end
					end
				elseif entry == self.moduleName then
					local unit = findTargetByGUID(mobId)
					if unit and UnitAffectingCombat(unit) then return unit end
				end
			end
		end
	end

	function boss:CheckForEngage()
		if debug then dbg(self, ":CheckForEngage initiated.") end
		local go = scan(self)
		if go then
			if debug then dbg(self, "Engage scan found active boss entities, transmitting engage sync.") end
			self:Sync("BossEngaged", self.moduleName)
		else
			if debug then dbg(self, "Engage scan did NOT find any active boss entities. Re-scheduling another engage check in 0.5 seconds.") end
			self:ScheduleTimer("CheckForEngage", .5)
		end
	end

	-- XXX What if we die and then get battleressed?
	-- XXX First of all, the CheckForWipe every 2 seconds would continue scanning.
	-- XXX Secondly, if the boss module registers for PLAYER_REGEN_DISABLED, it would
	-- XXX trigger again, and CheckForEngage (possibly) invoked, which results in
	-- XXX a new BossEngaged sync -> :Engage -> :OnEngage on the module.
	-- XXX Possibly a concern?
	function boss:CheckForWipe()
		if debug then dbg(self, ":CheckForWipe initiated.") end
		local go = scan(self)
		if not go then
			if debug then dbg(self, "Wipe scan found no active boss entities, rebooting module.") end
			if self.OnWipe then self:OnWipe() end
			self:Reboot()
		else
			if debug then dbg(self, "Wipe scan found active boss entities (" .. tostring(go) .. "). Re-scheduling another wipe check in 2 seconds.") end
			self:ScheduleTimer("CheckForWipe", 2)
		end
	end
	
	function boss:Engage()
		if debug then dbg(self, ":Engage") end
		CombatLogClearEntries()
		updateData()
		if self.OnEngage then
			self:OnEngage(self:GetDifficulty())
		end
	end

	function boss:Win()
		if debug then dbg(self, ":Win") end
		if self.OnWin then self:OnWin() end
		self:Sync("Death", self.moduleName)
		wipe(icons) -- Wipe icon cache
		wipe(spells)
	end
end


-------------------------------------------------------------------------------
-- Instance Difficulty stuff
--

do
	local curDiff
	local difficultyMap
	--XXX BIG ASS HACK BECAUSE BLIZZ SCREWED UP
	--XXX GetRaidDifficulty() doesn't update when changing difficulty whilst inside the zone
	local function getInstanceDifficulty()
		local _, instanceType, diff, _, _, heroic, dynamic = GetInstanceInfo()
		if instanceType == "raid" and dynamic and heroic == 1 and diff <= 2 then
			diff = diff + 2
		end
		return type(diff) == "number" and diff or 1
	end
	
	function UpdateInstanceDifficulty()
		wipe(difficultyMap)
		curDiff = getInstanceDifficulty()
	end
	
	local diffStringTable = {
		["10nh"] = {[1] = true},
		["25nh"] = {[2] = true},
		["10hc"] = {[3] = true},
		["25hc"] = {[4] = true},
		["10"] = {[1] = true, [3] = true},
		["25"] = {[2] = true, [4] = true},
		["nh"] = {[1] = true, [2] = true},
		["hc"] = {[3] = true, [4] = true}
	}
	local diffTable_mt = {
		__index = function(self, key)
			local value = false
			if not curDiff then UpdateInstanceDifficulty() end
			if type(key) == "string" then
				value = diffStringTable[key][curDiff]
			else
				value = curDiff == key
			end
			rawset(self, key, value)
			return value
		end
	}
	difficultyMap = setmetatable({}, diffTable_mt)

	function boss:IsDifficulty(diff)
		return difficultyMap[diff]
	end
	
	function boss:GetDifficulty()
		return curDiff
	end
end

-------------------------------------------------------------------------------
-- Boss module APIs for messages, bars, icons, etc.
--
local checkFlag
do
local silencedOptions = {}
	local bwOptionSilencer = CreateFrame("Frame")
	bwOptionSilencer:Hide()
	LibStub("AceEvent-3.0"):Embed(bwOptionSilencer)
	bwOptionSilencer:RegisterMessage("BigWigs_SilenceOption", function(event, key, time)
		if key ~= nil then -- custom bars have a nil key
			silencedOptions[key] = time
			bwOptionSilencer:Show()
		end
	end)
	local total = 0
	bwOptionSilencer:SetScript("OnUpdate", function(self, elapsed)
		total = total + elapsed
		if total >= 0.5 then
			for k, t in pairs(silencedOptions) do
				local newT = t - total
				if newT < 0 then
					silencedOptions[k] = nil
				else
					silencedOptions[k] = newT
				end
			end
			if not next(silencedOptions) then
				self:Hide()
			end
			total = 0
		end
	end)
	
	function checkFlag(self, key, flag)
		if not key then return false end
		if silencedOptions[key] then
			return
		end
		if type(key) == "number" then key = GetSpellInfo(key) end
		if type(self.db.profile[key]) ~= "number" then
			if debug then
				dbg(self, ("Tried to access %q, but in the database it's a %s."):format(key, type(self.db.profile[key])))
			else
				self.db.profile[key] = self.toggleDefaults[key]
			end
		end
		return bit.band(self.db.profile[key], flag) == flag
	end
end

-- PROXIMITY
function boss:OpenProximity(range, key, player, isReverse)
	if key and checkFlag(self, key, C.PROXIMITY) then
		if type(key) == "number" then
			self:SendMessage("BigWigs_ShowProximity", self, range, key, player, isReverse, spells[key], icons[key])
		else
			self:SendMessage("BigWigs_ShowProximity", self, range, key, player, isReverse)
		end
	elseif not key and checkFlag(self, "proximity", C.PROXIMITY) then
		self:SendMessage("BigWigs_ShowProximity", self, range, "proximity", player, isReverse)
	end
end

function boss:CloseProximity(key)
	if (key and checkFlag(self, key, C.PROXIMITY)) or (not key and checkFlag(self, "proximity", C.PROXIMITY)) then
		self:SendMessage("BigWigs_HideProximity", self)
	end
end

-- SOUND AND VOICE
local function playVoiceOrSound(self, key, sound, onMe, nearMe, custom)
	if checkFlag(self, key, C.VOICE) then
		self:SendMessage("BigWigs_Voice", self, key, sound, onMe, nearMe, custom)
	elseif sound then
		self:SendMessage("BigWigs_Sound", sound)
	end
end

function boss:PlayVoiceOrSound(key, voice, sound)
	local onMe = voice:upper() == "ONME"
	local nearMe = voice:upper() == "NEARME"
	playVoiceOrSound(self, key, sound, onMe, nearMe, voice)
end

-- MESSAGES
function boss:CancelDelayedMessage(text)
	if self.scheduledMessages and self.scheduledMessages[text] then
		self:CancelTimer(self.scheduledMessages[text], true)
		self.scheduledMessages[text] = nil
	end
end

function boss:DelayedMessage(key, delay, color, text, icon, sound)
	if checkFlag(self, key, C.MESSAGE) then
		if type(delay) ~= "number" then error(string.format("Module %s tried to schedule a delayed message with delay as type %q, but it must be a number.", module.name, type(delay))) end
		self:CancelDelayedMessage(text or key)
		if not self.scheduledMessages then self.scheduledMessages = {} end
		local id = self:ScheduleTimer("Message", delay, key, color, sound, text, icon or false)
		self.scheduledMessages[text or key] = id
		return id
	end
end

-- old order: key, text, color, icon, sound
function boss:Message(key, color, sound, text, icon)
	if not checkFlag(self, key, C.MESSAGE) then return end
	
	local textType = type(text)
	local temp = (icon == false and 0) or (icon ~= false and icon) or (textType == "number" and text) or key
	if temp == key and type(key) == "string" then
		BigWigs:Print(("Message '%s' doesn't have an icon set."):format(textType == "string" and text or spells[text or key] or key)) -- XXX temp
	end
	
	self:SendMessage("BigWigs_Message", self, key, textType == "string" and text or spells[text or key], color, icon ~= false and icons[icon or textType == "number" and text or key])
	self:SendMessage("BigWigs_Broadcast", text)
	
	playVoiceOrSound(self, key, sound)
end

-- Outputs a local message only, no raid warning.
-- old order: key, text, color, icon, sound
function boss:LocalMessage(key, color, sound, text, icon)
	if not checkFlag(self, key, C.MESSAGE) then return end
	
	local textType = type(text)
	local temp = (icon == false and 0) or (icon ~= false and icon) or (textType == "number" and text) or key
	if temp == key and type(key) == "string" then
		BigWigs:Print(("Message '%s' doesn't have an icon set."):format(textType == "string" and text or spells[text or key])) -- XXX temp
	end
	
	self:SendMessage("BigWigs_Message", self, key, text, color, icon)
	
	playVoiceOrSound(self, key, sound)
end

function boss:RangeMessage(key, color, sound, text, icon)
	if not checkFlag(self, key, C.MESSAGE) then return end
	local textType = type(text)
	self:SendMessage("BigWigs_Message", self, key, format(L.near, textType == "string" and text or spells[text or key]), color == nil and "Personal" or color, icon ~= false and icons[icon or textType == "number" and text or key])
	
	playVoiceOrSound(self, key, sound, nil, true)
end

do
	local hexColors = {}
	for k, v in pairs(RAID_CLASS_COLORS) do
		hexColors[k] = "|cff" .. string.format("%02x%02x%02x", v.r * 255, v.g * 255, v.b * 255)
	end
	local coloredNames = setmetatable({}, {__index =
		function(self, key)
			if type(key) == "nil" then return nil end
			local class = select(2, UnitClass(key))
			if class then
				self[key] = hexColors[class]  .. key .. "|r"
			else
				return key
			end
			return self[key]
		end
	})

	local mt = {
		__newindex = function(self, key, value)
			rawset(self, key, coloredNames[value])
		end
	}
	function boss:NewTargetList()
		return setmetatable({}, mt)
	end

	function boss:StackMessage(key, player, stack, color, sound, text, icon)
		if checkFlag(self, key, C.MESSAGE) then
			local textType = type(text)
			local onMe = player == pName
			if onMe then
				self:SendMessage("BigWigs_Message", self, key, format(L.stackyou, stack or 1, textType == "string" and text or spells[text or key]), "Personal", icon ~= false and icons[icon or textType == "number" and text or key])
			else
				self:SendMessage("BigWigs_Message", self, key, format(L.stack, stack or 1, textType == "string" and text or spells[text or key], coloredNames[player]), color, icon ~= false and icons[icon or textType == "number" and text or key])
			end
			playVoiceOrSound(self, key, sound, onMe)
		end
	end

	-- old Order key, spellName, player, color, icon, sound
	function boss:TargetMessage(key, player, color, sound, text, icon)
		local textType = type(text)
		local msg = textType == "string" and text or spells[text or key]
		local texture = icon ~= false and icons[icon or textType == "number" and text or key]
	
		if not checkFlag(self, key, C.MESSAGE) then return end
		if type(player) == "table" then
			local list = table.concat(player, ", ")
			local onMe = string.find(list, pName, nil, true)
			if onMe and #player == 1 then
				self:SendMessage("BigWigs_Message", self, key, fmt(L["you"], msg), "Personal", texture)
			else
				self:SendMessage("BigWigs_Message", self, key, fmt(L["other"], msg, list), color, texture)
			end
			self:SendMessage("BigWigs_Broadcast", fmt(L["other"], msg, list))
			playVoiceOrSound(self, key, sound, onMe)
			wipe(player)
		else
			if UnitIsUnit(player, "player") then
				self:SendMessage("BigWigs_Message", self, key, fmt(L["you"], msg), color, texture)
				self:SendMessage("BigWigs_Broadcast", fmt(L["other"], msg, coloredNames[player]))
			
				playVoiceOrSound(self, key, sound, true)
			else
				-- Change color and remove sound when warning about effects on other players
				if color == "Personal" then color = "Important" end

				fmtMsg = fmt(L["other"], msg, coloredNames[player])
				self:SendMessage("BigWigs_Message", self, key, fmtMsg, color, texture)
				self:SendMessage("BigWigs_Broadcast", fmtMsg)
			
				playVoiceOrSound(self, key, sound)
			end
		end
	end
end

function boss:FlashShake(key, r, g, b)
	if not checkFlag(self, key, C.FLASHSHAKE) then return end
	self:SendMessage("BigWigs_FlashShake", self, key)
end

function boss:Say(key, msg)
	if not checkFlag(self, key, C.SAY) then return end
	SendChatMessage(msg, "SAY")
end

function boss:Bar(key, text, length, icon, expTime, barColor, barEmphasized, barText, barBackground, ...)
	if checkFlag(self, key, C.BAR) then
		self:SendMessage("BigWigs_StartBar", self, key, text, length, icons[icon], expTime, ...)
	end
end

function boss:HealthBar(key, Id, powerType, icon, text, minValue, maxValue, Value, func, ...)
	if checkFlag(self, key, C.HEALTHBAR) then
		self:SendMessage("BigWigs_AddGeneralBar", self, key, Id, powerType, icons[icon], text, minValue, maxValue, Value, func, ...)
	end
end

function boss:Sync(...) core:Transmit(...) end

function boss:HealthBarStop(key, Id, powerType) self:SendMessage("BigWigs_RemoveBar", self, Id, powerType) end

do
	local sentWhispers = {}
	local function filter(self, event, msg) if sentWhispers[msg] or msg:find("^<BW>") or msg:find("^<DBM>") then return true end end
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filter)

	function boss:Whisper(key, player, spellName, noName)
		self:SendMessage("BigWigs_Whisper", self, key, player, msg, spellName, noName)
		if not checkFlag(self, key, C.WHISPER) then return end
		local msg = noName and spellName or fmt(L["you"], spellName)
		sentWhispers[msg] = true
		if UnitIsUnit(player, "player") or not UnitIsPlayer(player) or not core.db.profile.whisper then return end
		if UnitInRaid("player") and not IsRaidLeader() and not IsRaidOfficer() then return end
		SendChatMessage("<BW> " .. msg, "WHISPER", nil, player)
	end
end

function boss:PrimaryIcon(key, player)
	if key and not checkFlag(self, key, C.ICON) then return end
	if not player then
		self:SendMessage("BigWigs_RemoveRaidIcon", 1)
	else
		self:SendMessage("BigWigs_SetRaidIcon", player, 1)
	end
end

function boss:SecondaryIcon(key, player)
	if key and not checkFlag(self, key, C.ICON) then return end
	if not player then
		self:SendMessage("BigWigs_RemoveRaidIcon", 2)
	else
		self:SendMessage("BigWigs_SetRaidIcon", player, 2)
	end
end

function boss:SetIcon(key, unit, icon)
	if key and not checkFlag(self, key, C.ICON) then return end
	self:SendMessage("BigWigs_SetRaidIcon", key, player, icon)
end

function boss:RemoveIcon(key, input)
	if key and not checkFlag(self, key, C.ICON) then return end
	self:SendMessage("BigWigs_RemoveRaidIcon", key, input)
end

function boss:AddSyncListener(sync)
	core:AddSyncListener(self, sync)
end

function boss:Berserk(seconds, noEngageMessage, customBoss)
	local boss = customBoss or self.displayName
	if not noEngageMessage then
		-- Engage warning with minutes to enrage
		self:Message("berserk", "Attention", nil, fmt(L["berserk_start"], boss, seconds / 60), false)
	end

	-- Half-way to enrage warning.
	local half = seconds / 2
	local m = half % 60
	local halfMin = (half - m) / 60
	self:DelayedMessage("berserk", half + m, "Positive", fmt(L["berserk_min"], halfMin))

	self:DelayedMessage("berserk", seconds - 60, "Positive", L["berserk_min"]:format(1))
	self:DelayedMessage("berserk", seconds - 30, "Urgent", L["berserk_sec"]:format(30))
	self:DelayedMessage("berserk", seconds - 10, "Urgent", L["berserk_sec"]:format(10))
	self:DelayedMessage("berserk", seconds - 5, "Important", L["berserk_sec"]:format(5))
	self:DelayedMessage("berserk", seconds, "Important", L["berserk_end"]:format(boss), nil, "Alarm")

	-- There are many Berserks, but we use 26662 because Brutallus uses this one.
	-- Brutallus is da bomb.
	local berserk = GetSpellInfo(26662)
	self:Bar("berserk", berserk, seconds, 26662)
end

-------------------------------------------------------------------------------
-- Role checking
--
do
	local myRole, myDamagerRole
	local classRoleMap = {
		["WARRIOR"] = {{"DAMAGER", "MELEE"}, {"DAMAGER", "MELEE"}, {"TANK"}},
		["PALADIN"] = {{"HEALER"}, {"TANK"}, {"DAMAGER", "MELEE"}},
		["HUNTER"] = {{"DAMAGER", "RANGED"}, {"DAMAGER", "RANGED"}, {"DAMAGER", "RANGED"}},
		["ROGUE"] = {{"DAMAGER", "MELEE"}, {"DAMAGER", "MELEE"}, {"DAMAGER", "MELEE"}},
		["PRIEST"] = {{"HEALER"}, {"HEALER"}, {"DAMAGER", "RANGED"}},
		["DEATHKNIGHT"] = {{"DAMAGER", "MELEE"}, {--[[not sure]]}, {"DAMAGER", "MELEE"}},
		["SHAMAN"] = {{"DAMAGER", "RANGED"}, {"DAMAGER", "MELEE"}, {"HEALER"}},
		["MAGE"] = {{"DAMAGER", "RANGED"}, {"DAMAGER", "RANGED"}, {"DAMAGER", "RANGED"}},
		["WARLOCK"] = {{"DAMAGER", "RANGED"}, {"DAMAGER", "RANGED"}, {"DAMAGER", "RANGED"}},
		["DRUID"] = {{"DAMAGER", "RANGED"}, {--[[not sure]]}, {"HEALER"}},
	}

	local function GetPrimaryTalentTree()
		local numTabs = GetNumTalentTabs()
		local primarySpec = {points = 0, index = 0}
		for i = 1, MAX_TALENT_TABS do
			if ( i <= numTabs ) then
				_,_,pointsSpent = GetTalentTabInfo(i)
				if pointsSpent > primarySpec.points then
					primarySpec.index = i
					primarySpec.points = pointsSpent
				end
			end
		end
		return primarySpec.index
	end

	function UpdateRoleData()
		local _, class = UnitClass("player")
		local talentTree = GetPrimaryTalentTree()
		if class == "DEATHKNIGHT" and talentTree == 2 then
			if select(5, GetTalentInfo(2,13)) > 0 then		-- Protector of the Pack skilled
				myRole = "TANK"
				myDamagerRole = nil
			else
				myRole = "DAMAGER"
				myDamagerRole = "MELEE"
			end
		elseif class == "DRUID" and talentTree == 2 then
			if select(5, GetTalentInfo(2,22)) > 0 then		-- Frigid Dreadplate skilled
				myRole = "TANK"
				myDamagerRole = nil
			else
				myRole = "DAMAGER"
				myDamagerRole = "MELEE"
			end
		else
			local classRoleInfo = classRoleMap[class][talentTree]
			myRole = classRoleInfo[1]
			myDamagerRole = classRoleInfo[2]
		end
	end

	function boss:Melee()
		return myRole == "TANK" or myDamagerRole == "MELEE"
	end

	function boss:Ranged()
		return myRole == "HEALER" or myDamagerRole == "RANGED"
	end

	function boss:Tank()
		return myRole == "TANK"
	end

	function boss:Healer()
		return myRole == "HEALER"
	end

	function boss:Damager()
		return myDamagerRole
	end
end

-------------------------------------------------------------------------------
-- Despell stuff
--
do
	local offDispel, defDispel = "", ""
	function UpdateDispelStatus()
		offDispel, defDispel = "", ""
		if IsSpellKnown(19801) then
			-- Tranq (Hunter)
			offDispel = offDispel .. "enrage,"
		end
		if IsSpellKnown(19801) or IsSpellKnown(32375) or IsSpellKnown(988) or IsSpellKnown(370) or IsSpellKnown(30449) then
			-- Tranq (Hunter), Mass Dispel (Priest), Dispel Magic (Priest), Purge (Shaman), Spellsteal (Mage)
			offDispel = offDispel .. "magic,"
		end
		if IsSpellKnown(988) or IsSpellKnown(4987) then
			-- Dispel Magic (Priest), Cleanse (Paladin)
			defDispel = defDispel .. "magic,"
		end
		if IsSpellKnown(528) or IsSpellKnown(552) or IsSpellKnown(4987) or IsSpellKnown(526) or IsSpellKnown(51886) then
			-- Cure Disease (Priest), Abolish Disease (Priest), Cleanse (Paladin), Cure Toxins (Schaman), Cleanse Spirit (Restro Schaman)
			defDispel = defDispel .. "disease,"
		end
		if IsSpellKnown(8946) or IsSpellKnown(2893) or IsSpellKnown(4987) or IsSpellKnown(526) or IsSpellKnown(51886) then
			-- Cure Poison (Druid) Abolish Poison (Druid), Cleanse (Paladin), Cure Toxins (Schaman), Cleanse Spirit (Restro Schaman)
			defDispel = defDispel .. "poison,"
		end
		if IsSpellKnown(2782) or IsSpellKnown(475) or IsSpellKnown(51886) then
			-- Remove Curse (Druid), Remove Curse (Mage), Cleanse Spirit (Restro Schaman)
			defDispel = defDispel .. "curse,"
		end
	end
	function boss:Dispeller(dispelType, isOffensive, key)
		if key and not checkFlag(self, key, C.DISPEL) then return end
		if isOffensive then
			if find(offDispel, dispelType, nil, true) then
				return true
			end
		else
			if find(defDispel, dispelType, nil, true) then
				return true
			end
		end
		return false
	end
end

-------------------------------------------------------------------------------
-- Interrupt stuff
--
do
	local canInterrupt = false
	local spellList = {
		57994, -- Wind Shear (Shaman)
		47528, -- Mind Freeze (Death Knight)
		15487, -- Silence (Priest)
		2139, -- Counterspell (Mage)
		1766, -- Kick (Rogue)
		6552, -- Pummel (Warrior)
	}
	function UpdateInterruptStatus()
		canInterrupt = false
		for i = 1, #spellList do
			local spell = spellList[i]
			if IsSpellKnown(spell) then
				canInterrupt = spell -- XXX check for cooldown also?
			end
		end
	end
	function boss:Interrupter(guid, checkCooldown)
		local result = canInterrupt
		if canInterrupt then
			if checkCooldown then
				result = GetSpellCooldown(canInterrupt) ~= 0 and result
			end
			if guid then
				result = (UnitGUID("target") == guid or UnitGUID("focus") == guid) and result
			end
		end
		return result		
	end
end


------------------------------
--- Map stuff

do
	local zoneScale, zoneScalingData, zoneOverrides
	local function CoordsToPosition(x, y)
		if not x or not y or (x == 0 and y == 0) then return x, y end
		if not zoneScale then
			return x * 1500, (1 - y) * 1000
		end
		return x * zoneScale[1], (1 - y) * zoneScale[2]
	end

	local function GetUnitPosition(unit, forceZone)
		if not unit then return nil, nil end
		if forceZone then SetMapToCurrentZone()	end
		local x, y = GetPlayerMapPosition(unit)
		return CoordsToPosition(x, y)
	end

	function boss:Range(player, otherPlayer)
		if not zoneScale then return end
		if not otherPlayer then otherPlayer = "player" end
		local ty, tx = GetUnitPosition(player)
		if not ty or not tx then return end
		local py, px = GetUnitPosition(otherPlayer)
		if not py or not px then return end
		local dx = tx - px
		local dy = ty - py
		local distance = (dx * dx + dy * dy) ^ 0.5
		return distance
	end

	function UpdateZoneData()
		if WorldMapFrame:IsVisible() then return end
		
		SetMapToCurrentZone()
		
		local cx, cy = GetPlayerMapPosition("player")
		if cx == 0 and cy == 0 then 
			zoneScale = nil
			return 
		end
		
		local area, level, key, currentZone
		area = GetMapInfo()
		level = GetCurrentMapDungeonLevel()
		
		-- Thanks Cyprias!
		if area == "Ulduar" or area == "CoTStratholme" then
			level = level - 1
		end
		key = level > 0 and (area .. level) or area
		currentZone = zoneOverrides[GetSubZoneText()] or key
		zoneScale = zoneScalingData[currentZone]
	end


	zoneOverrides = {
		[L["The Frozen Throne"]] = "IcecrownCitadel7"
	}

	zoneScalingData = setmetatable({
		Arathi = { 3599.99987792969, 2399.99992370605, 1},
		Ogrimmar = { 1402.6044921875, 935.416625976563, 2},
		Undercity = { 959.375030517578, 640.104125976563, 4},
		Barrens = { 10133.3330078125, 6756.24987792969, 5},
		Darnassis = { 1058.33325195313, 705.7294921875, 6},
		AzuremystIsle = { 4070.8330078125, 2714.5830078125, 7},
		UngoroCrater = { 3699.99981689453, 2466.66650390625, 8},
		BurningSteppes = { 2929.16659545898, 1952.08349609375, 9},
		Wetlands = { 4135.41668701172, 2756.25, 10},
		Winterspring = { 7099.99984741211, 4733.33325195313, 11},
		Dustwallow = { 5250.00006103516, 3499.99975585938, 12},
		Darkshore = { 6549.99975585938, 4366.66650390625, 13},
		LochModan = { 2758.33312988281, 1839.5830078125, 14},
		BladesEdgeMountains = { 5424.99975585938, 3616.66638183594, 15},
		Durotar = { 5287.49963378906, 3524.99987792969, 16},
		Silithus = { 3483.333984375, 2322.916015625, 17},
		ShattrathCity = { 1306.25, 870.833374023438, 18},
		Ashenvale = { 5766.66638183594, 3843.74987792969, 19},
		Azeroth = { 40741.181640625, 27149.6875, 20},
		Nagrand = { 5525.0, 3683.33316802979, 21},
		TerokkarForest = { 5399.99975585938, 3600.00006103516, 22},
		EversongWoods = { 4925.0, 3283.3330078125, 23},
		SilvermoonCity = { 1211.45849609375, 806.7705078125, 24},
		Tanaris = { 6899.99952697754, 4600.0, 25},
		Stormwind = { 1737.499958992, 1158.3330078125, 26},
		SwampOfSorrows = { 2293.75, 1529.1669921875, 27},
		EasternPlaguelands = { 4031.25, 2687.49987792969, 28},
		BlastedLands = { 3349.99987792969, 2233.333984375, 29},
		Elwynn = { 3470.83325195313, 2314.5830078125, 30},
		DeadwindPass = { 2499.99993896484, 1666.6669921875, 31},
		DunMorogh = { 4924.99975585938, 3283.33325195313, 32},
		TheExodar = { 1056.7705078125, 704.687744140625, 33},
		Felwood = { 5749.99963378906, 3833.33325195313, 34},
		Silverpine = { 4199.99975585938, 2799.99987792969, 35},
		ThunderBluff = { 1043.74993896484, 695.833312988281, 36},
		Hinterlands = { 3850.0, 2566.66662597656, 37},
		StonetalonMountains = { 4883.33312988281, 3256.24981689453, 38},
		Mulgore = { 5137.49987792969, 3424.99984741211, 39},
		Hellfire = { 5164.5830078125, 3443.74987792969, 40},
		Ironforge = { 790.625061035156, 527.6044921875, 41},
		ThousandNeedles = { 4399.99969482422, 2933.3330078125, 42},
		Stranglethorn = { 6381.24975585938, 4254.166015625, 43},
		Badlands = { 2487.5, 1658.33349609375, 44},
		Teldrassil = { 5091.66650390625, 3393.75, 45},
		Moonglade = { 2308.33325195313, 1539.5830078125, 46},
		ShadowmoonValley = { 5500.0, 3666.66638183594, 47},
		Tirisfal = { 4518.74987792969, 3012.49981689453, 48},
		Aszhara = { 5070.83276367188, 3381.24987792969, 49},
		Redridge = { 2170.83325195313, 1447.916015625, 50},
		BloodmystIsle = { 3262.4990234375, 2174.99993896484, 51},
		WesternPlaguelands = { 4299.99990844727, 2866.66653442383, 52},
		Alterac = { 2799.99993896484, 1866.66665649414, 53},
		Westfall = { 3499.99981689453, 2333.3330078125, 54},
		Duskwood = { 2699.99993896484, 1800.0, 55},
		Netherstorm = { 5574.99967193604, 3716.66674804688, 56},
		Ghostlands = { 3300.0, 2199.99951171875, 57},
		Zangarmarsh = { 5027.08349609375, 3352.08325195313, 58},
		Desolace = { 4495.8330078125, 2997.91656494141, 59},
		Kalimdor = { 36799.810546875, 24533.2001953125, 60},
		SearingGorge = { 2231.24984741211, 1487.49951171875, 61},
		Expansion01 = { 17464.078125, 11642.71875, 62},
		Feralas = { 6949.99975585938, 4633.3330078125, 63},
		Hilsbrad = { 3199.99987792969, 2133.33325195313, 64},
		Sunwell = { 3327.0830078125, 2218.7490234375, 65},
		Northrend = { 17751.3984375, 11834.2650146484, 66},
		BoreanTundra = { 5764.5830078125, 3843.74987792969, 67},
		Dragonblight = { 5608.33312988281, 3739.58337402344, 68},
		GrizzlyHills = { 5249.99987792969, 3499.99987792969, 69},
		HowlingFjord = { 6045.83288574219, 4031.24981689453, 70},
		IcecrownGlacier = { 6270.83331298828, 4181.25, 71},
		SholazarBasin = { 4356.25, 2904.16650390625, 72},
		TheStormPeaks = { 7112.49963378906, 4741.666015625, 73},
		ZulDrak = { 4993.75, 3329.16650390625, 74},
		ScarletEnclave = { 3162.5, 2108.33337402344, 76},
		CrystalsongForest = { 2722.91662597656, 1814.5830078125, 77},
		LakeWintergrasp = { 2974.99987792969, 1983.33325195313, 78},
		StrandoftheAncients = { 1743.74993896484, 1162.49993896484, 79},
		Dalaran = { 0.0, 0.0, 80},
		Naxxramas = { 1856.24975585938, 1237.5, 81},
		Naxxramas1 = { 1093.830078125, 729.219970703125, 82},
		Naxxramas2 = { 1093.830078125, 729.219970703125, 83},
		Naxxramas3 = { 1200.0, 800.0, 84},
		Naxxramas4 = { 1200.330078125, 800.219970703125, 85},
		Naxxramas5 = { 2069.80981445313, 1379.8798828125, 86},
		Naxxramas6 = { 655.93994140625, 437.2900390625, 87},
		TheForgeofSouls = { 11399.9995117188, 7599.99975585938, 88},
		TheForgeofSouls1 = { 1448.09985351563, 965.400390625, 89},
		AlteracValley = { 4237.49987792969, 2824.99987792969, 90},
		WarsongGulch = { 1145.83331298828, 764.583312988281, 91},
		IsleofConquest = { 2650.0, 1766.66658401489, 92},
		TheArgentColiseum = { 2599.99996948242, 1733.33334350586, 93},
		TheArgentColiseum1 = { 369.986186981201, 246.657989501953, 94},
		TheArgentColiseum1 = { 369.986186981201, 246.657989501953, 95},
		TheArgentColiseum2 = { 739.996017456055, 493.330017089844, 96},
		HrothgarsLanding = { 3677.08312988281, 2452.083984375, 97},
		AzjolNerub = { 1072.91664505005, 714.583297729492, 98},
		AzjolNerub1 = { 752.973999023438, 501.983001708984, 99},
		AzjolNerub2 = { 292.973999023438, 195.315979003906, 100},
		AzjolNerub3 = { 367.5, 245.0, 101},
		Ulduar77 = { 3399.99981689453, 2266.66666412354, 102},
		Ulduar771 = { 920.196014404297, 613.466064453125, 103},
		DrakTharonKeep = { 627.083312988281, 418.75, 104},
		DrakTharonKeep1 = { 619.941009521484, 413.293991088867, 105},
		DrakTharonKeep2 = { 619.941009521484, 413.293991088867, 106},
		HallsofReflection = { 12999.9995117188, 8666.66650390625, 107},
		HallsofReflection1 = { 879.02001953125, 586.01953125, 108},
		TheObsidianSanctum = { 1162.49991798401, 775.0, 109},
		HallsofLightning = { 3399.99993896484, 2266.66666412354, 110},
		HallsofLightning1 = { 566.235015869141, 377.489990234375, 111},
		HallsofLightning2 = { 708.237014770508, 472.160034179688, 112},
		IcecrownCitadel = { 12199.9995117188, 8133.3330078125, 113},
		IcecrownCitadel1 = { 1355.47009277344, 903.647033691406, 114},
		IcecrownCitadel2 = { 1067.0, 711.333690643311, 115},
		IcecrownCitadel3 = { 195.469970703125, 130.315002441406, 116},
		IcecrownCitadel4 = { 773.710083007813, 515.810302734375, 117},
		IcecrownCitadel5 = { 1148.73999023438, 765.820068359375, 118},
		IcecrownCitadel6 = { 373.7099609375, 249.1298828125, 119},
		IcecrownCitadel7 = { 293.260009765625, 195.507019042969, 120},
		IcecrownCitadel8 = { 247.929931640625, 165.287994384766, 121},
		VioletHold = { 383.333312988281, 256.25, 122},
		VioletHold1 = { 256.22900390625, 170.820068359375, 123},
		NetherstormArena = { 2270.83319091797, 1514.58337402344, 124},
		CoTStratholme = { 1824.99993896484, 1216.66650390625, 125},
		CoTStratholme1 = { 1125.29998779297, 750.199951171875, 126},
		TheEyeofEternity = { 3399.99981689453, 2266.66666412354, 127},
		TheEyeofEternity1 = { 430.070068359375, 286.713012695313, 128},
		Nexus80 = { 2600.0, 1733.33322143555, 129},
		Nexus801 = { 514.706970214844, 343.138977050781, 130},
		Nexus802 = { 664.706970214844, 443.138977050781, 131},
		Nexus803 = { 514.706970214844, 343.138977050781, 132},
		Nexus804 = { 294.700988769531, 196.463989257813, 133},
		VaultofArchavon = { 2599.99987792969, 1733.33325195313, 134},
		VaultofArchavon1 = { 1398.25500488281, 932.170013427734, 135},
		Ulduar = { 3287.49987792969, 2191.66662597656, 136},
		Ulduar1 = { 669.450988769531, 446.300048828125, 137},
		Ulduar2 = { 1328.46099853516, 885.639892578125, 138},
		Ulduar3 = { 910.5, 607.0, 139},
		Ulduar4 = { 1569.4599609375, 1046.30004882813, 140},
		Ulduar5 = { 619.468994140625, 412.97998046875, 141},
		Dalaran1 = { 830.015014648438, 553.33984375, 142},
		Dalaran2 = { 563.223999023438, 375.48974609375, 143},
		Gundrak = { 1143.74996948242, 762.499877929688, 144},
		Gundrak1 = { 905.033050537109, 603.35009765625, 145},
		TheNexus = { 0.0, 0.0, 146},
		TheNexus1 = { 1101.2809753418, 734.1875, 147},
		PitofSaron = { 1533.33331298828, 1022.91667175293, 148},
		Ahnkahet = { 972.91667175293, 647.916610717773, 149},
		Ahnkahet1 = { 972.41796875, 648.279022216797, 150},
		ArathiBasin = { 1756.24992370605, 1170.83325195313, 151},
		UtgardePinnacle = { 6549.99951171875, 4366.66650390625, 152},
		UtgardePinnacle1 = { 548.936019897461, 365.957015991211, 153},
		UtgardePinnacle2 = { 756.179943084717, 504.119003295898, 154},
		UtgardeKeep = { 0.0, 0.0, 155},
		UtgardeKeep1 = { 734.580993652344, 489.721500396729, 156},
		UtgardeKeep2 = { 481.081008911133, 320.720293045044, 157},
		UtgardeKeep3 = { 736.581008911133, 491.054512023926, 158},
		TheRubySanctum = { 752.083312988281, 502.083251953125, 159},
	}, {__index = function(t, k)
		if k then
			error("BigWigs has no zone data for " .. k .. ". Please report this as a bug.")
			rawset(t, k, false)
		end
		return rawget(t, k)
	end })
end