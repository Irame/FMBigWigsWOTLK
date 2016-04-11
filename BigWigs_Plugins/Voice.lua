
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

-- variables for better readablility
local personal = 1
local nearby = 2
local general = 3

local paths = {
	[general] = "Interface\\AddOns\\BigWigs_Plugins\\Voices\\%s.mp3"
	[personal] = "Interface\\AddOns\\BigWigs_Plugins\\Voices\\%sy.mp3"
	[nearby] = "Interface\\AddOns\\BigWigs_Plugins\\Voices\\%sn.mp3"
}
function plugin:BigWigs_Voice(event, module, key, sound, onMe, near)
	local success = false;
	local modifier = (onMe and personal) or (near and nearby) or general
	local fileExists = key and plugin.fileTable[key] and plugin.fileTable[key][isOnMe];
	if BigWigs.db.profile.voice and fileExists then
		success = PlaySoundFile(format(paths[modifier], tostring(key)))
	end
	if not success then
		self:SendMessage("BigWigs_Sound", sound) 
	end
end


plugin.fileTable = {	-- on you            on other
	----------------------------------------
	--- Testing
	["testVoice1"] = 	{ [personal] = false,	[nearby] = false,	[general] = true },
	["testVoice2"] = 	{ [personal] = false,	[nearby] = false,	[general] = true },
	["testVoice3"] = 	{ [personal] = false,	[nearby] = false,	[general] = true },
	["testVoice4"] = 	{ [personal] = false,	[nearby] = false,	[general] = true },
	
	----------------------------------------
	----- Icecrown Citadel
	----------------------------------------
	-- Lord Marrowgar
	[69057] = 			{ [personal] = true,	[nearby] = false,	[general] = true },		-- Impale
	[69138] = 			{ [personal] = false,	[nearby] = false,	[general] = true },		-- Coldflame
	
}