--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Highking Beemz", "Icecrown Citadel")
if not mod then return end
mod:RegisterEnableMob(100008, 100012)
mod.toggleOptions = {
	{71340, "WHISPER", "FLASHSHAKE"}, --Pakt der Sinistren
	{71861, "WHISPER", "FLASHSHAKE"}, --Schwärmende Schatten
	{41001, "WHISPER", "FLASHSHAKE"}, --Verhängnisvolle Affäre
	{63018, "WHISPER", "FLASHSHAKE"}, --Sengendes Licht
	{68123, "WHISPER", "FLASHSHAKE"}, --Legionsflamme
	{68872, "WHISPER", "FLASHSHAKE"}, --Seelensturm
	{70106, "FLASHSHAKE"}, --Durchgefroren
	70842, --Manabarriere
	66118, --Egelschwarm
	41350, --Aura der Begierde
	68335, --Wutanfall
	45855, --Gasnova
	31306, --Aasschwarm
	"add_warning_key", "ability_warning_key", "proximity", "berserk", "bosskill"}
	
mod.optionHeaders = {
	proximity = "general",
}

--------------------------------------------------------------------------------
-- Locals
--
local pactDarkfallenTargets = mod:NewTargetList()
local shadowsTargets = mod:NewTargetList()
local flameTargets = mod:NewTargetList()
local lightBombTargets = mod:NewTargetList()
local fatalAttractionTargets = mod:NewTargetList()


