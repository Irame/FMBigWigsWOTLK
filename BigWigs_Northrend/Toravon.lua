--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Toravon the Ice Watcher", "Vault of Archavon")
if not mod then return end
mod.otherMenu = "Northrend"
mod:RegisterEnableMob(38433)
mod.toggleOptions = {72034, 72091, 72004, 72090, "bosskill"}

--------------------------------------------------------------------------------
-- Locals
--

local count = 1
local freezeTargets = mod:NewTargetList()

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.whiteout_bar = "Whiteout %d"
	L.whiteout_message = "Whiteout %d soon!"


	L.freeze_message = "Freeze"

	L.orb_bar = "Next Orb"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Whiteout", 72034, 72096)
	self:Log("SPELL_CAST_START", "Orbs", 72091, 72095)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Frostbite", 72004, 72098, 72121)
	self:Log("SPELL_AURA_APPLIED", "Freeze", 72090, 72104)
	self:Death("Win", 38433)

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
end

function mod:OnEngage()
	count = 1
	self:Bar(72091, L["orb_bar"], 15, 72091)
	self:Bar(72034, L["whiteout_bar"]:format(count), 30, 72034)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Whiteout(_, spellId, _, _, spellName)
	self:Message(72034, "Positive")
	count = count + 1
	self:Bar(72034, L["whiteout_bar"]:format(count), 38, spellId)
	self:DelayedMessage(72034, 33, "Attention", L["whiteout_message"]:format(count))
end

function mod:Orbs(_, spellId, _, _, spellName)
	self:Message(72091, "Important")
	self:Bar(72091, L["orb_bar"], 30, spellId)
end

function mod:Frostbite(player, spellId, _, _, _, stack)
	if stack and stack > 4 then
		self:StackMessage(72004, player, stack, "Urgent")
	end
end

do
	local scheduled = nil
	local function freezeWarn()
		mod:TargetMessage(72090, freezeTargets, "Personal", nil, L["freeze_message"])
		scheduled = nil
	end
	function mod:Freeze(player)
		freezeTargets[#freezeTargets + 1] = player
		if not scheduled then
			scheduled = true
			self:ScheduleTimer(freezeWarn, 0.2)
		end
	end
end

