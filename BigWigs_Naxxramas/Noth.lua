--------------------------------------------------------------------------------
-- Module declaration
--

local mod = BigWigs:NewBoss("Noth the Plaguebringer", "Naxxramas")
if not mod then return end
mod:RegisterEnableMob(15954)
mod.toggleOptions = {"blink", "teleport", 29213, "wave", "bosskill"}

--------------------------------------------------------------------------------
-- Locals
--

local timeroom = 90
local timebalcony = 70
local cursetime = 55
local wave1time = 10
local wave2time = 41

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.starttrigger1 = "Die, trespasser!"
	L.starttrigger2 = "Glory to the master!"
	L.starttrigger3 = "Your life is forfeit!"
	L.startwarn = "Noth the Plaguebringer engaged! 90 sec till teleport"

	L.blink = "Blink"
	L.blink_icon = 29208
	L.blink_desc = "Warnings when Noth blinks."
	L.blinktrigger = "%s blinks away!"
	L.blinkwarn = "Blink!"
	L.blinkwarn2 = "Blink in ~5 sec!"
	L.blinkbar = "Blink"

	L.teleport = "Teleport"
	L.teleport_icon = "Spell_Magic_LesserInvisibilty"
	L.teleport_desc = "Warnings and bars for teleport."
	L.teleportbar = "Teleport!"
	L.backbar = "Back in room!"
	L.teleportwarn = "Teleport! He's on the balcony!"
	L.teleportwarn2 = "Teleport in 10 sec!"
	L.backwarn = "He's back in the room for %d sec!"
	L.backwarn2 = "10 sec until he's back in the room!"

	L.curseexplosion = "Curse explosion!"
	L.cursewarn = "Curse! next in ~55 sec"
	L.curse10secwarn = "Curse in ~10 sec"
	L.cursebar = "Next Curse"

	L.wave = "Waves"
	L.wave_icon = "Spell_ChargePositive"
	L.wave_desc = "Alerts for the different waves."
	L.addtrigger = "Rise, my soldiers! Rise and fight once more!"
	L.wave1bar = "Wave 1"
	L.wave2bar = "Wave 2"
	L.wave2_message = "Wave 2 in 10 sec"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "Curse", 29213, 54835)

	self:Yell("Engage", L["starttrigger1"], L["starttrigger2"], L["starttrigger3"])
	self:Emote("Blink", L["blinktrigger"])

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:Death("Win", 15954)
end

function mod:OnEngage()
	timeroom = 90
	timebalcony = 70
	cursetime = 55
	wave1time = 10
	wave2time = 41

	self:Message("teleport", "Important", nil, L["startwarn"], false)
	self:DelayedMessage("teleport", timeroom - 10, "Urgent", L["teleportwarn2"])
	self:Bar("teleport", L["teleportbar"], timeroom, L.teleport_icon)
	if GetRaidDifficulty() == 2 then
		self:DelayedMessage("blink", 25, "Attention", L["blinkwarn2"])
		self:Bar("blink", L["blinkbar"], 30, L.blink_icon)
	end
	self:ScheduleTimer("TeleportToBalcony", timeroom)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Curse(_, spellId)
	self:Message(29213, "Important", "Alarm", L["cursewarn"])
	self:DelayedMessage(29213, cursetime - 10, "Urgent", L["curse10secwarn"])
	self:Bar(29213, L["cursebar"], cursetime, spellId)
	self:Bar(29213, L["curseexplosion"], 10, spellId)
end

function mod:Blink()
	self:Message("blink", "Important", nil, L["blinkwarn"], L.blink_icon)
	self:DelayedMessage("blink", 34, "Attention", L["blinkwarn2"])
	self:Bar("blink", L["blinkbar"], 39, L.blink_icon)
end

function mod:TeleportToBalcony()
	if timeroom == 90 then
		timeroom = 110
	elseif timeroom == 110 then
		timeroom = 180
	end

	self:SendMessage("BigWigs_StopBar", self, L["blinkbar"])
	self:SendMessage("BigWigs_StopBar", self, L["cursebar"])

	self:Message("teleport", "Important", nil, L["teleportwarn"], false)
	self:Bar("teleport", L["backbar"], timebalcony, L.teleport_icon)
	self:DelayedMessage("teleport", timebalcony - 10, "Urgent", L["backwarn2"])

	self:Bar("wave", L["wave1bar"], wave1time, L.wave_icon)
	self:Bar("wave", L["wave2bar"], wave2time, L.wave_icon)
	self:DelayedMessage("wave", wave2time - 10, "Urgent", L["wave2_message"])

	self:ScheduleTimer("TeleportToRoom", timebalcony)
	wave2time = wave2time + 15
end

function mod:TeleportToRoom()
	if timebalcony == 70 then
		timebalcony = 95
	elseif timebalcony == 95 then
		timebalcony = 120
	end

	self:Message("teleport", "Important", nil, L["backwarn"]:format(timeroom), false)
	self:Bar("teleport", L["teleportbar"], timeroom, L.teleport_icon)
	self:DelayedMessage("teleport", timeroom - 10, "Urgent", L["teleportwarn2"])
	self:ScheduleTimer("TeleportToBalcony", timeroom)
end

