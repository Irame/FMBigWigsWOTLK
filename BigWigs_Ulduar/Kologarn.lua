--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Kologarn", "Ulduar")
if not mod then return end
mod:RegisterEnableMob(32930)
mod.toggleOptions = { 64290, "shockwave", {"eyebeam", "WHISPER", "ICON", "FLASHSHAKE", "SAY"}, "arm", 63355, "bosskill"}
mod.order = 6

--------------------------------------------------------------------------------
-- Locals
--

local grip = mod:NewTargetList()
local pName = UnitName("player")

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.arm = "Arm dies"
	L.arm_desc = "Warn for Left & Right Arm dies."
	L.left_dies = "Left Arm dies"
	L.right_dies = "Right Arm dies"
	L.left_wipe_bar = "Respawn Left Arm"
	L.right_wipe_bar = "Respawn Right Arm"

	L.shockwave = "Shockwave"
	L.shockwave_desc = "Warn when the next Shockwave is coming."
	L.shockwave_trigger = "Oblivion!"

	L.eyebeam = "Focused Eyebeam"
	L.eyebeam_desc = "Warn who gets Focused Eyebeam."
	L.eyebeam_trigger = "his eyes on you"
	L.eyebeam_message = "Eyebeam: %s"
	L.eyebeam_bar = "~Eyebeam"
	L.eyebeam_you = "Eyebeam on YOU!"
	L.eyebeam_say = "Eyebeam on ME!"

	L.eyebeamsay = "Eyebeam Say"
	L.eyebeamsay_desc = "Say when you are the target of Focused Eyebeam."

end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Grip", 64290, 64292)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Armor", 63355, 64002)
	self:Log("UNIT_DIED", "Deaths")

	self:Death("Deaths", 32933, 32934, 32930)

	self:RegisterEvent("CHAT_MSG_RAID_BOSS_WHISPER")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:AddSyncListener("EyeBeamWarn")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Armor(player, spellId, _, _, _, stack)
	if stack > 1 then
		self:StackMessage(63355, player, stack, "Urgent", "Info")
	end
end

do
	local id, name, handle = nil, nil, nil
	local function gripWarn()
		mod:TargetMessage(64290, grip, "Attention", "Alert")
		mod:Bar(64290, name, 10, id)
	end

	function mod:Grip(player, spellId, _, _, spellName)
		id, name = spellId, spellName
		grip[#grip + 1] = player
		self:CancelTimer(handle, true)
		handle = self:ScheduleTimer(gripWarn, 0.2)
	end
end

function mod:CHAT_MSG_RAID_BOSS_WHISPER(event, msg)
	if msg:find(L["eyebeam_trigger"]) then
		self:LocalMessage("eyebeam", "Personal", "Long", L["eyebeam_you"], 63976)
		self:FlashShake("eyebeam")
		self:Say("eyebeam", L["eyebeam_say"])
	end
	self:Sync("EyeBeamWarn", pName)
end

function mod:Deaths(guid)
	if guid == 32933 then
		self:Message("arm", "Attention", nil, L["left_dies"], false)
		self:Bar("arm", L["left_wipe_bar"], 50, 2062)
	elseif guid == 32934 then
		self:Message("arm", "Attention", nil, L["right_dies"], false)
		self:Bar("arm", L["right_wipe_bar"], 50, 2062)
	else
		self:Win()
	end
end

function mod:CHAT_MSG_MONSTER_YELL(event, msg)
	if msg == L["shockwave_trigger"] then
		self:Message("shockwave", "Attention", nil, L["shockwave"], 63982)
		self:Bar("shockwave", L["shockwave"], 21, 63982)
	end
end

function mod:OnSync(sync, rest, nick)
	if sync == "EyeBeamWarn" and rest then
		self:TargetMessage("eyebeam", rest, "Positive", "Info", 40620, 63976) --40620 = "Eyebeam"
		self:Bar("eyebeam", L["eyebeam_message"]:format(rest), 11, 63976)
		self:Bar("eyebeam", L["eyebeam_bar"], 20, 63976)
		self:PrimaryIcon("eyebeam", rest)
	end
end

