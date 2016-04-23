--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Sindragosa", "Icecrown Citadel")
if not mod then return end
-- Sindragosa, Rimefang, Spinestalker
mod:RegisterEnableMob(36853, 37533, 37534)
mod.toggleOptions = {"airphase", "phase2", 70127, {69762, "FLASHSHAKE"}, {69766, "PROXIMITY", "SAY"}, 70106, 71047, {70126, "PROXIMITY", "FLASHSHAKE"}, "berserk", "bosskill"}
local CL = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Common")
mod.optionHeaders = {
	airphase = CL.phase:format(1),
	phase2 = CL.phase:format(2),
	[69762] = "general",
}
mod.order = 43

--------------------------------------------------------------------------------
-- Locals
--

local phase = 0
local playerHasUnchained = false
local proxInstabilityTargetTable = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_trigger = "You are fools to have come to this place."

	L.phase2 = "Phase 2"
	L.phase2_desc = "Warn when Sindragosa goes into phase 2, at 35%."
	L.phase2_trigger = "Now feel my master's limitless power and despair!"
	L.phase2_message = "Phase 2!"

	L.airphase = "Air phase"
	L.airphase_desc = "Warn when Sindragosa will lift off."
	L.airphase_trigger = "Your incursion ends here! None shall survive!"
	L.airphase_message = "Air phase!"
	L.airphase_bar = "Next air phase"

	L.boom_message = "Explosion!"
	L.boom_bar = "Explosion"

	L.grip_bar = "Next Icy Grip"

	L.unchained_message = "Unchained magic on YOU!"
	L.unchained_bar = "Unchained Magic"
	L.instability_message = "Unstable x%d!"
	L.chilled_message = "Chilled x%d!"
	L.buffet_message = "Magic x%d!"
	L.buffet_cd = "Next Magic"
	
	L.mage_bug_message = "Mage Bug: %s!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Unchained", 69762)
	self:Log("SPELL_AURA_REMOVED", "UnchainedRemoved", 69762)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Instability", 69766)
	self:Log("SPELL_AURA_APPLIED", "Instability", 69766)
	self:Log("SPELL_AURA_REMOVED", "InstabilityRemoved", 69766)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Chilled", 70106)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Buffet", 70127, 72528, 72529, 72530)

	self:Log("SPELL_AURA_APPLIED", "FrostBeacon", 70126)
	self:Log("SPELL_AURA_APPLIED", "Tombed", 70157)

	-- 70123, 71047, 71048, 71049 is the actual blistering cold
	self:Log("SPELL_CAST_SUCCESS", "Grip", 70117)

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:Yell("Engage", L["engage_trigger"])
	self:Yell("AirPhase", L["airphase_trigger"])
	self:Yell("Phase2", L["phase2_trigger"])
	self:Death("Win", 36853)
end

function mod:OnEngage()
	phase = 1
	self:Berserk(600)
	self:Bar("airphase", L["airphase_bar"], 63, 23684)
	self:Bar(69762, L["unchained_bar"], 15, 69762)
	self:Bar(71047, L["grip_bar"], 34, 70117)
	playerHasUnchained = false
	wipe(proxInstabilityTargetTable)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Tombed(player)
	if UnitIsUnit(player, "player") then
		self:CloseProximity()
	end
end

