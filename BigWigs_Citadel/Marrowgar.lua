--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Lord Marrowgar", "Icecrown Citadel")
if not mod then return end
mod:RegisterEnableMob(36612)
mod.toggleOptions = {69076, 69057, {69138, "FLASHSHAKE"}, "bosskill"}

--------------------------------------------------------------------------------
-- Locals
--

local impaleTargets = mod:NewTargetList()

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.cleave_cd = "~Cleave Start"

	L.impale_cd = "~Next Impale"

	L.bonestorm_cd = "~Next Bone Storm"
	L.bonestorm_warning = "Bone Storm in 5 sec!"

	L.coldflame_message = "Coldflame on YOU!"

	L.engage_trigger = "The Scourge will wash over this world as a swarm of death and destruction!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_SUMMON", "Impale", 69062, 72669, 72670) --25, ??, ??
	self:Log("SPELL_CAST_START", "BonestormCast", 69076)
	self:Log("SPELL_AURA_APPLIED", "Bonestorm", 69076)
	self:Log("SPELL_AURA_APPLIED", "Coldflame", 70823, 69146, 70824, 70825) --25, ??, ??, ??
	self:Death("Win", 36612)

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:Yell("Engage", L["engage_trigger"])
end

function mod:OnEngage()
	self:Bar(69076, L["bonestorm_cd"], 48, 69076)
	self:Bar(69055, L["cleave_cd"], 10, 69055)
	self:DelayedMessage(69076, 43, L["bonestorm_warning"], "Attention")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local scheduled = nil
	local _, achievName = GetAchievementInfo(4534)
	--Remove the (25/10 player) text from name
	achievName = (achievName):gsub("%(.*%)", "")
	local function impaleWarn(spellName)
		mod:TargetMessage(69057, spellName, impaleTargets, "Urgent", 69062, "Alert")
		scheduled = nil
	end
	function mod:Impale(_, spellId, player, _, spellName)
		impaleTargets[#impaleTargets + 1] = player
		if not scheduled then
			scheduled = true
			self:ScheduleTimer(impaleWarn, 0.3, spellName)
			self:Bar(69057, achievName, 8, "achievement_boss_lordmarrowgar")
			self:Bar(69057, L["impale_cd"], 15, 69057)
		end
	end
end

function mod:Coldflame(player, spellId)
	if UnitIsUnit(player, "player") then
		self:LocalMessage(69138, L["coldflame_message"], "Personal", spellId, "Alarm")
		self:FlashShake(69138)
	end
end

local function afterTheStorm()
	if mod:GetInstanceDifficulty() == 1 or mod:GetInstanceDifficulty() == 3 then
		mod:Bar(69076, L["bonestorm_cd"], 73, 69076)
		mod:DelayedMessage(69076, 68, L["bonestorm_warning"], "Attention")
		if mod:GetInstanceDifficulty() == 3 then
			self:Bar(69057, L["impale_cd"], 10, 69057)
		end
	else
		mod:Bar(69076, L["bonestorm_cd"], 63, 69076)
		mod:DelayedMessage(69076, 58, L["bonestorm_warning"], "Attention")
		if mod:GetInstanceDifficulty() == 4 then
			self:Bar(69057, L["impale_cd"], 15, 69057)
		end
	end
	
	self:Bar(69055, L["cleave_cd"], 10, 69055)
end

function mod:Bonestorm(_, spellId, _, _, spellName)
	local time = 20
	if mod:GetInstanceDifficulty() == 2 or mod:GetInstanceDifficulty() == 4 then
		time = 30
	end
	if mod:GetInstanceDifficulty() < 3 then 
		self:SendMessage("BigWigs_StopBar", self, L["impale_cd"])
	end
	self:Bar(69076, spellName, time, spellId)
	self:ScheduleTimer(afterTheStorm, time)
end

function mod:BonestormCast(_, spellId, _, _, spellName)
	self:Message(69076, spellName, "Attention", spellId)
end

