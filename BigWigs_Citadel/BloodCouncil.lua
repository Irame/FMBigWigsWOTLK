--------------------------------------------------------------------------------
-- Module Declaration
--
local mod = BigWigs:NewBoss("Blood Prince Council", "Icecrown Citadel")
if not mod then return end
--Prince Valanar, Prince Keleseth, Prince Taldaram
mod:RegisterEnableMob(37970, 37972, 37973)
mod.toggleOptions = {{72040, "ICON", "FLASHSHAKE"},  {72039, "PROXIMITY"}, {72037, "SAY", "FLASHSHAKE", "WHISPER"}, 72999, 70981, 72052, {"iconprince", "ICON"}, "berserk", "bosskill"}
local CL = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Common")
mod.optionHeaders = {
	[72040] = "Taldaram",
	[72039] = "Valanar",
	[72999] = "heroic",
	[70981] = "general",
}
mod.order = 31

--------------------------------------------------------------------------------
-- Locals
--

local count = 0

--------------------------------------------------------------------------------
--  Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.switch_message = "Health swap: %s"
	L.switch_bar = "~Next health swap"

	L.empowered_flames = "Inferno Flames"
	L.empowered_bar = "~Next Flames"

	L.empowered_shock_message = "Casting Shock!"
	L.regular_shock_message = "Shock zone"
	L.shock_say = "Shock zone on me!"
	L.shock_bar = "~Next Shock"

	L.iconprince = "Icon on active prince"
	L.iconprince_icon = "achievement_boss_princetaldaram"
	L.iconprince_desc = "Place the primary raid icon on the active prince (requires promoted or leader)."

	L.prison_message = "Shadow Prison x%d!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED_DOSE", "Prison", 72999)
	self:Log("SPELL_AURA_APPLIED", "Switch", 70981, 70982, 70952, 70983, 70934, 71582, 71596)
	self:Log("SPELL_CAST_START", "EmpoweredShock", 72039, 73037, 73038, 73039)
	self:Log("SPELL_SUMMON", "RegularShock", 72037)
	self:Log("SPELL_CAST_SUCCESS", "Bomb", 72052, 72800, 72801, 72802)

	self:Emote("EmpoweredFlame", L["empowered_flames"])

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "Reboot")

	self:Death("Deaths", 37970, 37972, 37973)
	count = 0
end

function mod:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
	--Need some sensible event args please Blizz
	count = count + 1
	if count == 3 then --3 bosses engaged
		count = 0
		local guid = UnitGUID("boss1")
		if guid then
			local mobId = self.GetMobIdByGUID[guid]
			if mobId == 37970 or mobId == 37972 or mobId == 37973 then
				self:Engage()
				self:OpenProximity(15,72039)
				self:Bar(70981, L["switch_bar"], 45, 70981)
				self:Bar(72037, L["shock_bar"], 20, 72037)
				self:Berserk(600)
			else
				self:Disable()
			end
		else
			self:Reboot()
		end
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Bomb(_, spellId, _, _, spellName)
	self:Message(72052, "Attention", "Alert")
end

function mod:Prison(player, spellId, _, _, _, stack)
	if stack > 2 and UnitIsUnit(player, "player") then
		self:LocalMessage(72999, "Personal", nil, L["prison_message"]:format(stack))
	end
end

function mod:Switch(unit, spellId, _, _, spellName)
	self:Message(70981, "Positive", "Info", L["switch_message"]:format(unit))
	self:Bar(70981, L["switch_bar"], 45, spellId)
	self:SendMessage("BigWigs_StopBar", self, L["empowered_bar"])
	for i = 1, 3 do
		local bossId = ("boss%d"):format(i)
		local name = UnitName(bossId)
		if name and name == unit then
			if self.GetMobIdByGUID[UnitGUID(bossId)] == 37970 then
				self:OpenProximity(15,72039)
			else
				self:CloseProximity(72039)
			end
			self:PrimaryIcon("iconprince", bossId)
			break
		end
	end
end

function mod:EmpoweredShock(_, spellId)
	self:Message(72039, "Important", "Alert", L["empowered_shock_message"])
	--self:OpenProximity(15,72039)
	--self:ScheduleTimer(self.CloseProximity, 5, 72039)
	self:Bar(72039, L["shock_bar"], 16, spellId)
end

function mod:RegularShock()
	for i = 1, 3 do
		local bossId = ("boss%d"):format(i)
		local guid = UnitGUID(bossId)
		if not guid then return end
		local mobId = self.GetMobIdByGUID[guid]
		if mobId == 37970 then
			local target = UnitName(bossId .. "target")
			if target then
				if UnitIsUnit("player", target) then
					self:FlashShake(72037)
					self:Say(72037, L["shock_say"])
				end
				self:TargetMessage(72037, target, "Urgent", nil, L["regular_shock_message"])
				self:Whisper(72037, target, L["regular_shock_message"])
				self:Bar(72037, L["shock_bar"], 16, 72037)
			end
			break
		end
	end
end

function mod:EmpoweredFlame(msg, _, _, _, player)
	if UnitIsUnit(player, "player") then
		self:FlashShake(72040)
	end
	self:TargetMessage(72040, player, "Urgent", "Long", L["empowered_flames"])
	self:SecondaryIcon(72040, player)
	self:Bar(72040, L["empowered_bar"], 20, 72040)
end

do
	local deaths = 0
	function mod:Deaths()
		deaths = deaths + 1
		if deaths == 3 then
			self:Win()
		end
	end
end

