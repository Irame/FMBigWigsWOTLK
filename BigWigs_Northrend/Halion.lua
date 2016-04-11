--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Halion", "The Ruby Sanctum")
if not mod then return end
mod.otherMenu = "Northrend"
mod:RegisterEnableMob(39863, 40142)
mod.toggleOptions = {{74562, "SAY", "ICON", "FLASHSHAKE", "WHISPER"}, {75879, "FLASHSHAKE"},"add_enrage" , {74792, "SAY", "ICON", "FLASHSHAKE", "WHISPER"}, {74826, "FLASHSHAKE"}, 74769, 75954, 74525, "berserk", "bosskill"}

--------------------------------------------------------------------------------
-- Locals
--

local phase = 1
local addsDeaths = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_trigger = "Your world teeters on the brink of annihilation. You will ALL bear witness to the coming of a new age of DESTRUCTION!"
	
	L.phase_two_trigger = "You will find only suffering within the realm of twilight! Enter if you dare!"

	L.twilight_cutter_yell = "Beware the shadow!"
	L.twilight_cutter_emote = "The orbiting spheres pulse with dark energy!"
	L.twilight_cutter_bar = "~Laser beams"
	L.twilight_cutter_warning = "Laser beams incoming!"

	L.fire_damage_message = "Your feet are burning!"
	L.fire_message = "Fire bomb"
	L.fire_bar = "Next Fire bomb"
	L.fire_say = "Fire bomb on ME!"
	L.shadow_message = "Shadow bomb"
	L.shadow_bar = "Next Shadow bomb"
	L.shadow_say = "Shadow bomb on ME!"

	L.meteorstrike_yell = "The heavens burn!"
	L.meteorstrike_bar = "Meteor Strike"
	L.meteor_warning_message = "Meteor incoming!"

	L.sbreath_cooldown = "Next Shadow Breath"
	L.fbreath_cooldown = "Next Fire Breath"
	
	L.add_enrage = "Add Enrage"
	L.add_enrage_desc = "Show timers for when the adds goes enrage."
	L.add_enrage_bar = "Add Enrage"
	
	L.corporeality_message = "Corporeality %d: %s"
	L.corporeality_trigger = "efforts force"
	L.corporeality_0_to_30_message = "FULL DAMAGE!"
	L.corporeality_40_message = "More damage"
	L.corporeality_50_message = "Balanced"
	L.corporeality_60_message = "Less damage"
	L.corporeality_70_to_100_message = "DAMAGE STOP!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Fire", 74562)
	self:Log("SPELL_AURA_APPLIED", "Shadow", 74792)
	self:Log("SPELL_CAST_SUCCESS", "MeteorStrike", 75879, 74648, 75877)
	self:Log("SPELL_DAMAGE", "FireDamage", 75947, 75948, 75949, 75950, 75951, 75952)
	-- Dark breath 25m, flame breath 25m, dark breath 10m, flame breath 10m
	self:Log("SPELL_CAST_START", "ShadowBreath", 74806, 75954, 75955, 75956)
	self:Log("SPELL_CAST_START", "FireBreath", 74525, 74526, 74527, 74528)
	self:Death("Deaths", 39863, 40142, 40683)

	self:Yell("TwilightCutter", L["twilight_cutter_yell"])
	self:Yell("Engage", L["engage_trigger"])
	self:Yell("PhaseTwo", L["phase_two_trigger"])
	self:Yell("MeteorInc", L["meteorstrike_yell"])
	
	self:Emote("TwilightCutter",L["twilight_cutter_emote"])
	self:Emote("Corporeality",L["corporeality_trigger"])
	
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
end

function mod:OnEngage(diff)
	phase = 1
	self:Berserk(480)
	self:Bar(75879, L["meteorstrike_bar"], 25, 75879)
	self:Bar(74562, L["fire_bar"], 20, 74562)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:FireDamage(player, spellId)
	if UnitIsUnit(player, "player") then
		self:FlashShake(75879)
		self:LocalMessage(75879, "Personal", nil, L["fire_damage_message"])
	end
end

