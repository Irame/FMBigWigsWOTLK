-- Very empty for now
local plugin = {}

BigWigs.pluginCore:SetDefaultModulePrototype(plugin)

function plugin:OnInitialize()
	BigWigs:RegisterPlugin(self)
end

function plugin:OnEnable()
	if type(self.OnPluginEnable) == "function" then
		self:OnPluginEnable()
	end
	self:SendMessage("BigWigs_OnPluginEnable", self)
end

function plugin:OnDisable()
	if type(self.OnPluginDisable) == "function" then
		self:OnPluginDisable()
	end
	self:SendMessage("BigWigs_OnPluginDisable", self)
end

function plugin:IsBossModule() return end

do
	local raidList = {}
	for i = 1, 40 do
		raidList[i] = format("raid%d", i)
	end
	function plugin:GetRaidList()
		return raidList
	end
end

do
	local partyList = {}
	partyList[1] = "player"
	for i = 1, 4 do
		partyList[i+1] = format("party%d", i)
	end
	function plugin:GetPartyList()
		return partyList
	end
end

function plugin:GetGroupList()
	return GetNumRaidMembers() > 0 and plugin:GetRaidList() or plugin:GetPartyList()
end

function plugin:GetNumGroupMembers()
	return GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()+1
end

function plugin:IsInGroup()
	return (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0)
end

function plugin:IsInRaid()
	return GetNumRaidMembers() > 0
end

function plugin:UnitInGroup(unit)
	return UnitInParty(unit) or UnitInRaid(unit)
end

function plugin:UnitIsGroupOfficer(unit)
	return UnitIsRaidOfficer(unit) or UnitIsPartyLeader(unit)
end

function plugin:GetRightChannel(warning)
	local zoneType = select(2, IsInInstance())
	if zoneType == "pvp" or zoneType == "arena" then
		return "BATTLEGROUND"
	elseif GetRealNumRaidMembers() > 0 then
		return "RAID"..(warning and "_WARNING" or "")
	elseif GetRealNumPartyMembers() > 0 then
		return "PARTY"
	end
end
