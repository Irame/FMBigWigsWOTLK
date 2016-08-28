--------------------------------------------------------------------------------
-- Module declaration
--

local mod = BigWigs:NewBoss("Heigan the Unclean", "Naxxramas")
if not mod then return end
mod:RegisterEnableMob(15936)
mod.toggleOptions = {"engage", "teleport", "bosskill"}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.starttrigger = "You are mine now."
	L.starttrigger2 = "You... are next."
	L.starttrigger3 = "I see you..."

	L.engage = "Engage"
	L.engage_icon = ""
	L.engage_desc = "Warn when Heigan is engaged."
	L.engage_message = "Heigan the Unclean engaged! 90 sec to teleport!"

	L.teleport = "Teleport"
	L.teleport_icon = "Spell_Arcane_Blink"
	L.teleport_desc = "Warn for Teleports."
	L.teleport_trigger = "The end is upon you."
	L.teleport_1min_message = "Teleport in 1 min"
	L.teleport_30sec_message = "Teleport in 30 sec"
	L.teleport_10sec_message = "Teleport in 10 sec!"
	L.on_platform_message = "Teleport! On platform for 45 sec!"

	L.to_floor_30sec_message = "Back in 30 sec"
	L.to_floor_10sec_message = "Back in 10 sec!"
	L.on_floor_message = "Back on the floor! 90 sec to next teleport!"

	L.teleport_bar = "Teleport!"
	L.back_bar = "Back on the floor!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Yell("Engage", L["starttrigger"], L["starttrigger2"], L["starttrigger3"])
	self:Yell("Teleport", L["teleport_trigger"])
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:Death("Win", 15936)
end

function mod:OnEngage()
	self:Message("engage", "Important", nil, L["engage_message"], L.engage_icon)
	self:Bar("teleport", L["teleport_bar"], 90, "Spell_Arcane_Blink")
	self:DelayedMessage("teleport", 30, "Attention", L["teleport_1min_message"])
	self:DelayedMessage("teleport", 60, "Urgent", L["teleport_30sec_message"])
	self:DelayedMessage("teleport", 80, "Important", L["teleport_10sec_message"])
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local function backToRoom()
	mod:Message("teleport", "Attention", nil, L["on_floor_message"], false)
	mod:DelayedMessage("teleport", 60, "Urgent", L["teleport_30sec_message"])
	mod:DelayedMessage("teleport", 80, "Important", L["teleport_10sec_message"])
	mod:Bar("teleport", L["teleport_bar"], 90, "Spell_Arcane_Blink")
end

function mod:Teleport()
	self:ScheduleTimer(backToRoom, 45)
	self:Message("teleport", "Attention", nil, L["on_platform_message"], false)
	self:DelayedMessage("teleport", 15, "Urgent", L["to_floor_30sec_message"])
	self:DelayedMessage("teleport", 35, "Important", L["to_floor_10sec_message"])
	self:Bar("teleport", L["back_bar"], 45, "Spell_Magic_LesserInvisibilty")
end

