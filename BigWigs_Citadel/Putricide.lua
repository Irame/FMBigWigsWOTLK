--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Professor Putricide", "Icecrown Citadel")
if not mod then return end
--Putricide, Gas Cloud (Red Ooze), Volatile Ooze (Green Ooze)
mod:RegisterEnableMob(36678, 37562, 37697)
mod.toggleOptions = {70341, {70447, "ICON"}, {72455, "WHISPER", "FLASHSHAKE"}, 71966, 71255, {72295, "SAY", "FLASHSHAKE"}, 72451, {72855, "ICON", "FLASHSHAKE"}, "phase", "berserk", "bosskill"}
local CL = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Common")
mod.optionHeaders = {
	[70447] = CL.phase:format(1),
	[71255] = CL.phase:format(2),
	[72451] = CL.phase:format(3),
	[72855] = "heroic",
	phase = "general",
}
mod.order = 23

--------------------------------------------------------------------------------
-- Locals
--

local p2, p3, first, barText, lastGoo = nil, nil, nil, "test", 0
local oozeTargets = mod:NewTargetList()
local gasTargets = mod:NewTargetList()

--------------------------------------------------------------------------------
--  Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.phase = "Phases"
	L.phase_desc = "Warn for phase changes."
	L.phase_warning = "Phase %d soon!"
	L.phase_bar = "Next Phase"
	
	L.slime_bar = "Next Slime Puddle"

	L.engage_trigger = "perfected a plague that will destroy"

	L.ball_bar = "Next bouncing goo ball"
	L.ball_say = "Goo ball incoming!"
	
	L.slime_message = "Slime incoming!"
	L.experiment_message = "Ooze incoming!"
	L.experiment_heroic_message = "Oozes incoming!"
	L.experiment_bar = "Next ooze"
	L.blight_message = "Red ooze"
	L.violation_message = "Green ooze"

	L.plague_bar = "Next plague"
	L.unboundplague_bar = "Next Unbound Plague"

	L.gasbomb_bar = "More yellow gas bombs"
	L.gasbomb_message = "Yellow bombs!"

	L.unbound_bar = "Unbound Plague: %s"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "ChasedByRedOoze", 72455, 70672, 72832, 72833)
	self:Log("SPELL_AURA_APPLIED", "StunnedByGreenOoze", 70447, 72836, 72837, 72838)
	self:Log("SPELL_CAST_START", "Experiment", 70351, 71966, 71967, 71968)
	self:Log("SPELL_CAST_SUCCESS", "Slime", 70341)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Plague", 72451, 72463, 72671, 72672)
	self:Log("SPELL_AURA_APPLIED", "Plague", 72451, 72463, 72671, 72672)
	self:Log("SPELL_CAST_SUCCESS", "GasBomb", 71255)
	--self:Log("SPELL_CAST_SUCCESS", "BouncingGooBall", 72295, 74280, 72615, 74281) --10/25
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE", "MalleableGooBE") --custom
	self:RegisterEvent("UNIT_SPELLCAST_START", "MalleableGooSS") --custom
	self:Log("SPELL_AURA_APPLIED", "TearGasStart", 71615)
	self:Log("SPELL_AURA_REMOVED", "TearGasOver", 71615)

	-- Heroic
	self:Log("SPELL_AURA_APPLIED", "UnboundPlague", 72855, 72856)
	self:Log("SPELL_CAST_START", "VolatileExperiment", 72840, 72841, 72842, 72843)

	self:RegisterEvent("UNIT_HEALTH")

	self:Death("RedOozeDeath", 37562)
	self:Death("Win", 36678)

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:Yell("Engage", L["engage_trigger"])
end

function mod:OnEngage(diff)
	self:Berserk(600)
	p2, p3, first = nil, nil, nil
	self:Bar(71966, L["experiment_bar"], 31, 71966)
	self:Bar(70341, L["slime_bar"], 10, 70341)
	if diff > 2 then
		self:Bar(72855, L["unboundplague_bar"], 20, 72855)
		self:ScheduleTimer(self.OpenProximity, 15, 10, 72855)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local function stopOldStuff()
		mod:SendMessage("BigWigs_StopBar", mod, L["experiment_bar"])
		mod:SendMessage("BigWigs_StopBar", mod, barText)
	end
	local function newPhase()
		mod:Bar(71255, L["gasbomb_bar"], 14, 71255)
		mod:Bar(72295, L["ball_bar"], 6, 72295)
		if not first then
			mod:Message("phase", "Positive", nil, CL.phase:format(2), "achievement_boss_profputricide")
			mod:Bar(71966, L["experiment_bar"], 25, 71966)
			first = true
			p2 = true
		else
			mod:Message("phase", "Positive", nil, CL.phase:format(3), "achievement_boss_profputricide")
			first = nil
			p3 = true
		end
	end

	-- Heroic mode phase change
	function mod:VolatileExperiment()
		stopOldStuff()
		self:Message("phase", "Important", nil, L["experiment_heroic_message"], 71968)
		if not first then
			self:Bar("phase", L["phase_bar"], 45, "achievement_boss_profputricide")
			self:ScheduleTimer(newPhase, 45)
		else
			self:Bar("phase", L["phase_bar"], 37, "achievement_boss_profputricide")
			self:ScheduleTimer(newPhase, 37)
		end
	end

	-- Normal mode phase change
	local stop = nil
	local function nextPhase()
		stop = nil
	end
	function mod:TearGasStart()
		if stop then return end
		stop = true
		self:Bar("phase", L["phase_bar"], 11, "achievement_boss_profputricide")
		self:ScheduleTimer(nextPhase, 3)
		stopOldStuff()
	end
	function mod:TearGasOver()
		if stop then return end
		stop = true
		self:ScheduleTimer(nextPhase, 13)
		newPhase()
	end
