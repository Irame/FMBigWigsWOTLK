--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("The Lich King", "Icecrown Citadel")
if not mod then return end
mod:RegisterEnableMob(36597)
mod.toggleOptions = {72143, 70541, {73912, "ICON", "FLASHSHAKE"}, 70372, {72762, "SAY", "ICON", "WHISPER", "FLASHSHAKE"}, 69409, 69037, {68980, "ICON", "WHISPER", "FLASHSHAKE"}, 70498, {74270, "FLASHSHAKE"}, 69200, {72262, "FLASHSHAKE"}, 72350, {73529, "SAY", "WHISPER", "FLASHSHAKE", "ICON"}, "berserk", "bosskill"}
local CL = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Common")
mod.optionHeaders = {
	[72143] = CL.phase:format(1),
	[72762] = CL.phase:format(2),
	[68980] = CL.phase:format(3),
	[74270] = "Transition",
	[73529] = "heroic",
	berserk = "general",
}
mod.order = 51

--------------------------------------------------------------------------------
-- Locals
--

local phase = 0
local hugged = mod:NewTargetList()
local class = select(2,UnitClass("player"))
local frenzied = {}
local plagueTicks = {}
local mapData = { [1] = 293.260009765625, [2] = 195.507019042969}
local valksToMark = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.warmup_trigger = "So the Light's vaunted justice has finally arrived"
	L.engage_trigger = "I'll keep you alive to witness the end, Fordring"

	L.horror_bar = "~Next Horror"
	L.horror_message = "Shambling Horror"

	L.necroticplague_bar = "Necrotic Plague"

	L.ragingspirit_bar = "Raging Spirit"

	L.valkyr_bar = "Next Val'kyr"
	L.valkyr_message = "Val'kyr"

	L.vilespirits_bar = "~Vile Spirits"

	L.harvestsoul_bar = "Harvest Soul"

	L.remorselesswinter_message = "Remorseless Winter Casting"
	L.quake_message = "Quake Casting"
	L.quake_bar = "Quake"

	L.defile_say = "Defile on ME!"
	L.defile_message = "Defile on YOU!"
	L.defile_bar = "Next Defile"

	L.infest_bar = "~Next Infest"

	L.reaper_bar = "~Next Reaper"

	L.last_phase_bar = "Last Phase"

	L.trap_say = "Shadow Trap on ME!"
	L.trap_near_say = "Shadow Trap next to ME!"
	L.trap_message = "Shadow Trap"
	L.trap_bar = "Next Trap"

	L.valkyrhug_message = "Val'kyrs Hugged"
	L.cave_phase = "Cave Phase"

	L.frenzy_bar = "%s frenzies!"
	L.frenzy_survive_message = "%s will survive after plague"
	L.enrage_bar = "~Enrage"
	L.frenzy_message = "Add frenzied!"
	L.frenzy_soon_message = "5sec to frenzy!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--


