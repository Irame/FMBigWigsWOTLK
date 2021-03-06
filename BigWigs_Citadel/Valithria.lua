--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Valithria Dreamwalker", "Icecrown Citadel")
if not mod then return end
mod:RegisterEnableMob(36789, 37868, 36791, 37934, 37886, 37950, 37985)
mod.toggleOptions = {71730, {71741, "FLASHSHAKE"}, "suppresser", {"blazing", "ICON"}, "portal", "berserk", "bosskill"}
mod.optionHeaders = {
	[71730] = "normal",
	berserk = "heroic",
	bosskill = "general",
}
mod.order = 41

--------------------------------------------------------------------------------
-- Locals
--

local blazingTimers = {60, 51.5, 53.5, 41, 41, 35, 33}
local blazingCount, blazingRepeater, portalCount = 1, nil, 1

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_trigger = "Intruders have breached the inner sanctum. Hasten the destruction of the green dragon!"

	L.portal = "Nightmare Portals"
	L.portal_icon = 72482
	L.portal_desc = "Warns when Valithria opens portals."
	L.portal_message = "Portals up!"
	L.portal_bar = "Portals inc"
	L.portalcd_message = "Portals %d up in 14 sec!"
	L.portalcd_bar = "Next Portals %d"
	L.portal_trigger = "I have opened a portal into the Dream. Your salvation lies within, heroes..."

	L.manavoid_message = "Mana Void on YOU!"

	L.suppresser = "Suppressers spawn"
	L.suppresser_icon = 70588
	L.suppresser_desc = "Warns when a pack of Suppressers spawn."
	L.suppresser_message = "~Suppressers"

	L.blazing = "Blazing Skeleton"
	L.blazing_icon = 71730
	L.blazing_desc = "Blazing Skeleton |cffff0000estimated|r respawn timer. This timer may be inaccurate, use only as a rough guide."
	L.blazing_warning = "Blazing Skeleton soon!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	if UnitPowerType("player") == 0 then
		self:Log("SPELL_DAMAGE", "ManaVoid", 71086, 71179, 71743, 72030) --10/25
		self:Log("SPELL_MISSED", "ManaVoid", 71086, 71179, 71743, 72030)
	end
	self:Log("SPELL_AURA_APPLIED", "LayWaste", 69325, 71730) -- 10/25
	self:Log("SPELL_AURA_REMOVED", "LayWasteRemoved", 69325, 71730)
	self:Log("SPELL_CAST_START", "WinSoon", 71189)

	self:Yell("Portal", L["portal_trigger"])
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:Yell("Engage", L["engage_trigger"])
end

do
	local function scanTarget()
		local unitId = mod:GetUnitIdByGUID(36791)
		if not unitId then return end
		mod:PrimaryIcon("blazing", unitId)
		mod:CancelTimer(blazingRepeater)
		blazingRepeater = nil
	end
	local function suppresserSpawn(time)
		mod:Bar("suppresser", L["suppresser_message"], time, L.suppresser_icon)
		mod:ScheduleTimer(suppresserSpawn, time, time)
	end
	local function blazingSpawn()
		if not blazingTimers[blazingCount] then return end
		mod:Bar("blazing", L["blazing"], blazingTimers[blazingCount], L.blazing_icon)
		mod:ScheduleTimer(blazingSpawn, blazingTimers[blazingCount])
		mod:DelayedMessage("blazing", blazingTimers[blazingCount] - 5, "Positive", L["blazing_warning"])
		blazingCount = blazingCount + 1
		if blazingRepeater or (not IsRaidLeader() and not IsRaidOfficer()) then return end
		if bit.band(mod.db.profile.blazing, BigWigs.C.ICON) == BigWigs.C.ICON then
			blazingRepeater = mod:ScheduleRepeatingTimer(scanTarget, 0.5)
		end
	end
	function mod:OnEngage(diff)
		portalCount = 1
		if diff > 2 then
			self:Bar("suppresser", L["suppresser_message"], 14, L.suppresser_icon)
			self:Bar("portal", L["portalcd_bar"]:format(portalCount), 46, L.portal_icon)
			self:ScheduleTimer(suppresserSpawn, 14, 31)
			self:Berserk(420)
		else
			self:Bar("suppresser", L["suppresser_message"], 29, L.suppresser_icon)
			self:Bar("portal", L["portalcd_bar"]:format(portalCount), 46, L.portal_icon)
			self:ScheduleTimer(suppresserSpawn, 29, 58)
		end
		self:ScheduleTimer(blazingSpawn, 50)
		self:Bar("blazing", L["blazing"], 50, L.blazing_icon)
		self:DelayedMessage("blazing", 45, "Positive", L["blazing_warning"])
		blazingCount = 1
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:LayWaste(_, spellId, _, _, spellName)
	self:Message(71730, "Attention")
	self:Bar(71730, spellName, 12, spellId)
end

function mod:LayWasteRemoved(_, _, _, _, spellName)
	self:SendMessage("BigWigs_StopBar", self, spellName)
end

function mod:Portal()
	-- 46 sec cd until initial positioning, +14 sec until 'real' spawn.
	self:Message("portal", "Important", nil, L["portalcd_message"]:format(portalCount), L.portal_icon)
	self:Bar("portal", L["portal_bar"], 14, L.portal_icon)
	self:DelayedMessage("portal", 14, "Important", L["portal_message"])
	portalCount = portalCount + 1
	self:Bar("portal", L["portalcd_bar"]:format(portalCount), 46, L.portal_icon)
end

do
	local t = 0
	function mod:ManaVoid(player, spellId)
		if (GetTime()-t > 2) and UnitIsUnit(player, "player") then
			t = GetTime()
			self:LocalMessage(71741, "Personal", "Alarm", L["manavoid_message"])
			self:FlashShake(71741)
		end
	end
end

function mod:WinSoon(...)
	self:Win()
	self:ScheduleTimer(function() if mod and mod:IsEnabled() then mod:Disable() end end, 10)
end

