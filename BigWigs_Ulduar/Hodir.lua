--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Hodir", "Ulduar")
if not mod then return end
mod:RegisterEnableMob(32845)
mod.toggleOptions = {{"cold", "FLASHSHAKE"}, {65123, "WHISPER", "ICON"}, 61968, 62478, "hardmode", "berserk", "bosskill"}

mod.optionHeaders = {
	cold = "normal",
	hardmode = "hard",
	berserk = "general",
}
mod.order = 9

--------------------------------------------------------------------------------
-- Locals
--

local flashFreezed = mod:NewTargetList()
local lastCold = nil
local cold = GetSpellInfo(62039)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_trigger = "You will suffer for this trespass!"

	L.cold = "Biting Cold"
	L.cold_icon = 62039
	L.cold_desc = "Warn when you have 2 or more stacks of Biting Cold."
	L.cold_message = "Biting Cold x%d!"

	L.flash_warning = "Freeze!"
	L.flash_soon = "Freeze in 5sec!"

	L.hardmode = "Hard mode"
	L.hardmode_icon = 6673
	L.hardmode_desc = "Show timer for hard mode."

	L.end_trigger = "I... I am released from his grasp... at last."
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FlashCast", 61968)
	self:Log("SPELL_AURA_APPLIED", "Flash", 61969, 61990)
	self:Log("SPELL_AURA_APPLIED", "Frozen", 62478, 63512)
	self:Log("SPELL_AURA_APPLIED", "Cloud", 65123, 65133)
	self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:Yell("Engage", L["engage_trigger"])
	self:Yell("Win", L["end_trigger"])
end

function mod:OnEngage()
	lastCold = nil
	local name = GetSpellInfo(61968)
	self:Bar(61968, name, 35, 61968)
	self:Bar("hardmode", L["hardmode"], 180, L.hardmode_icon)
	self:Berserk(480)
end

function mod:VerifyEnable(unit)
	return (UnitIsEnemy(unit, "player") and UnitCanAttack(unit, "player")) and true or false
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Cloud(player, spellId, _, _, spellName)
	self:TargetMessage(65123, player, "Positive", "Info")
	self:Whisper(65123, player, spellName)
	self:Bar(65123, spellName..": "..player, 30, spellId)
	self:PrimaryIcon(65123, player)
end

function mod:FlashCast(_, spellId, _, _, spellName)
	self:Message(61968, "Attention", nil, L["flash_warning"])
	self:Bar(61968, spellName, 9, spellId)
	self:Bar(61968, spellName, 35, spellId)
	self:DelayedMessage(61968, 30, "Attention", L["flash_soon"])
end

do
	local id, name, handle = nil, nil, nil
	local function flashWarn()
		mod:TargetMessage(61968, flashFreezed, "Urgent", "Alert")
		handle = nil
	end

	function mod:Flash(player, spellId, _, _, spellName)
		if UnitInRaid(player) then
			id, name = spellId, spellName
			flashFreezed[#flashFreezed + 1] = player
			self:CancelTimer(handle, true)
			handle = self:ScheduleTimer(flashWarn, 0.3)
		end
	end
end

function mod:Frozen(_, spellId, _, _, spellName)
	self:Message(62478, "Important")
	self:Bar(62478, spellName, 20, spellId)
end

function mod:UNIT_AURA(event, unit)
	if unit and unit ~= "player" then return end
	local _, _, icon, stack = UnitDebuff("player", cold)
	if stack and stack ~= lastCold then
		if stack > 1 then
			self:LocalMessage("cold", "Personal", nil, L["cold_message"]:format(stack), icon)
			self:FlashShake("cold")
		end
		lastCold = stack
	end
end