do
	local msgTargets = mod:NewTargetList()
	local proxTargets = {}
	local onMe = false
	local scheduled = nil
	local function baconWarn(spellName)
		if phase == 1 and ((#msgTargets < 2 and mod:IsDifficulty("10")) or (#msgTargets < 5 and mod:IsDifficulty("25nh")) or (#msgTargets < 6 and mod:IsDifficulty("25hc"))) then
			mod:Message(70126, "Important", "Alarm", L["mage_bug_message"]:format(spellName))
			local _,playerClass = UnitClass("player")
			if playerClass == "MAGE" then
				self:OpenProximity(10,70126)
				self:ScheduleTimer(self.CloseProximity, 7, self)
			end
		end
		if onMe then
			self:OpenProximity(10, 70126)
		else
			self:OpenProximity(10, 70126, proxTargets)
		end
		mod:TargetMessage(70126, msgTargets, "Urgent")
		mod:Bar(70126, spellName, 7, 70126)
		scheduled = nil
		onMe = false
	end
	function mod:FrostBeacon(player, spellId, _, _, spellName)
		msgTargets[#msgTargets + 1] = player
		proxTargets[#proxTargets + 1] = player
		if UnitIsUnit(player, "player") then
			onMe = true
			self:FlashShake(70126)
		end
		if not scheduled then
			scheduled = true
			self:ScheduleTimer(baconWarn, 0.2, spellName)
		end
	end
end

function mod:Grip()
	self:Message(71047, "Important", "Alarm", L["boom_message"])
	self:Bar(71047, L["boom_bar"], 5, 71047)
	if phase == 2 then
		self:Bar(71047, L["grip_bar"], 67, 70117)
	end
end

function mod:AirPhase()
	self:Message("airphase", "Positive", nil, L["airphase_message"], 23684)
	self:Bar("airphase", L["airphase_bar"], 110, 23684)
	self:Bar(71047, L["grip_bar"], 80, 70117)
	self:Bar(69762, L["unchained_bar"], 57, 69762)
end

function mod:Phase2()
	phase = 2
	self:SendMessage("BigWigs_StopBar", self, L["airphase_bar"])
	self:Message("phase2", "Positive", "Long", L["phase2_message"], false)
	self:Bar(71047, L["grip_bar"], 38, 70117)
end

function mod:Buffet(player, spellId, _, _, _, stack)
	self:Bar(70127, L["buffet_cd"], 6, 70127)
	if (stack % 2 == 0) and UnitIsUnit(player, "player") then
		self:LocalMessage(70127, "Attention", "Info", L["buffet_message"]:format(stack))
	end
end

do
	function mod:Instability(player, spellId, _, _, _, stack)
		if not stack then stack = 1 end
		if stack > 4 and UnitIsUnit(player, "player") then
			self:LocalMessage(69766, "Personal", nil, L["instability_message"]:format(stack))
			if (stack % 2 == 0) and mod:IsDifficulty("hc") then
				self:Say(69766, L["instability_message"]:format(stack))
			end
		end
		if not proxInstabilityTargetTable[player] then
			proxInstabilityTargetTable[player] = true
			if not playerHasUnchained then
				local proxTargets = {}
				for p, _ in pairs(proxInstabilityTargetTable) do
					proxTargets[#proxTargets + 1] = p
				end
				mod:OpenProximity(20, 69766, proxTargets)
			end
		end
	end
	function mod:InstabilityRemoved(player)
		if proxInstabilityTargetTable[player] then
			proxInstabilityTargetTable[player] = nil
			if not playerHasUnchained then
				local proxTargets = {}
				for p, _ in pairs(proxInstabilityTargetTable) do
					proxTargets[#proxTargets + 1] = p
				end
				mod:OpenProximity(20, 69766, proxTargets)
			end
		end
	end
end
	
function mod:Chilled(player, spellId, _, _, _, stack)
	if stack > 4 and UnitIsUnit(player, "player") then
		self:LocalMessage(70106, "Personal", nil, L["chilled_message"]:format(stack))
	end
end

do
	local unchainedTargets = mod:NewTargetList()
	local scheduledUnchained = nil
	local function unchainedTargetWarning(spellName)
		if ((#unchainedTargets < 6 and mod:IsDifficulty("25")) or (#unchainedTargets < 2 and mod:IsDifficulty("10"))) then
			mod:Message(69762, "Important", "Alarm", L["mage_bug_message"]:format(spellName))
			local _,playerClass = UnitClass("player")
			if playerClass == "MAGE" then
				self:OpenProximity(20,69762)
				self:ScheduleTimer(self.CloseProximity, 30, self)
			end
		end
		mod:TargetMessage(69762, unchainedTargets, "Urgent")
		scheduledUnchained = nil
	end
	function mod:Unchained(player, spellId, _, _, spellName)
		unchainedTargets[#unchainedTargets + 1] = player
		if UnitIsUnit(player, "player") then
			self:FlashShake(69762)
			if mod:IsDifficulty("hc") then
				playerHasUnchained = true
				self:OpenProximity(20,69762)
			end
		end
		if not scheduledUnchained then
			scheduledUnchained = true
			if phase == 1 then
				self:Bar(69762, L["unchained_bar"], 30, spellId)
			elseif phase == 2 then
				self:Bar(69762, L["unchained_bar"], 80, spellId)
			end
			self:ScheduleTimer(unchainedTargetWarning, 0.3, spellName)
		end
	end
end

function mod:UnchainedRemoved(player, spellId)
	if UnitIsUnit(player, "player") then
		playerHasUnchained = false
		self:CloseProximity(69762)
		local proxTargets = {}
		for p, _ in pairs(proxInstabilityTargetTable) do
			proxTargets[#proxTargets + 1] = p
		end
		mod:OpenProximity(20, 69766, proxTargets)
	end
end

