
local plugin = BigWigs:NewPlugin("Voice")
if not plugin then return end

--------------------------------------------------------------------------------
-- Locals
--

local tostring = tostring
local format = format

--------------------------------------------------------------------------------
-- Localization
--




function plugin:OnPluginEnable()
	self:RegisterMessage("BigWigs_Voice")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local path = "Interface\\AddOns\\BigWigs_Plugins\\Voices\\%s.mp3"
local pathYou = "Interface\\AddOns\\BigWigs_Plugins\\Voices\\%sy.mp3"
function plugin:BigWigs_Voice(event, module, key, sound, isOnMe)
	local success = false;
	local fileExists = key and plugin.fileTable[key] and plugin.fileTable[key][not not isOnMe];
	if BigWigs.db.profile.voice and fileExists then
		success = PlaySoundFile(format(isOnMe and pathYou or path, tostring(key)))
	end
	if not success then
		self:SendMessage("BigWigs_Sound", sound) 
	end
end

-- variables for better readablility
local personal = true
local general = false

plugin.fileTable = {	-- on you            on other
	----------------------------------------
	--- Testing
	["testVoice1"] = 	{ [personal] = false,	[general] = true },
	["testVoice2"] = 	{ [personal] = false,	[general] = true },
	["testVoice3"] = 	{ [personal] = false,	[general] = true },
	["testVoice4"] = 	{ [personal] = false,	[general] = true },
	
	----------------------------------------
	----- Icecrown Citadel
	----------------------------------------
	-- Lord Marrowgar
	[69057] = 			{ [personal] = true,	[general] = true },		-- Impale
	[69138] = 			{ [personal] = false,	[general] = true },		-- Coldflame
	
}