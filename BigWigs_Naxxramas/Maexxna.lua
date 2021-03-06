--------------------------------------------------------------------------------
-- Module declaration
--

local mod = BigWigs:NewBoss("Maexxna", "Naxxramas")
if not mod then return end
mod:RegisterEnableMob(15952)
mod.toggleOptions = {29484, 28622, 54123, "bosskill"}

--------------------------------------------------------------------------------
-- Locals
--

local inCocoon = mod:NewTargetList()
local enrageannounced = nil

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.webspraywarn30sec = "Cocoons in 10 sec"
	L.webspraywarn20sec = "Cocoons! Spiders in 10 sec!"
	L.webspraywarn10sec = "Spiders! Spray in 10 sec!"
	L.webspraywarn5sec = "WEB SPRAY in 5 seconds!"
	L.webspraywarn = "Web Spray! 40 sec until next!"
	L.enragewarn = "Frenzy - SQUISH SQUISH SQUISH!"
	L.enragesoonwarn = "Frenzy Soon - Bugsquatters out!"

	L.webspraybar = "Web Spray"
	L.cocoonbar = "Cocoons"
	L.spiderbar = "Spiders"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Cocoon", 28622)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 54123, 54124) --Norm/Heroic
	self:Log("SPELL_CAST_SUCCESS", "Spray", 29484, 54125)
	self:Death("Win", 15952)

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:Spray()
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local handle = nil
	local function cocoonWarn()
		mod:TargetMessage(28622, inCocoon, "Important", "Alert", L["cocoonbar"], 745)
		handle = nil
	end

	function mod:Cocoon(player)
		inCocoon[#inCocoon + 1] = player
		self:CancelTimer(handle, true)
		handle = self:ScheduleTimer(cocoonWarn, 0.3)
	end
end

function mod:Spray()
	self:Message(29484, "Important", nil, L["webspraywarn"], 54125)
	self:DelayedMessage(29484, 10, "Attention", L["webspraywarn30sec"])
	self:DelayedMessage(29484, 20, "Attention", L["webspraywarn20sec"])
	self:DelayedMessage(29484, 30, "Attention", L["webspraywarn10sec"])
	self:DelayedMessage(29484, 35, "Attention", L["webspraywarn5sec"])
	self:Bar(29484, L["webspraybar"], 40, 54125)

	self:Bar(28622, L["cocoonbar"], 20, 745)

	self:Bar(29484, L["spiderbar"], 30, 17332)
end

function mod:Frenzy(_, spellId)
	self:Message(54123, "Attention", "Alarm", L["enragewarn"])
end

function mod:UNIT_HEALTH(event, msg)
	if UnitName(msg) == mod.displayName then
		local health = UnitHealth(msg) / UnitHealthMax(msg) * 100
		if health > 30 and health <= 33 and not enrageannounced then
			self:Message(54123, "Important", nil, L["enragesoonwarn"])
			enrageannounced = true
		elseif health > 40 and enrageannounced then
			enrageannounced = nil
		end
	end
end