function mod:OnBossEnable()
	-- Phase 1
	self:Log("SPELL_CAST_START", "Infest", 70541, 73779, 73780, 73781)
	self:Log("SPELL_CAST_SUCCESS", "NecroticPlague", 70337, 70338, 73785, 73786, 73787, 73912, 73913, 73914)
	self:Log("SPELL_DISPEL", "PlagueScan", 528, 552, 4987, 51886) --cure, abolish, cleanse, cleanse spirit
	self:Log("SPELL_SUMMON", "Horror", 70372)
	self:Log("SPELL_CAST_START", "Enrage", 72143, 72146, 72147, 72148)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 28747)
	self:Log("SPELL_PERIODIC_DAMAGE", "PlagueTick", 70337, 70338, 73785, 73786, 73787, 73912, 73913, 73914)

	-- Phase 2
	self:Log("SPELL_CAST_SUCCESS", "SoulReaper", 69409, 73797, 73798, 73799)
	self:Log("SPELL_CAST_START", "DefileCast", 72762)
	self:Log("SPELL_DAMAGE", "DefileRun", 72754, 73708, 73709, 73710)
	self:Log("SPELL_SUMMON", "Valkyr", 69037)

	-- Phase 3
	self:Log("SPELL_CAST_SUCCESS", "HarvestSoul", 68980, 74325, 74326, 74327, 74295, 74296, 74297, 73654)
	self:Log("SPELL_AURA_REMOVED", "HSRemove", 68980, 74325, 74326, 74327)
	self:Log("SPELL_CAST_START", "VileSpirits", 70498)

	-- Transition phases
	self:Log("SPELL_CAST_START", "RemorselessWinter", 68981, 72259, 74270, 74271, 74272, 74273, 74274, 74275)
	self:Log("SPELL_CAST_SUCCESS", "RagingSpirit", 69200)
	self:Log("SPELL_CAST_START", "Quake", 72262)

	self:Log("SPELL_CAST_START", "FuryofFrostmourne", 72350)

	-- Hard Mode
	self:Log("SPELL_CAST_START", "ShadowTrap", 73539)

	self:Death("Win", 36597)

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:Yell("Warmup", L["warmup_trigger"])
	self:Yell("Engage", L["engage_trigger"])
end

function mod:Warmup()
	self:Bar("berserk", self.displayName, 54, "achievement_boss_lichking")
end

function mod:OnEngage(diff)
	wipe(frenzied)
	wipe(plagueTicks)

	self:Berserk(900)
	self:Bar(73912, L["necroticplague_bar"], 31, 73912)
	self:Bar(70372, L["horror_bar"], 22, 70372)
	phase = 1
	if diff > 2 then
		self:Bar(73529, L["trap_bar"], 16, 73539)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:PlagueTick(horrorName, _, _, tickDamage, _, _, _, _, _, dGUID)
	if self:IsDifficulty("nh") < 3 then return end -- Doesn't apply on normal diff.
	-- Not ticking on a Shambling Horror, so bail early
	if self.GetMobIdByGUID[dGUID] ~= 37698 then return end

	if not plagueTicks[dGUID] then plagueTicks[dGUID] = 1
	else plagueTicks[dGUID] = plagueTicks[dGUID] + 1 end
	if plagueTicks[dGUID] == 3 then
		plagueTicks[dGUID] = nil
		return
	end

	-- Search by full GUID, so we don't mistake one shambler for another
	local unitId = self:GetUnitIdByGUID(dGUID)
	if not unitId then return end

	-- Shambler is already frenzied, will it die from the plague or endure
	-- for a longer period?
	if frenzied[dGUID] then
		local damageLeft = (3 - plagueTicks[dGUID]) * tickDamage
		local hp = UnitHealth(unitId)
		if hp > damageLeft then
			self:Message(70372, "Attention", nil, L["frenzy_survive_message"]:format(horrorName), 72143)
		end
	else
		local hp, max = UnitHealth(unitId), UnitHealthMax(unitId)
		if not max or max == 0 then return end
		local nextTickHP = hp - tickDamage
		-- Will the shambler die from the next tick?
		if nextTickHP <= 0 then return end
		local percentHp = (nextTickHP / max) * 100
		-- This sucker will frenzy in 5 seconds
		if percentHp < 21 then
			self:Message(70372, "Important", "Info", L["frenzy_soon_message"], 72143)
			self:Bar(70372, L["frenzy_bar"]:format(horrorName), 5, 72143)
		end
	end
end

function mod:Frenzy(_, _, _, _, _, _, _, _, _, dGUID)
	frenzied[dGUID] = true
	self:Message(70372, "Important", "Long", L["frenzy_message"], 72143)
end

function mod:Horror(_, spellId)
	self:Message(70372, "Attention", nil, L["horror_message"])
	self:Bar(70372, L["horror_bar"], 60, spellId)
end