function mod:Fire(player, spellId)
	self:Bar(74562, L["fire_bar"], 30, spellId)
	if UnitIsUnit(player, "player") then
		self:Say(74562, L["fire_say"])
		self:FlashShake(74562)
	end
	self:TargetMessage(74562, player, "Personal", "Info", L["fire_message"])
	self:Whisper(74562, player, L["fire_message"])
	self:PrimaryIcon(74562, player)
end

function mod:Shadow(player, spellId)
	self:Bar(74792, L["shadow_bar"], 30, spellId)
	if UnitIsUnit(player, "player") then
		self:Say(74792, L["shadow_say"])
		self:FlashShake(74792)
	end
	self:TargetMessage(74792, player, "Personal", "Info", L["shadow_message"])
	self:Whisper(74792, player, L["shadow_message"])
	self:SecondaryIcon(74792, player)
end

function mod:ShadowBreath(_, spellId)
	self:Bar(75954, L["sbreath_cooldown"], 12, spellId)
end

function mod:FireBreath(_, spellId)
	self:Bar(74525, L["fbreath_cooldown"], 25, spellId)
end

do
	local lastExecute = 0
	function mod:TwilightCutter()
		local ct = GetTime()
		if lastExecute + 5 > ct then return end
		lastExecute = ct
		self:Bar(74769, L["twilight_cutter_bar"], 29, 74769)
		self:Message(74769, "Important", "Alert", L["twilight_cutter_warning"])
	end
end

function mod:MeteorInc()
	if mod:IsDifficulty("25hc") then
		addsDeaths = 0
		self:Bar("add_enrage", L["add_enrage_bar"], 26, 26662)
	end
	self:Message(75879, "Urgent", "Long", L["meteor_warning_message"])
	self:FlashShake(75879)
	self:Bar(75879, L["meteorstrike_bar"], 48, 75879)
end

function mod:MeteorStrike(_, spellId, _, _, spellName)
	if mod:IsDifficulty("25hc") then
		addsDeaths = 0
		self:Bar("add_enrage", L["add_enrage_bar"], 18, 26662)
	end
	self:Message(75879, "Important")
	self:FlashShake(75879)
	self:Bar(75879, L["meteorstrike_bar"], 40, spellId)
end

do
	local lastCorporeality = 0
	function mod:Corporeality()
		local statusFrameText = AlwaysUpFrame1Text:GetText()
		local corporeality = tonumber(statusFrameText:sub(statusFrameText:find("%d+")))
		if corporeality >= 0 and corporeality <= 30 then
			self:Message(74826, "Important", "Alarm", L["corporeality_message"]:format(corporeality,L["corporeality_0_to_30_message"]))
		elseif corporeality == 40 then
			self:Message(74826, "Attention", nil, L["corporeality_message"]:format(corporeality,L["corporeality_40_message"]))
		elseif corporeality == 50 then
			self:Message(74826, "Positive", nil, L["corporeality_message"]:format(corporeality,L["corporeality_50_message"]))
		elseif corporeality == 60 then
			self:Message(74826, "Attention", nil, L["corporeality_message"]:format(corporeality,L["corporeality_60_message"]))
		elseif corporeality >= 70 and corporeality <= 100 then
			if lastCorporeality < corporeality then
				self:FlashShake(74826)
			end
			self:Message(74826, "Important", "Alarm", L["corporeality_message"]:format(corporeality,L["corporeality_70_to_100_message"]))
		end
		lastCorporeality = corporeality
	end
end

function mod:PhaseTwo()
	phase = 2
	self:SendMessage("BigWigs_StopBar", self, L["fbreath_cooldown"])
	self:SendMessage("BigWigs_StopBar", self, L["meteorstrike_bar"])
	self:SendMessage("BigWigs_StopBar", self, L["fire_bar"])
	self:Bar(74769, L["twilight_cutter_bar"], 29, 74769)
end


function mod:Deaths(mobId)
	if mobId == 40683 then
		addsDeaths = addsDeaths + 1
		if addsDeaths >= 8 then
			self:SendMessage("BigWigs_StopBar", self, L["add_enrage_bar"])
		end
	elseif mobId == 39863 or mobId == 40142 then
		self:Win()
	end
end