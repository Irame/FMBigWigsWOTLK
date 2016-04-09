--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Lady Deathwhisper", "Icecrown Citadel")
if not mod then return end
--Deathwhisper, Cult Adherent, Reanimated Adherent, Cult Fanatic, Reanimated Fanatic, Deformed Fanatic
mod:RegisterEnableMob(36855, 37949, 38010, 37890, 38009, 38135)
mod.toggleOptions = {"adds", {70842, "HEALTHBAR"}, 71204, 71426, 71289, {71001, "FLASHSHAKE"}, "berserk", "bosskill"}
local CL = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Common")
mod.optionHeaders = {
	adds = CL.phase:format(1),
	[71204] = CL.phase:format(2),
	[71289] = "general",
}
mod.order = 13

--------------------------------------------------------------------------------
-- Locals
--

local handle_Adds = nil
local dmTargets = mod:NewTargetList()

--------------------------------------------------------------------------------
--  Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_trigger = "What is this disturbance?"
	L.phase2_message = "Barrier DOWN - Phase 2!"

	L.dnd_message = "Death and Decay on YOU!"

	L.adds = "Adds"
	L.adds_desc = "Show timers for when the adds spawn."
	L.adds_bar = "Next Adds"
	L.adds_warning = "New adds in 5 sec!"

	L.touch_message = "%2$dx Touch on %1$s"
	L.touch_bar = "Next Touch"

	L.deformed_fanatic = "Deformed Fanatic!"

	L.spirit_message = "Summon Spirit!"
	L.spirit_bar = "Next Spirit"

	L.dominate_bar = "~Next Dominate Mind"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "DnD", 71001, 72108, 72109, 72110) --??, 25, ??, ??
	self:Log("SPELL_AURA_REMOVED", "Barrier", 70842)
	self:Log("SPELL_AURA_APPLIED", "DominateMind", 71289)
	self:Log("SPELL_AURA_APPLIED", "Touch", 71204)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Touch", 71204)
	self:Log("SPELL_CAST_START", "Deformed", 70900)
	self:Log("SPELL_SUMMON", "Spirit", 71426)
	self:Death("Win", 36855)

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:Yell("Engage", L["engage_trigger"])
end

local function adds(time)
	mod:DelayedMessage("adds", time-5, L["adds_warning"], "Attention")
	mod:Bar("adds", L["adds_bar"], time, 70768)
	handle_Adds = mod:ScheduleTimer(adds, time, time)
end

function mod:OnEngage(diff)
	self:Berserk(600, true)
	local time = 60
	if diff > 2 then time = 45 end
	self:Bar("adds", L["adds_bar"], 5, 70768)
	if diff > 1 then
		self:Bar(71289, L["dominate_bar"], 27, 71289)
	end
	handle_Adds = self:ScheduleTimer(adds, 5, time)
	self:HealthBar(70842, 36855, 0, 70842)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:DnD(player, spellId)
	if UnitIsUnit(player, "player") then
		self:LocalMessage(71001, L["dnd_message"], "Personal", spellId, "Alarm")
		self:FlashShake(71001)
	end
end

function mod:Barrier(_, spellId)
	self:CancelTimer(handle_Adds, true)
	self:SendMessage("BigWigs_StopBar", self, L["adds_bar"])
	self:CancelDelayedMessage(L["adds_warning"])
	if self:GetInstanceDifficulty() > 2 then
		self:DelayedMessage("adds", 40, L["adds_warning"], "Attention")
		self:Bar("adds", L["adds_bar"], 45, 70768)
		handle_Adds = self:ScheduleTimer(adds, 45, 45)
	end
	self:Message(70842, L["phase2_message"], "Positive", spellId, "Info")
	self:Bar(71426, L["spirit_bar"], 12, 71426)
	self:Bar(71204, L["touch_bar"], 6, 71204)
	self:HealthBarStop(70842, 36855, 0)
end

do
	local scheduled = nil
	local function dmWarn(spellName)
		mod:TargetMessage(71289, spellName, dmTargets, "Important", 71289, "Alert")
		scheduled = nil
	end
	function mod:DominateMind(player, spellId, _, _, spellName)
		dmTargets[#dmTargets + 1] = player
		if not scheduled then
			scheduled = true
			self:Bar(71289, L["dominate_bar"], 40, 71289)
			self:ScheduleTimer(dmWarn, 0.3, spellName)
		end
	end
end

function mod:Touch(player, spellId, _, _, _, stack)
	if stack and stack > 1 then
		self:TargetMessage(71204, L["touch_message"], player, "Urgent", spellId, nil, stack)
	end
	self:Bar(71204, L["touch_bar"], 9, spellId)
end

function mod:Deformed()
	self:Message("adds", L["deformed_fanatic"], "Urgent", 70900)
end

do
	local t = 0
	function mod:Spirit(_, spellId)
		local time = GetTime()
		if (time - t) > 5 then
			t = time
			self:Message(71426, L["spirit_message"], "Attention", spellId)
			self:Bar(71426, L["spirit_bar"], 18, spellId)
		end
	end
end

