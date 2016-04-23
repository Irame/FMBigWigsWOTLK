--------------------------------------------------------------------------------
-- Module Declaration
--
local mod = BigWigs:NewBoss("Gruul the Dragonkiller", "Gruul's Lair")
if not mod then return end
--Prince Valanar, Prince Keleseth, Prince Taldaram
mod:RegisterEnableMob(19044)
mod.toggleOptions = {33525, 33654, {36240, "FLASHSHAKE"}, 36297, 36300, "berserk", "proximity", "bosskill"}
local CL = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Common")
mod.optionHeaders = {
	[33525] = "Gruul the Dragonkiller",
	berserk = "general"
}

--------------------------------------------------------------------------------
-- Locals
--
local lastReverberation = 0

--------------------------------------------------------------------------------
--  Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_trigger = "Kommt und sterbt."
	
	L.cooldown_bars = "~%s"
	
	L.shatter_message = "Shatter"
	L.cave_in_message = "Cave In!"
	L.growth_message = "Growth %dx"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "GroundSlam", 33525)
	--self:Log("SPELL_CAST_START", "Shatter", 33654)
	self:Log("SPELL_AURA_APPLIED", "CaveIn", 36240)
	self:Log("SPELL_PERIODIC_DAMAGE", "CaveIn", 36240)
	self:Log("SPELL_AURA_APPLIED", "Reverberation", 36297)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Growth", 36300)
	
	
	self:Yell("Engage", L["engage_trigger"])
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")

	self:Death("Win", 19044)
end

function mod:OnEngage()
	print("OnEngage()")
	deaths = 0
	--self:Berserk(410, true)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:GroundSlam(_, spellId, _, _, spellName)
	self:Message(33525, "Important", "Long")
	self:Bar(33525, L["cooldown_bars"]:format(spellName), 85, spellId)
	self:Bar(33654, L["cooldown_bars"]:format(L["shatter_message"]), 11, 33654)
end

function mod:CaveIn(player , spellId, _, _, spellName)
	if UnitIsUnit(player,"player") then
		self:LocalMessage(36240, "Personal", "Alarm", L["cave_in_message"])
		self:FlashShake(36240)
	end
end

function mod:Reverberation(_, spellId, _, _, spellName)
	local ct = GetTime()
	if ct - lastReverberation < 2 then return end
	lastReverberation = ct
	self:Message(36297, "Attention")
	self:Bar(36297, L["cooldown_bars"]:format(spellName), 20, spellId)
end

function mod:Growth(_, spellId, _, _, spellName, stack)
	print(spellName, stack, spellId)
	if stack > 7 then
		self:Message(36300, "Urgent", nil, L["growth_message"]:format(stack))
		self:Bar(36300, L["cooldown_bars"]:format(spellName), 30, spellId)
	end
end


