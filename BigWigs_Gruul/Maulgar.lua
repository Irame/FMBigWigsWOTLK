--------------------------------------------------------------------------------
-- Module Declaration
--
local mod = BigWigs:NewBoss("High King Maulgar", "Gruul's Lair")
if not mod then return end
--Prince Valanar, Prince Keleseth, Prince Taldaram
mod:RegisterEnableMob(18831, 18832, 18834, 18835, 18836)
mod.toggleOptions = {33238, {33239, "FLASHSHAKE"}, 26561, 16508, 33061, 33054, 33131, 33237, 33173, 33152, "berserk", "proximity", "bosskill"}
local CL = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Common")
mod.optionHeaders = {
	[33238] = "High King Maulgar",
	[33061] = "Krosh Firehand",
	[33131] = "Olm the Summoner",
	[33237] = "Kiggler the Crazed",
	[33152] = "Blindeye the Seer",
	berserk = "general"
}

--------------------------------------------------------------------------------
-- Locals
--

local deaths = 0

--------------------------------------------------------------------------------
--  Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.cooldown_bars = "~%s"
	
	L.whirlwind_hit_message = "Whirlwind"
	L.berserker_charge_message = "Charge"
	L.intimidating_roar_message = "Roar"
	L.summon_message = "Summon Deamon"
	L.greater_polymorph_message = "Polimorph"
	L.prayer_of_healing_message = "Prayer"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	print("OnBossEnable()")
	self:Log("SPELL_CAST_SUCCESS", "Whirlwind", 33238)
	self:Log("SPELL_DAMAGE", "WhirlwindHit", 33239)
	self:Log("SPELL_CAST_SUCCESS", "BerserkerCharge", 26561)
	self:Log("SPELL_CAST_SUCCESS", "IntimidatingRoar", 16508)
	self:Log("SPELL_CAST_SUCCESS", "BlastWave", 33061)
	self:Log("SPELL_CAST_SUCCESS", "SpellShield", 33054)
	self:Log("SPELL_CAST_START", "SummonWildFelhunter", 33131)
	self:Log("SPELL_CAST_SUCCESS", "ArcaneExplosion", 33237)
	self:Log("SPELL_AURA_APPLIED", "GreaterPolymorph", 33173)
	self:Log("SPELL_CAST_START", "PrayerOfHealing", 33152)
	
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")

	self:Death("Deaths", 18831, 18832, 18834, 18835, 18836)
	deaths = 0
end

function mod:OnEngage()
	print("OnEngage()")
	deaths = 0
	--self:Berserk(410, true)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Whirlwind(_, spellId, _, _, spellName)
	self:Message(33238, spellName, "Important", spellId, "Alert")
	self:Bar(33238, L["cooldown_bars"]:format(spellName), 55, spellId)
end

function mod:WhirlwindHit(player, spellId, _, _, spellName)
	if UnitIsUnit(player, "player") then
		self:LocalMessage(33239, L["whirlwind_hit_message"], "Personal", spellId, "Alert")
		self:FlashShake(33239)
	end
end

function mod:BerserkerCharge(player , spellId, _, _, spellName)
	self:TargetMessage(26561, L["berserker_charge_message"], player, "Attention", spellId)
	self:Bar(26561, L["cooldown_bars"]:format(L["berserker_charge_message"]), 20, spellId)
end

function mod:IntimidatingRoar(_, spellId, _, _, spellName)
	self:Message(16508, L["intimidating_roar_message"], "Attention", spellId)
	self:Bar(16508, L["cooldown_bars"]:format(L["intimidating_roar_message"]), 45, spellId)
end

function mod:BlastWave(_, spellId, _, _, spellName)
	self:Message(33061, spellName, "Attention", spellId)
	self:Bar(33061, L["cooldown_bars"]:format(spellName), 60, spellId)
end

function mod:SpellShield(_, spellId, _, _, spellName)
	self:Message(33054, spellName, "Attention", spellId, "Info")
	self:Bar(33054, L["cooldown_bars"]:format(spellName), 30, spellId)
end

function mod:SummonWildFelhunter(_, spellId, _, _, spellName)
	self:Message(33131, L["summon_message"], "Attention", spellId, "Info")
	self:Bar(33131, L["cooldown_bars"]:format(L["summon_message"]), 30, spellId)
end

function mod:ArcaneExplosion(_, spellId, _, _, spellName)
	self:Message(33237, spellName, "Attention", spellId)
	self:Bar(33237, L["cooldown_bars"]:format(spellName), 30, spellId)
end

function mod:GreaterPolymorph(player, spellId, _, _, spellName)
	self:TargetMessage(33173, L["greater_polymorph_message"], player, "Attention", spellId, "Info")
end

function mod:PrayerOfHealing(_, spellId, _, _, spellName)
	self:Message(33131, L["prayer_of_healing_message"], "Attention", spellId, "Info")
	self:Bar(33131, L["cooldown_bars"]:format(L["prayer_of_healing_message"]), 20, spellId)
end


do
	function mod:Deaths(unit)
		print("Death of: " .. unit,deaths)
		deaths = deaths + 1
		if deaths == 5 then
			self:Win()
		end
	end
end

