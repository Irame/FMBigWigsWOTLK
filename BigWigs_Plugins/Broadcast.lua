-------------------------------------------------------------------------------
-- Module Declaration
--

local plugin = BigWigs:NewPlugin("Broadcast")
if not plugin then return end

-------------------------------------------------------------------------------
-- Locals
--

local output = "*** %s ***"
local L = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Plugins")

-------------------------------------------------------------------------------
-- Initialization
--

function plugin:OnPluginEnable()
	self:RegisterMessage("BigWigs_Broadcast")
end

-------------------------------------------------------------------------------
-- Event Handlers
--

function plugin:BigWigs_Broadcast(event, self, key, msg)
	if not msg or not broadcast or not BigWigs.db.profile.broadcast then return end

	-- only allowed to broadcast if we're in a party or raidleader/assistant
	local inRaid = GetRealNumRaidMembers() > 0
	if not inRaid and GetRealNumPartyMembers() == 0 then
		return
	elseif inRaid and not IsRaidLeader() and not IsRaidOfficer() then
		return
	end

	local clean = msg:gsub("(|c%x%x%x%x%x%x%x%x)", ""):gsub("(|r)", "")
	local o = output:format(clean)
	if BigWigs.db.profile.useraidchannel or not inRaid then
		SendChatMessage(o, inRaid and "RAID" or "PARTY")
	else
		SendChatMessage(o, "RAID_WARNING")
	end
end
