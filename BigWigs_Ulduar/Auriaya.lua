--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Auriaya", "Ulduar")
if not mod then return end
mod:RegisterEnableMob(33515)
--Feral Defender = 34035
mod.toggleOptions = { 64386, 64389, 64396, 64422, "defender", "berserk", "bosskill" }
mod.order = 8

--------------------------------------------------------------------------------
-- Locals
--

local count = 9

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_trigger = "Some things are better left alone!"

	L.fear_warning = "Fear soon!"
	L.fear_message = "Casting Fear!"
	L.fear_bar = "~Fear"

	L.swarm_message = "Swarm"
	L.swarm_bar = "~Swarm"

	L.defender = "Feral Defender"
	L.defender_icon = 64455
	L.defender_desc = "Warn for Feral Defender lives."
	L.defender_message = "Defender up %d/9!"

	L.sonic_bar = "~Sonic"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Sonic", 64422, 64688)
	self:Log("SPELL_CAST_START", "Fear", 64386)
	self:Log("SPELL_CAST_START", "Sentinel", 64389, 64678)
	self:Log("SPELL_AURA_APPLIED", "Swarm", 64396)
	self:Log("SPELL_AURA_APPLIED", "Defender", 64455)
	self:Log("SPELL_AURA_REMOVED_DOSE", "DefenderKill", 64455)
	self:Death("Win", 33515)

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:Yell("Engage", L["engage_trigger"])
end

function mod:OnEngage()
	count = 9
	self:Bar("defender", L["defender_message"]:format(count), 60, L.defender_icon)
	self:Bar(64386, L["fear_bar"], 32, 64386)
	self:DelayedMessage(64386, 32, "Attention", L["fear_warning"])
	self:Berserk(600)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Sonic(_, spellId, _, _, spellName)
	self:Message(64422, "Attention")
	self:Bar(64422, L["sonic_bar"], 28, spellId)
end

function mod:Defender(_, spellId)
	self:Message("defender", "Attention", nil, L["defender_message"]:format(count), spellId)
end

function mod:DefenderKill(_, spellId)
	count = count - 1
	self:Bar("defender", L["defender_message"]:format(count), 34, spellId)
end

function mod:Swarm(player, spellId)
	self:TargetMessage(64396, player, "Attention", nil, L["swarm_message"])
	self:Bar(64396, L["swarm_bar"], 37, spellId)
end

function mod:Fear(_, spellId)
	self:Message(64386, "Urgent", nil, L["fear_message"])
	self:Bar(64386, L["fear_bar"], 35, spellId)
	self:DelayedMessage(64386, 32, "Attention", L["fear_warning"])
end

function mod:Sentinel(_, spellId, _, _, spellName)
	self:Message(64389, "Important")
end