local abilityWarningBar = 0
local addData = {
	[34464]={id="valk",name="Val'kyr",spell1=63018},
	[34465]={id="fireEle",name="Feuer Ele",spell1=68123},
	[34466]={id="arcaneEle",name="Arcane Ele",spell1=68872},
	[34467]={id="frostOrb",name="Frost Kugel",spell1=70106,spell2=71050},
	[34468]={id="waterEle",name="Wasser Ele",spell1=70842},
	[34469]={id="flower",name="Blume",spell1=66118},
	[34470]={id="essence",name="Essenz",spell1=41350},
	[34471]={id="bloodBeast",name="Blutbestie",spell1=68335},
	[34477]={id="goo",name="Schleim",spell1=45855},
	[34478]={id="spore",name="Spore",spell1=31306}
}
local addSpawnTime = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.warmup_trigger = "Was denkt ihr werden sie mit euch machen"
	L.engage_trigger = "Hütet euch vor den Schatten!"
	L.enrage_trigger = "Eure Zeit ist abgelaufen!"
	L.enrage_message = "Berserk!"
	
	L.pactDarkfallen_message = "Pact of the Darkfallen"
	L.swarmingShadows_message = "Swarming Shadows"
	L.fatalAttraction_message = "Fatal Attraction"
	
	L.add_warning_key = "Warnings about adds"
	L.add_warning_key_desc = "Display warnings and bars for adds"
	L.ability_warning_key = "Genneral bar for the next abilitys"
	L.ability_warning_key_desc = "Display a bar whitch shows when the next ability will come. (This Bar will be removed if an add is identified)"
	
	--L.swarmingShadows_trigger = "Hütet euch vor den Schatten!"
	
	L.add_trigger = "Ihr wisst nicht, was euch erwartet!!!"
	L.add_message = "New Adds"
	L.nextAdds_bar = "Next Adds"
	L.nextAbilitys_bar = "Next abilitys"
	
	L.valk_identify_massage = "Valkyr recognized!"
	L.valk_walk_bar = "Valkyr (Searing Light)"
	L.valk_ability_message = "Searing Light will come!"
	L.lightbomb_other = "Searing Light"
	
	L.fireEle_identify_massage = "Fire ele recognized!"
	L.fireEle_walk_bar = "Fire ele (Legionflame)"
	L.fireEle_ability_message = "Legionflame will come!"
	L.legionflame_message = "Legionflame"
	
	L.arcaneEle_identify_massage = "Arcane ele recognized!"
	L.arcaneEle_walk_bar = "Arcane ele (Soulstorm)"
	L.arcaneEle_ability_message = "Soulstorm will come!"
	
	L.frostOrb_identify_massage = "Frost orb recognized!"
	L.frostOrb_walk_bar = "Frost orb (Permeating Chill)"
	L.frostOrb_ability_message = "Permeating Chill will come!"
	L.chilled_message = "Chilled x%d!"
	
	L.waterEle_identify_massage = "Water ele recognized!"
	L.waterEle_walk_bar = "Water ele (Mana Barrier)"
	L.waterEle_ability_message = "Mana Barrier will come!"
	
	L.flower_identify_massage = "Flower recognized!"
	L.flower_walk_bar = "Flower (Leeching Swarm)"
	L.flower_ability_message = "Leeching Swarm will come!"
	
	L.essence_identify_massage = "Essence recognized!"
	L.essence_walk_bar = "Essence (Aura of Desire)"
	L.essence_ability_message = "Aura of Desire will come!"
	
	L.bloodBeast_identify_massage = "Blood Beast recognized!"
	L.bloodBeast_walk_bar = "Blood Beast (Enrage)"
	L.bloodBeast_ability_message = "Enrage will come!"
	
	L.goo_identify_massage = "Goo recognized!"
	L.goo_walk_bar = "Schleim (Gas Nova)"
	L.goo_ability_message = "Gas Nova will come!"
	L.gas_message = "Casting Gas Nova!"
	L.gas_bar = "~Gas Nova Cooldown"
	
	L.spore_identify_massage = "Spore recognized!"
	L.spore_walk_bar = "Spore (Carrion Swarm)"
	L.spore_ability_message = "Carrion Swarm will come!"
	L.swarm_message = "Swarm!"
	L.swarm_bar = "~Swarm Cooldown"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "PactDarkfallen", 71340)
	self:Log("SPELL_CAST_SUCCESS", "SwarmingShadows", 71264)
	self:Log("SPELL_AURA_APPLIED", "FatalAttraction", 41001)
	
	self:Log("SPELL_AURA_APPLIED", "LightBomb", 63018, 65121)
	self:Log("SPELL_AURA_REMOVED", "LightRemoved", 63018, 65121)
	self:Log("SPELL_AURA_APPLIED", "LegionFlame", 68123, 68124, 68125, 66197)
	self:Log("SPELL_AURA_APPLIED", "SoulstormBoss", 68872)
	self:Log("SPELL_AURA_APPLIED", "SoulstormPlayer", 69049, 68921)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Chilled", 70106)
	self:Log("SPELL_AURA_APPLIED", "ManaBarrier", 70842)
	self:Log("SPELL_CAST_START", "LeechingSwarm", 66118, 67630, 68646, 68647)
	self:Log("SPELL_AURA_APPLIED", "Essence", 41350)
	self:Log("SPELL_AURA_APPLIED", "BeastEnraged", 68335)
	self:Log("SPELL_CAST_START", "Gas", 45855)
	self:Log("SPELL_CAST_SUCCESS", "Swarm", 31306)
	
	--self:Log("UNIT_DIED","testDie")
	
	self:Death("Deaths", 100008)
	

	for k,_ in pairs(addData) do
		self:Death("Deaths", (k+65536))
	end

	
	
	self:RegisterEvent("UNIT_TARGET", "CheckForAdds")
	--self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "CheckAddDies")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	
	self:Yell("AddSpawn",L["add_trigger"])
	--self:Yell("Engage",L["engage_trigger"])
	self:Yell("Warmup",L["warmup_trigger"])
	--self:Yell("EnrageWarning",L["enrage_trigger"])
end

function mod:Warmup()
	self:Bar("berserk", self.displayName, 13, "achievement_boss_algalon_01")
end