function mod:FuryofFrostmourne()
	self:SendMessage("BigWigs_StopBar", self, L["defile_bar"])
	self:SendMessage("BigWigs_StopBar", self, L["reaper_bar"])
	self:SendMessage("BigWigs_StopBar", self, L["vilespirits_bar"])
	self:SendMessage("BigWigs_StopBar", self, L["harvestsoul_bar"])
	self:Bar(72350, L["last_phase_bar"], 160, 72350)
end

function mod:Infest(_, spellId, _, _, spellName)
	self:Message(70541, "Urgent")
	self:Bar(70541, L["infest_bar"], 22, spellId)
end

function mod:VileSpirits(_, spellId, _, _, spellName)
	self:Message(70498, "Urgent")
	self:Bar(70498, L["vilespirits_bar"], 30.5, spellId)
end

function mod:SoulReaper(player, spellId, _, _, spellName)
	self:TargetMessage(69409, player, "Personal", "Alert")
	self:Bar(69409, L["reaper_bar"], 34, spellId)
end

function mod:NecroticPlague(player, spellId, _, _, spellName)
	self:TargetMessage(73912, player, "Personal", "Alert")
	if UnitIsUnit(player, "player") then 
		self:FlashShake(73912)
	end
	self:Bar(73912, L["necroticplague_bar"], 30, spellId)
	self:SecondaryIcon(73912, player)
end

do
	local plague = GetSpellInfo(70337)
	local function scanRaid()
		for i = 1, GetNumRaidMembers() do
			local player = GetRaidRosterInfo(i)
			if player then
				local debuffed, _, _, _, _, _, expire = UnitDebuff(player, plague)
				if debuffed and (expire - GetTime()) > 13 then
					mod:TargetMessage(73912, player, "Personal", "Alert")
					if UnitIsUnit(player, "player") then mod:FlashShake(73912) end
					mod:SecondaryIcon(73912, player)
				end
			end
		end
	end
	function mod:PlagueScan()
		self:ScheduleTimer(scanRaid, 0.8)
	end
end

function mod:Enrage(_, spellId, _, _, spellName)
	if class == "HUNTER" or class == "ROGUE" then
		self:Message(72143, "Attention", "Info")
		self:Bar(72143, L["enrage_bar"], 21, spellId)
	else
		self:Message(72143, "Attention")
	end
end

function mod:RagingSpirit(player, spellId, _, _, spellName)
	self:TargetMessage(69200, player, "Personal", "Alert")
	self:Bar(69200, L["ragingspirit_bar"], 23, spellId)
end

local last = 0
function mod:DefileRun(player, spellId)
	local time = GetTime()
	if (time - last) > 2 then
		last = time
		if UnitIsUnit(player, "player") then
			self:LocalMessage(72762, "Personal", "Info", L["defile_message"])
			self:FlashShake(72762)
		end
	end
end

