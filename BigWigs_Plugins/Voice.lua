
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

-- variables for better readablility
local normalIndex = 0
local onMeIndex = 1
local nearMeIndex = 2
local customIndex = 3

local pattern = {
	[normal] = filePath.."%s.mp3",
	[onMe]   = filePath.."%s-y.mp3",
	[nearMe] = filePath.."%s-n.mp3",
	[custom] = filePath.."%s_%s.mp3",
}

function plugin:BigWigs_Voice(event, module, key, sound, onMe, nearMe, custom)
	local success = false;
	local index = (onMe and onMeIndex) or (nearMe and nearMeIndex) or (custom and customIndex) or normalIndex
	local fileExists = plugin.fileTable[index == customIndex and custom or index]
	if BigWigs.db.profile.voice and fileExists then
		success = PlaySoundFile(pattern[index]:format(tostring(key, custom)))
	end
	if not success and sound then
		self:SendMessage("BigWigs_Sound", sound) 
	end
end

do
	plugin.fileTable = setmetatable({},{
		__newindex = function(t, k, v)
			local r = {}
			if type(v) == "table" then
				for _,m in pairs(v) do
					r[m] = true
				end
			else
				r[v] = true
			end
			rawset(t, k, r)
		end
	})

	local normal = normalIndex
	local onMe = onMeIndex
	local nearMe = nearMeIndex
	
	local ft = plugin.fileTable
	
	----------------------------------------
	--- Testing
	ft["testVoice1"] = normal
	ft["testVoice2"] = normal
	ft["testVoice3"] = normal
	ft["testVoice4"] = normal
	
	----------------------------------------
	----- Icecrown Citadel
	----------------------------------------
	-- Lord Marrowgar
	ft[69057] = { normal, onMe }		-- Impale
	ft[69138] = { normal }				-- Coldflame
	ft[69076] = { "incoming" }			-- Bonestorm
	
end