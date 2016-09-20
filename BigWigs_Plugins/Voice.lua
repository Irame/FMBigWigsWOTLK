
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

local filePath = "Interface\\AddOns\\BigWigs_Plugins\\Voices\\"

local normalPattern = 	filePath.."%s.mp3"
local onMePattern = 	filePath.."%s-y.mp3"
local nearMePattern = 	filePath.."%s-n.mp3"
local customPattern = 	filePath.."%%s_%s.mp3"

function plugin:BigWigs_Voice(event, module, key, onMe, nearMe, custom)
	local pattern = (onMe and onMePattern) or (nearMe and nearMePattern) or (custom and customPattern:format(custom)) or normalPattern
	if BigWigs.db.profile.voice and fileExists then
		PlaySoundFile(pattern:format(tostring(key)))
	end
end

----------------------------------------
----- TestFiles
----------------------------------------
---  testVoice1, testVoice2, testVoice3, testVoice4

----------------------------------------
----- Icecrown Citadel
----------------------------------------
-- Lord Marrowgar

--	Impale (69057): 		normal, onMe
--	Coldflame (69138): 		normal
--	Bonestorm (69076):		incoming
