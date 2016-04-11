--------------------------------------------------------------------------------
-- Module declaration
--

local mod = BigWigs:NewBoss("Gluth", "Naxxramas")
if not mod then return end
mod:RegisterEnableMob(15932)
mod.toggleOptions = {28371, 54426, "berserk", "bosskill"}

--------------------------------------------------------------------------------
-- Locals
--

local enrageTime = 420

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.startwarn = "Gluth engaged, ~105 sec to decimate!"

	L.decimatesoonwarn = "Decimate Soon!"
	L.decimatebartext = "~Decimate Zombies"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "Frenzy", 28371, 54427)
	self:Log("SPELL_DAMAGE", "Decimate", 28375, 54426)
	self:Log("SPELL_MISSED", "Decimate", 28375, 54426)
	self:Death("Win", 15932)

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
end

function mod:OnEngage(diff)
	enrageTime = diff == 1 and 480 or 420
	self:Message(54426, "Attention", nil, L["startwarn"])
	self:Bar(54426, L["decimatebartext"], 105, 54426)
	self:DelayedMessage(54426, 100, "Urgent", L["decimatesoonwarn"])
	self:Berserk(enrageTime)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Frenzy(_, spellId, _, _, spellName)
	self:Message(28371, "Important")
end

local last = 0
function mod:Decimate(_, spellId, _, _, spellName)
	local time = GetTime()
	if (time - last) > 5 then
		last = time
		self:Message(54426, "Attention", "Alert")
		self:Bar(54426, L["decimatebartext"], 105, spellId)
		self:DelayedMessage(54426, 100, "Urgent", L["decimatesoonwarn"])
	end
end