function mod:OnEngage()
	self:Berserk(410, true)
	self:Bar("add_warning_key", L["nextAdds_bar"], 30, 71772)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:AbilityBar(key, text, time, icon)
	if GetTime() + time > addSpawnTime + 76 then return end
	self:Bar(key, text, time, icon)
end


function mod:testDie(...)
	print("testDie")
	for i=1, select("#",...) do
		print(select(i,...))
	end
end


-- Spore
function mod:Swarm(_, spellID, _, _, spellName)
	self:Message(31306, spellName, "Attention", spellID)
	self:AbilityBar(31306, spellName, 21, spellID)
end

-- Schleim
function mod:Gas(_, spellID, _, _, spellName)
	self:Message(45855, spellName, "Important", spellID, "Alert")
	self:AbilityBar(45855, spellName, 12, spellID)
end

--Blutbestie
function mod:BeastEnraged(_, spellId, _, _, spellName)
	self:Message(68335, spellName, "Attention", spellId)
end

--Essenz
function mod:Essence(player, spellId, _, _, spellName)
	if UnitIsUnit(player, "player") then
		self:LocalMessage(41350, spellName, "Attention", spellId)
	end
end

--Blume
function mod:LeechingSwarm(_, spellId, _, _, spellName)
	self:Message(66118, spellName, "Important", spellId, "Long")
end

--Wasser Ele
function mod:ManaBarrier(_, spellId, _, _, spellName)
	self:Message(70842, spellName, "Attention", spellId)
end

--Frost Kugel
function mod:Chilled(player, spellId, _, _, _, stack)
	if stack > 4 and UnitIsUnit(player, "player") then
		self:LocalMessage(70106, L["chilled_message"]:format(stack), "Personal", spellId)
		if stack > 10 then
			self:FlashShake(70106)
		end
	end
end

--Arcane Ele
function mod:SoulstormBoss(_, spellId, _, _, spellName)
	self:Message(68872, spellName, "Important", spellId)
end

function mod:SoulstormPlayer(player, spellId, _, _, spellName)
	--self:TargetMessage(68872, spellName, player, "Personal", spellId, "Alert")
	if UnitIsUnit(player, "player") then self:FlashShake(68872) end
	self:Whisper(68872, player, spellName)
end


