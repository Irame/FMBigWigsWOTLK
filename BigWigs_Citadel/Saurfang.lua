--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Deathbringer Saurfang", "Icecrown Citadel")
if not mod then return end
-- Deathbringer Saurfang, Muradin, Marine, Overlord Saurfang, Kor'kron Reaver
mod:RegisterEnableMob(37813, 37200, 37830, 37187, 37920)
mod.toggleOptions = {"adds", 72378, 72410, 72385, {72293, "WHISPER", "ICON", "FLASHSHAKE", "HEALTHBAR"}, 72737, "proximity", "berserk", "bosskill"}
mod.order = 15

--------------------------------------------------------------------------------
-- Locals
--

local bbTargets = mod:NewTargetList()
local killed = nil
local count = 1

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.adds = "Blood Beasts"
	L.adds_desc = "Shows a timer and messages for when Blood Beasts spawn."
	L.adds_warning = "Blood Beasts in 5 sec!"
	L.adds_message = "Blood Beasts!"
	L.adds_bar = "Next Blood Beasts"
	
	L.nova_warning = "Blood Nova in 5 sec!"
	L.nova_message = "Blood Nova!"
	L.nova_bar = "~Next Blood Nova"

	L.rune_bar = "~Next Rune"

	L.mark = "Mark %d"

	L.engage_trigger = "BY THE MIGHT OF THE LICH KING!"
	L.warmup_alliance = "Let's get a move on then! Move ou..."
	L.warmup_horde = "Kor'kron, move out! Champions, watch your backs. The Scourge have been..."
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "Adds", 72173) --10man Id's: 72172, 72173; 25man Id's: 72172, 72173, 72356, 72357, 72358
	self:Log("SPELL_AURA_APPLIED", "RuneofBlood", 72410)
	self:Log("SPELL_AURA_APPLIED", "BoilingBlood", 72385, 72442, 72441, 72443) --10/25
	self:Log("SPELL_AURA_APPLIED", "Mark", 72293)
	self:Log("SPELL_CAST_START", "BloodNova", 73058, 72378)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 72737)
	self:Death("Deaths", 37813)

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:Yell("Engage", L["engage_trigger"])
	self:Yell("Warmup", L["warmup_alliance"], L["warmup_horde"])
end

function mod:OnEngage()
	self:OpenProximity(11,72378)
	if self:IsDifficulty("hc") then
		self:Berserk(360)
	else
		self:Berserk(480)
	end
	self:DelayedMessage("adds", 25, L["adds_warning"], "Urgent")
	self:Bar("adds", L["adds_bar"], 40, 72173)
	self:HealthBar(72293, 37813, 3, "achievement_boss_saurfang")
	self:Bar(72378, L["nova_bar"], 17, 72378)
	self:Bar(72410, L["rune_bar"], 20, 72410)
	count = 1
end

function mod:Warmup(msg)
	self:OpenProximity(11,72378)
	if msg == L["warmup_alliance"] then
		self:Bar("adds", self.displayName, 44, "achievement_boss_saurfang")
	else
		self:Bar("adds", self.displayName, 99, "achievement_boss_saurfang")
	end
end

function mod:VerifyEnable()
	SetMapToCurrentZone()
	if not killed and GetCurrentMapDungeonLevel() == 3 then return true end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local scheduled = nil
	local function boilingWarn(spellName)
		mod:TargetMessage(72385, bbTargets, "Urgent")
		scheduled = nil
	end
	function mod:BoilingBlood(player, spellId, _, _, spellName)
		bbTargets[#bbTargets + 1] = player
		if not scheduled then
			scheduled = true
			self:ScheduleTimer(boilingWarn, 0.3, spellName)
		end
	end
end

function mod:BloodNova(_, spellId)
	self:Message(72378, "Attention", "Alarm", L["nova_message"])
	self:Bar(72378, L["nova_bar"], 20, spellId, 5)
end

function mod:Adds(_, spellId)
	self:Message("adds", "Positive", "Alarm", L["adds_message"], spellId)
	self:DelayedMessage("adds", 35, L["adds_warning"], "Urgent")
	self:Bar("adds", L["adds_bar"], 40, spellId)
end

function mod:RuneofBlood(player, spellId, _, _, spellName)
	self:TargetMessage(72410, player, "Attention")
	self:Bar(72410, L["rune_bar"], 20, spellId, 5)
end

function mod:Mark(player, spellId, _, _, spellName)
	self:TargetMessage(72293, player, "Attention", "Alert", L["mark"]:format(count))
	count = count + 1
	self:Whisper(72293, player, spellName)
	self:PrimaryIcon(72293, player)
	if UnitIsUnit(player, "player") then self:FlashShake(72293) end
end

function mod:Frenzy(_, spellId, _, _, spellName)
	self:Message(72737, "Important", "Long")
end

function mod:Deaths()
	killed = true
	self:Win()
end