do
	local function ValkyrHugCheck()
		for i=1, GetNumRaidMembers() do
			local n = GetRaidRosterInfo(i)
			if UnitInVehicle(n) then
				hugged[#hugged + 1] = n
			end
		end
		mod:TargetMessage(69037, hugged, "Urgent", nil, L["valkyrhug_message"])
	end

	local t = 0
	function mod:Valkyr(_, spellId, _, _, _, _, _, _, _, dGUID)
		valksToMark[dGUID] = true
		local time = GetTime()
		if (time - t) > 4 then
			t = time
			self:Message(69037, "Attention", nil, L["valkyr_message"], 71844)
			self:Bar(69037, L["valkyr_bar"], 46, 71844)
			self:ScheduleTimer(ValkyrHugCheck, 6.1)
		end
	end
end

function mod:HarvestSoul(player, spellId, _, _, spellName)
	if self:IsDifficulty("hc") then
		self:SendMessage("BigWigs_StopBar", self, L["defile_bar"])
		self:SendMessage("BigWigs_StopBar", self, L["reaper_bar"])
		self:SendMessage("BigWigs_StopBar", self, L["ragingspirit_bar"])
		self:Bar(68980, L["cave_phase"], 50, spellId)
		self:Bar(68980, L["harvestsoul_bar"], 105, spellId)
	else
		self:Bar(68980, L["harvestsoul_bar"], 75, spellId)
		if UnitIsUnit(player, "player") then self:FlashShake(68980) end
		self:TargetMessage(68980, player, "Attention")
		self:Whisper(68980, player, spellName)
		self:SecondaryIcon(68980, player)
	end
end

function mod:HSRemove(player, spellId)
	self:SecondaryIcon(68980, false)
end

function mod:RemorselessWinter(_, spellId)
	phase = phase + 1
	self:SendMessage("BigWigs_StopBar", self, L["necroticplague_bar"])
	self:SendMessage("BigWigs_StopBar", self, L["horror_bar"])
	self:SendMessage("BigWigs_StopBar", self, L["infest_bar"])
	self:SendMessage("BigWigs_StopBar", self, L["defile_bar"])
	self:SendMessage("BigWigs_StopBar", self, L["reaper_bar"])
	self:SendMessage("BigWigs_StopBar", self, L["valkyr_bar"])
	self:SendMessage("BigWigs_StopBar", self, L["trap_bar"])
	self:LocalMessage(74270, "Urgent", "Alert", L["remorselesswinter_message"])
	self:Bar(72262, L["quake_bar"], 62, 72262)
	self:Bar(69200, L["ragingspirit_bar"], 15, spellId)
end

function mod:Quake(_, spellId)
	phase = phase + 1
	self:SendMessage("BigWigs_StopBar", self, L["ragingspirit_bar"])
	self:LocalMessage(72262, "Urgent", "Alert", L["quake_message"])
	self:Bar(72762, L["defile_bar"], 37, 72762)
	self:Bar(70541, L["infest_bar"], 13, 70541)
	self:Bar(69409, L["reaper_bar"], 30, 69409)
	if phase == 3 then
		self:Bar(69037, L["valkyr_bar"], 24, 71844)
	elseif phase == 5 then
		self:Bar(70498, L["vilespirits_bar"], 21, 70498)
		self:Bar(68980, L["harvestsoul_bar"], 12, 68980)
	end
end

do
	local scheduled, stinvoker, stinvoker2, trapInitialTarget, lastDefile = nil, nil, nil, nil, 0
	local function scanTarget(spellName)
		--print("scanTarget:","lastDefile:",lastDefile,GetTime())
		if GetTime() - lastDefile < 5 then return end
		scheduled = nil
		local bossId = mod:GetUnitIdByGUID(36597)
		--print("scanTarget:","bossId:",bossId)
		if not bossId then return end
		local target = UnitName(bossId .. "target")
		--print("scanTarget:","target:",target)
		--print("scanTarget:","trapInitialTarget:",trapInitialTarget)
		if target and target ~= trapInitialTarget then
			--print("scanTarget:","GOAL")
			lastDefile = GetTime()
			if UnitIsUnit(target, "player") then
				mod:FlashShake(72762)
				mod:Say(72762, L["defile_say"])
			end
			mod:TargetMessage(72762, target, "Important", "Alert")
			mod:Whisper(72762, target, spellName)
			mod:PrimaryIcon(72762, target)
			mod:UnregisterEvent("UNIT_TARGET")
		end
	end
	function mod:DefileCast(_, spellId, _, _, spellName)
		--print("DefileCast:","scheduled:",scheduled)
		if not scheduled then
			scheduled = true
			stinvoker = stinvoker or function() scanTarget(spellName) end
			stinvoker2 = stinvoker2 or function() trapInitialTarget = nil; scanTarget(spellName) end
			local bossId = mod:GetUnitIdByGUID(36597)
			--print("DefileCast:","bossId:",bossId)
			if not bossId then return end
			trapInitialTarget = UnitName(bossId .. "target")
			--print("DefileCast:","trapInitialTarget:",trapInitialTarget)
			--self:ScheduleTimer(trapTarget, 0.1, spellName)
			self:Bar(72762, L["defile_bar"], 32, 72762)
			if (UnitExists("focus") and self.GetMobIdByGUID[UnitGUID("focus")] == 36597) or (UnitExists("target") and self.GetMobIdByGUID[UnitGUID("target")] == 36597) then
				--print("DefileCast:","UNIT_TARGET")
				mod:RegisterEvent("UNIT_TARGET", "DFTargetEvent")
			else
				--print("DefileCast:","Spam")
				-- Spam-check!
				self:ScheduleTimer(stinvoker, 0.1)
				self:ScheduleTimer(stinvoker, 0.2)
				self:ScheduleTimer(stinvoker, 0.3)
				self:ScheduleTimer(stinvoker, 0.4)
			end
			self:ScheduleTimer(stinvoker2, 0.5)
		end
	end
	function mod:DFTargetEvent(_,unit)
		if UnitGUID(unit) and self.GetMobIdByGUID[UnitGUID(unit)] == 36597 then
			--print("DFTargetEvent:","unit:",unit)
			scanTarget((GetSpellInfo(72762)))
		end
	end
end

do
	local scheduled, stinvoker, stinvoker2, trapInitialTarget, lastTrap = nil, nil, nil, nil, 0
	local function trapTarget(spellName)
		if GetTime() - lastTrap < 5 then return end
		scheduled = nil
		local bossId = mod:GetUnitIdByGUID(36597)
		if not bossId then return end
		local target = UnitName(bossId .. "target")
		if target and target ~= trapInitialTarget then
			lastTrap = GetTime()
			if UnitIsUnit(target, "player") then
				mod:FlashShake(73529)
				mod:Say(73529, L["trap_say"])
			else
				local xTarRel,yTarRel = GetPlayerMapPosition(target)
				local xPlayerRel,yPlayerRel = GetPlayerMapPosition("player")
				local xTar,yTar,xPlayer,yPlayer = mapData[1]*xTarRel,mapData[2]*yTarRel,mapData[1]*xPlayerRel,mapData[2]*yPlayerRel
				local distance = math.sqrt((xTar-xPlayer)^2 + (yTar-yPlayer)^2)
				if distance < 6 and distance > 0 then
					mod:FlashShake(73529)
					--mod:Say(73529, L["trap_near_say"])
				end
			end
			mod:TargetMessage(73529, target, "Attention", nil, L["trap_message"])
			mod:Whisper(73529, target, spellName)
			mod:PrimaryIcon(73529, target)
			mod:UnregisterEvent("UNIT_TARGET")
		end
	end
	function mod:ShadowTrap(_, spellId, _, _, spellName)
		if not scheduled then
			scheduled = true
			stinvoker = stinvoker or function() trapTarget(spellName) end
			stinvoker2 = stinvoker2 or function() trapInitialTarget = nil; trapTarget(spellName) end
			local bossId = mod:GetUnitIdByGUID(36597)
			if not bossId then return end
			trapInitialTarget = UnitName(bossId .. "target")
			--self:ScheduleTimer(trapTarget, 0.1, spellName)
			self:Bar(73529, L["trap_bar"], 16, spellId)
			if (UnitExists("focus") and self.GetMobIdByGUID[UnitGUID("focus")] == 36597) or (UnitExists("target") and self.GetMobIdByGUID[UnitGUID("target")] == 36597) then
				mod:RegisterEvent("UNIT_TARGET", "STTargetEvent")
			else
				-- Spam-check!
				self:ScheduleTimer(stinvoker, 0.1)
				self:ScheduleTimer(stinvoker, 0.2)
				self:ScheduleTimer(stinvoker, 0.3)
				self:ScheduleTimer(stinvoker, 0.4)
				self:ScheduleTimer(stinvoker, 0.5)
			end
			self:ScheduleTimer(stinvoker2, 1)
		end
	end
	function mod:STTargetEvent(_,unit)
		if UnitGUID(unit) and self.GetMobIdByGUID[UnitGUID(unit)] == 36597 then
			trapTarget((GetSpellInfo(73539)))
		end
	end
end