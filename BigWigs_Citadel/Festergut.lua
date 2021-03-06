--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Festergut", "Icecrown Citadel")
if not mod then return end
mod:RegisterEnableMob(36626)
mod.toggleOptions = {{69279, "PROXIMITY", "FLASHSHAKE"}, 69165, 71219, 72551, {71218, "PROXIMITY"}, 72295, "berserk", "bosskill"}
mod.optionHeaders = {
	[69279] = "normal",
	[72295] = "heroic",
}
mod.order = 21

--------------------------------------------------------------------------------
-- Locals
--

local count = 1

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_trigger = "Fun time?"

	L.inhale_message = "Inhale Blight %d"
	L.inhale_bar = "Inhale %d"

	L.blight_warning = "Pungent Blight in ~5sec!"
	L.blight_bar = "Next Blight"

	L.bloat_bar = "~Gastric Bloat"

	L.spore_bar = "~Gas Spores"

	L.ball_message = "Goo ball incoming!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "InhaleCD", 69165)
	self:Log("SPELL_CAST_START", "Blight", 69195, 71219, 73031, 73032)
	self:Log("SPELL_CAST_SUCCESS", "VileGas", 69240, 71218, 73020, 73019)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Bloat", 72219, 72551, 72552, 72553)
	self:Death("Win", 36626)

	self:AddSyncListener("GooBall")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:Yell("Engage", L["engage_trigger"])

	self:Log("SPELL_AURA_APPLIED", "Spores", 69279)
end

function mod:OnEngage()
	count = 1
	self:Berserk(300, true)
	self:Bar(69279, L["spore_bar"], 20, 69279)
	self:Bar(69165, L["inhale_bar"]:format(count), 33.5, 69165)
	self:OpenProximity(9,71218)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local onMe = false
	local msgTargets = mod:NewTargetList()
	local proxTargets = {}
	local scheduled = nil
	local function sporeWarn(spellName)
		if onMe then
			mod:OpenProximity(8, 69279, nil, true)
		else
			mod:OpenProximity(8, 69279, proxTargets, true)
		end
		mod:TargetMessage(69279, msgTargets, "Urgent", "Alert")
		scheduled = nil
		onMe = false
	end
	local function sporeNext()
		mod:Bar(69279, L["spore_bar"], 28, 69279)
		mod:OpenProximity(9,71218)
	end
	function mod:Spores(player, spellId, _, _, spellName)
		msgTargets[#msgTargets + 1] = player
		proxTargets[#proxTargets + 1] = player
		if UnitIsUnit(player, "player") then
			self:FlashShake(69279)
			onMe = true
		end
		if not scheduled then
			scheduled = true
			self:ScheduleTimer(sporeWarn, 0.2, spellName)
			self:ScheduleTimer(sporeNext, 12)
			local explodeName = GetSpellInfo(67729) --"Explode"
			self:Bar(69279, explodeName, 12, spellId)
		end
	end
end

function mod:InhaleCD(_, spellId, _, _, spellName)
	self:Message(69165, "Attention", nil, L["inhale_message"]:format(count))
	count = count + 1
	if count == 4 then
		self:DelayedMessage(71219, 28.5, "Attention", L["blight_warning"])
		self:Bar(71219, L["blight_bar"], 33.5, 71219)
	else
		self:Bar(69165, L["inhale_bar"]:format(count), 33.5, spellId)
	end
end

function mod:Blight(_, spellId, _, _, spellName)
	count = 1
	self:Message(71219, "Attention")
	self:Bar(69165, L["inhale_bar"]:format(count), 33.5, 69165)
end

function mod:Bloat(player, spellId, _, _, _, stack)
	if stack > 5 then
		self:StackMessage(72551, player, stack, "Positive")
		self:Bar(72551, L["bloat_bar"], 10, spellId)
	end
end

do
	local t = 0
	function mod:VileGas(_, spellId, _, _, spellName)
		local time = GetTime()
		if (time - t) > 2 then
			t = time
			self:Message(71218, "Important")
		end
	end
end

do
	local goo = GetSpellInfo(72310)
	function mod:UNIT_SPELLCAST_SUCCEEDED(unit, spell)
		if spell == goo then
			self:Sync("GooBall")
		end
	end
end

function mod:OnSync(sync, rest, nick)
	if sync == "GooBall" then
		self:Message(72295, "Important", nil, L["ball_message"])
	end
end

