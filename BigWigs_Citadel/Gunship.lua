--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Icecrown Gunship Battle", "Icecrown Citadel")
if not mod then return end
mod:RegisterEnableMob(37184) --Zafod Boombox
mod.toggleOptions = {"adds", "mage", "bosskill"}
mod.order = 14

--------------------------------------------------------------------------------
-- Locals
--

local killed = nil

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.adds = "Portals"
	L.adds_icon = 53142
	L.adds_desc = "Warn for Portals."
	L.adds_trigger_alliance = "Reavers, Sergeants, attack!"
	L.adds_trigger_horde = "Marines, Sergeants, attack!"
	L.adds_message = "Portals!"
	L.adds_bar = "Next Portals"

	L.mage = "Mage"
	L.mage_icon = 69705
	L.mage_desc = "Warn when a mage spawns to freeze the gunship cannons."
	L.mage_message = "Mage Spawned!"
	L.mage_bar = "Next Mage"

	L.warmup_trigger_alliance = "Fire up the engines"
	L.warmup_trigger_horde = "Rise up, sons and daughters"

	L.disable_trigger_alliance = "Onward, brothers and sisters"
	L.disable_trigger_horde = "Onward to the Lich King"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Yell("Warmup", L["warmup_trigger_alliance"], L["warmup_trigger_horde"])
	self:Yell("AddsPortal", L["adds_trigger_alliance"], L["adds_trigger_horde"]) --XXX unreliable, change to repeater
	self:Yell("Defeated", L["disable_trigger_alliance"], L["disable_trigger_horde"])
	self:Log("SPELL_CAST_START", "Frozen", 69705)
	self:Log("SPELL_AURA_REMOVED", "FrozenCD", 69705)
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
end

do
	local count = 0
	function mod:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
		--Need some sensible event args please Blizz
		count = count + 1
		if count == 2 then --2 bosses engaged
			count = 0
			local guid = UnitGUID("boss1")
			if guid then
				mobId = self.GetMobIdByGUID[guid]
				if mobId == 37540 or mobId == 37215 then
					self:Engage()
				else
					self:Disable()
				end
			end
		end
	end
end

function mod:Warmup()
	self:Bar("adds", COMBAT, 45, "achievement_dungeon_hordeairship")
	--XXX Fix me, move to engage, need more logs for testing
	self:Bar("adds", L["adds_bar"], 60, L.adds_icon)
	self:Bar("mage", L["mage_bar"], 82, L.mage_icon)
end

function mod:VerifyEnable()
	if not killed then return true end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:AddsPortal()
	self:Message("adds", "Attention", nil, L["adds_message"], L.adds_icon)
	self:Bar("adds", L["adds_bar"], 60, L.adds_icon) --Portal: Dalaran icon
end

function mod:Frozen(_, spellId)
	self:Message("mage", "Positive", "Info", L["mage_message"], spellId)
end

function mod:FrozenCD(_, spellId)
	self:Bar("mage", L["mage_bar"], 35, spellId)
end

function mod:Defeated()
	killed = true
	self:Win()
end