--Feuer Ele
do
	local legionFlameScheduled = nil
	local function legionFlame()
		mod:TargetMessage(68123, L["legionflame_message"], flameTargets, "Important", 68123, "Alert")
		legionFlameScheduled = nil
	end
	function mod:LegionFlame(player)
		if UnitIsUnit(player, "player") then
			self:FlashShake(68123)
		end
		self:Whisper(68123, player, L["legionflame_message"])
		flameTargets[#flameTargets + 1] = player
		if not legionFlameScheduled then
			legionFlameScheduled = true
			self:AbilityBar(68123, L["legionflame_message"], 22, 68123)
			self:ScheduleTimer(legionFlame, 0.5)
		end
	end
end

--Val'kyre
do
	local lightBombScheduled = nil
	local function lightBomb()
		mod:TargetMessage(63018, L["lightbomb_other"], lightBombTargets, "Important", 63018, "Alert")
		lightBombScheduled = nil
	end
	function mod:LightBomb(player)
		if UnitIsUnit(player, "player") then
			self:OpenProximity(10,63018)
			self:FlashShake(63018)
		end
		self:Whisper(63018, player, L["lightbomb_other"])
		lightBombTargets[#lightBombTargets + 1] = player
		if not lightBombScheduled then
			lightBombScheduled = true
			self:AbilityBar(63018, L["lightbomb_other"], 11, 63018)
			self:ScheduleTimer(lightBomb, 0.3)
		end
	end
end

function mod:LightRemoved(player)
	if UnitIsUnit(player, "player") then
		self:CloseProximity()
	end
end

--Start
do
	local fatalAttractionScheduled = nil
	local function fatalAttraction()
		mod:TargetMessage(41001, L["fatalAttraction_message"], fatalAttractionTargets, "Important", 41001, "Alert")
		fatalAttractionScheduled = nil
	end
	function mod:FatalAttraction(player)
		if UnitIsUnit(player, "player") then
			self:FlashShake(41001)
		end
		self:Whisper(41001, player, L["fatalAttraction_message"])
		fatalAttractionTargets[#fatalAttractionTargets + 1] = player
		if not fatalAttractionScheduled then
			fatalAttractionScheduled = true
			self:ScheduleTimer(fatalAttraction, 0.3)
		end
	end
end

do
	local pactDarkfallenScheduled = nil
	local function pactDarkfallen()
		mod:TargetMessage(71340, L["pactDarkfallen_message"], pactDarkfallenTargets, "Important", 71340, "Alert")
		pactDarkfallenScheduled = nil
	end
	function mod:PactDarkfallen(player)
		if UnitIsUnit(player, "player") then
			self:FlashShake(71340)
		end
		self:Whisper(71340, player, L["pactDarkfallen_message"])
		pactDarkfallenTargets[#pactDarkfallenTargets + 1] = player
		if not pactDarkfallenScheduled then
			pactDarkfallenScheduled = true
			self:ScheduleTimer(pactDarkfallen, 0.3)
		end
	end
end

do
	local swarmingShadowsScheduled = nil
	local function swarmingShadows()
		mod:TargetMessage(71861, L["swarmingShadows_message"], shadowsTargets, "Important", 71861, "Alert")
		swarmingShadowsScheduled = nil
	end
	function mod:SwarmingShadows(player)
		if UnitIsUnit(player, "player") then
			self:FlashShake(71861)
		end
		self:Whisper(71861, player, L["swarmingShadows_message"])
		shadowsTargets[#shadowsTargets + 1] = player
		if not swarmingShadowsScheduled then
			swarmingShadowsScheduled = true
			self:ScheduleTimer(swarmingShadows, 0.3)
		end
	end
end

function mod:AddSpawn()
	self:Message("add_warning_key", L["add_message"], "Important", 71772, "Alarm")
	abilityWarningBar = L["nextAbilitys_bar"]
	self:Bar("ability_warning_key", L["nextAbilitys_bar"], 37, 71623)
	self:Bar("add_warning_key", L["nextAdds_bar"], 76, 71772)
	addSpawnTime = GetTime()
	for k, v in pairs(addData) do
		if addData[k]["bar"] then
			addData[k]["bar"]=nil
		end
	end
end

function mod:CheckForAdds(_,unit)
	local guid = UnitGUID(unit.."target")
	if guid then
		local mobId = self.GetMobIdByGUID[guid]
		if addData[mobId] and not addData[mobId]["bar"] then
			if abilityWarningBar then
				self:SendMessage("BigWigs_StopBar", self, abilityWarningBar)
				abilityWarningBar=nil
			end
			local timeLeft = addSpawnTime + 37 - GetTime()
			addData[mobId]["bar"] = L[addData[mobId]["id"].."_walk_bar"]
			self:Message(addData[mobId]["spell1"], L[addData[mobId]["id"].."_identify_massage"], "Important", addData[mobId]["spell1"])
			self:Bar(addData[mobId]["spell1"], L[addData[mobId]["id"].."_walk_bar"], timeLeft, addData[mobId]["spell1"])
		end
		--[[
		if not (addData[mobId] or mobId == 34472 or mobId == 34476 or mobId == 0) and mod:IsEnabled() then
			mod:Disable()
		end
		]]
	end
end

function mod:Deaths(entryId)
	local mobId = entryId - 65536
	if addData[mobId] and addData[mobId]["bar"] then
		self:SendMessage("BigWigs_StopBar", self, addData[mobId]["bar"])
	elseif entryId == 100008 then
		self:Win()
	end
end
--[[
function mod:EnrageWarning()
	self:Message("berserk", L["enrage_message"], "Important", 26662, "Alarm")
end
]]