end

function mod:Plague(player, spellId, _, _, _, stack)
	stack = stack or 1
	self:StackMessage(72451, player, stack, "Urgent", "Info")
	self:Bar(72451, L["plague_bar"], 10, spellId)
end

--custom START
local scheduled = nil
	local function scanTargetCustom(spellName)
		scheduled = nil
		local bossId = mod:GetUnitIdByGUID(36678)
		if not bossId then return end
		local target = UnitName(bossId .. "target")
		if target then
			if UnitIsUnit(target, "player") then
				mod:Say(72295, L["ball_say"])
			end
			mod:FlashShake(72295)
			mod:TargetMessage(72295, target, "Attention")
		end
		if mod:IsDifficulty("hc") then
			mod:Bar(72295, L["ball_bar"], 30, 72295)
		else
			mod:Bar(72295, L["ball_bar"], 30, 72295)
		end
	end
	
	function mod:MalleableGooSS(_, _, spellName)
		if not scheduled and spellName == GetSpellInfo(72295) then
			scheduled = true
			self:ScheduleTimer(scanTargetCustom, 0.2, spellName)
		end
	end
	
	function mod:MalleableGooBE(_, msg)
		if not scheduled and string.find(msg,"inv_misc_herb_evergreenmoss") then
			local spellName = GetSpellInfo(72295)
			scheduled = true
			self:ScheduleTimer(scanTargetCustom, 0.2, spellName)
		end
	end
--custom END

function mod:UNIT_HEALTH(_, unit)
	if p2 and p3 then
		self:UnregisterEvent("UNIT_HEALTH")
		return
	end
	if UnitName(unit) == self.displayName then
		local hp = UnitHealth(unit) / UnitHealthMax(unit) * 100
		if hp <= 83 and not p2 then
			self:Message("phase", "Positive", nil, L["phase_warning"]:format(2), "achievement_boss_profputricide")
			p2 = true
		elseif hp <= 37 and not p3 then
			self:Message("phase", "Positive", nil, L["phase_warning"]:format(3), "achievement_boss_profputricide")
			p3 = true
		end
	end
end

function mod:ChasedByRedOoze(player, spellId)
	self:SendMessage("BigWigs_StopBar", self, barText)
	self:TargetMessage(72455, player, "Personal", nil, L["blight_message"])
	self:Whisper(72455, player, L["blight_message"])
	if UnitIsUnit(player, "player") then
		self:FlashShake(72455)
	end
	barText = CL.other:format(L["blight_message"], player)
	self:Bar(72455, barText, 20, spellId)
end

function mod:RedOozeDeath()
	self:SendMessage("BigWigs_StopBar", self, barText)
end

function mod:StunnedByGreenOoze(player, spellId)
	self:TargetMessage(70447, player, "Personal", nil, L["violation_message"])
	self:PrimaryIcon(70447, player)
end

function mod:Experiment(_, spellId)
	self:Message(71966, "Attention", "Alert", L["experiment_message"])
	self:Bar(71966, L["experiment_bar"], 38, spellId)
end

do
	local slimeScheduled = nil
	local function slime()
		slimeScheduled = nil
	end
	function mod:Slime(player)
		if not slimeScheduled then
			slimeScheduled = true
			self:Message(70341, "Urgent", nil, L["slime_message"])
			self:Bar(70341, L["slime_bar"], 30, 70341)
			self:ScheduleTimer(slime, 0.3)
		end
	end
end

function mod:GasBomb(_, spellId)
	self:Message(71255, "Urgent", nil, L["gasbomb_message"])
	self:Bar(71255, L["gasbomb_bar"], 37, spellId)
end

do
	local scheduled = nil
	local function scanTarget(spellName)
		scheduled = nil
		local bossId = mod:GetUnitIdByGUID(36678)
		if not bossId then return end
		local target = UnitName(bossId .. "target")
		if target then
			if UnitIsUnit(target, "player") then
				mod:FlashShake(72295)
				mod:Say(72295, L["ball_say"])
			end
			mod:TargetMessage(72295, target, "Attention")
		end
	end
	function mod:BouncingGooBall(_, spellId,...)
		if not scheduled then
			scheduled = true
			self:ScheduleTimer(scanTarget, 0.2, spellName)
			if self:IsDifficulty("hc") then
				self:Bar(72295, L["ball_bar"], 20, spellId)
			else
				self:Bar(72295, L["ball_bar"], 25, spellId)
			end
		end
	end
end

do
	local oldPlagueBar = nil
	local unboundPlagueStart = 0
	function mod:UnboundPlague(player, spellId, _, _, spellName)
		local expirationTime = select(7, UnitDebuff(player, spellName))
		if expirationTime then
			if oldPlagueBar then self:SendMessage("BigWigs_StopBar", self, oldPlagueBar) end
			oldPlagueBar = L["unbound_bar"]:format(player)
			self:Bar(72855, oldPlagueBar, expirationTime - GetTime(), spellId)
		end
		self:TargetMessage(72855, player, "Personal", "Alert")
		self:SecondaryIcon(72855, player)
		if UnitIsUnit(player, "player") then
			self:OpenProximity(10, 72855)
			self:FlashShake(72855)
		else
			self:CloseProximity()
		end
		if unboundPlagueStart - GetTime() <= 0 then
			self:ScheduleTimer(self.OpenProximity, 115, 10, 72855)
			self:Bar(72855, L["unboundplague_bar"], 120, 72855)
			unboundPlagueStart = GetTime() + 90
		end
	end
end

