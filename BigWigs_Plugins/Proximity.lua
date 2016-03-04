-------------------------------------------------------------------------------
-- Module Declaration
--

local plugin = BigWigs:NewPlugin("Proximity")
if not plugin then return end

plugin.defaultDB = {
	posx = nil,
	posy = nil,
	showTitle = true,
	showBackground = true,
	showSound = true,
	showClose = true,
	showAbility = true,
	showTooltip = true,
	lock = nil,
	width = 100,
	height = 80,
	sound = true,
	disabled = nil,
	proximity = true,
	font = nil,
	fontSize = nil,
	graphical = true,
	soundDelay = 1,
	soundName = "BigWigs: Alarm",
}

-------------------------------------------------------------------------------
-- Locals
--

local AceGUI = nil
local L = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Plugins")

local media = LibStub("LibSharedMedia-3.0")
local mute = "Interface\\AddOns\\BigWigs\\Textures\\icons\\mute"
local unmute = "Interface\\AddOns\\BigWigs\\Textures\\icons\\unmute"

local inConfigMode = nil
local activeProximityFunction = nil
local activeRange = nil
local activeSpellID = nil
local activeMap = nil
local maxPlayers = 0
local classCache = nil
local anchor = nil

local OnOptionToggled = nil -- Function invoked when the proximity option is toggled on a module.

local hexColors = {}
local vertexColors = {}
for k, v in pairs(RAID_CLASS_COLORS) do
	hexColors[k] = ("|cff%02x%02x%02x"):format(v.r * 255, v.g * 255, v.b * 255)
	vertexColors[k] = { v.r, v.g, v.b }
end

-- Helper table to cache colored player names.
local coloredNames = setmetatable({}, {__index =
	function(self, key)
		if type(key) == "nil" then return nil end
		local _, class = UnitClass(key)
		if class then
			self[key] = hexColors[class] .. key .. "|r"
			return self[key]
		else
			return key
		end
	end
})

--Radial upvalues
local GetPlayerMapPosition = GetPlayerMapPosition
local GetPlayerFacing = GetPlayerFacing
local format = string.format
local UnitInRange = UnitInRange
local UnitIsDead = UnitIsDead
local UnitIsUnit = UnitIsUnit
local GetTime = GetTime
local min = math.min
local pi = math.pi
local cos = math.cos
local sin = math.sin
local tremove = table.remove
local unpack = unpack

-------------------------------------------------------------------------------
-- Range functions
--

local bandages = {
	34722, -- Heavy Frostweave Bandage
	34721, -- Frostweave Bandage
	21991, -- Heavy Netherweave Bandage
	21990, -- Netherweave Bandage
	14530, -- Heavy Runecloth Bandage
	14529, -- Runecloth Bandage
	8545, -- Heavy Mageweave Bandage
	8544, -- Mageweave Bandage
	6451, -- Heavy Silk Bandage
	6450, -- Silk Bandage
	3531, -- Heavy Wool Bandage
	3530, -- Wool Bandage
	2581, -- Heavy Linen Bandage
	1251, -- Linen Bandage
}

local ranges = {
	[15] = function(unit)
		for i, v in next, bandages do
			local r = IsItemInRange(v, unit)
			if type(r) == "number" then
				if r == 1 then return true end
				break
			end
		end
	end,
}

do
	local checkInteractDistance = nil
	local _, r = UnitRace("player")
	if r == "Tauren" then
		checkInteractDistance = { [3] = 6, [2] = 7, [4] = 25 }
	elseif r == "Scourge" then
		checkInteractDistance = { [3] = 7, [2] = 8, [4] = 27 }
	else
		checkInteractDistance = { [3] = 8, [2] = 9, [4] = 28 }
	end
	for index, range in pairs(checkInteractDistance) do
		ranges[range] = function(unit) return CheckInteractDistance(unit, index) end
	end

	local spells = {
		DEATHKNIGHT = { 61999, 49892, 49016 }, -- Raise Ally works even on players that are alive oO
		DRUID = { 5185, 467, 1126 },
		-- HUNTER = { 34477 }, -- Misdirect is like 100y range, so forget it!
		HUNTER = {},
		MAGE = { 475, 1459 },
		PALADIN = { 635, 19740, 20473 },
		PRIEST = { 2050, 1243 },
		ROGUE = { 57934 },
		SHAMAN = { 331, 526 },
		WARRIOR = { 50720 }, -- Can't use Intervene since it has a minimum range.
		WARLOCK = { 5697 },
	}
	local _, class = UnitClass("player")
	local mySpells = spells[class]
	-- Gift of the Naaru
	if r == "Draenei" then tinsert(mySpells, 28880) end
	if mySpells then
		for i, spell in next, mySpells do
			local name, _, _, _, _, _, _, minRange, range = GetSpellInfo(spell)
			if name and range then
				local works = IsSpellInRange(name, "player")
				if type(works) == "number" then
					range = math.floor(range + 0.5)
					if range == 0 then range = 5 end
					if not ranges[range] then
						ranges[range] = function(unit)
							if IsSpellInRange(name, unit) == 1 then return true end
						end
					end
				end
			end
		end
	end
end

local mapData = {
	Arathi = {{3599.99987792969, 2399.99992370605}},
	Ogrimmar = {{1402.6044921875, 935.416625976563}},
	Undercity = {{959.375030517578, 640.104125976563}},
	Barrens = {{10133.3330078125, 6756.24987792969}},
	Darnassis = {{1058.33325195313, 705.7294921875}},
	AzuremystIsle = {{4070.8330078125, 2714.5830078125}},
	UngoroCrater = {{3699.99981689453, 2466.66650390625}},
	BurningSteppes = {{2929.16659545898, 1952.08349609375}},
	Wetlands = {{4135.41668701172, 2756.25}},
	Winterspring = {{7099.99984741211, 4733.33325195313}},
	Dustwallow = {{5250.00006103516, 3499.99975585938}},
	Darkshore = {{6549.99975585938, 4366.66650390625}},
	LochModan = {{2758.33312988281, 1839.5830078125}},
	BladesEdgeMountains = {{5424.99975585938, 3616.66638183594}},
	Durotar = {{5287.49963378906, 3524.99987792969}},
	Silithus = {{3483.333984375, 2322.916015625}},
	ShattrathCity = {{1306.25, 870.833374023438}},
	Ashenvale = {{5766.66638183594, 3843.74987792969}},
	Azeroth = {{40741.181640625, 27149.6875}},
	Nagrand = {{5525.0, 3683.33316802979}},
	TerokkarForest = {{5399.99975585938, 3600.00006103516}},
	EversongWoods = {{4925.0, 3283.3330078125}},
	SilvermoonCity = {{1211.45849609375, 806.7705078125}},
	Tanaris = {{6899.99952697754, 4600.0}},
	Stormwind = {{1737.499958992, 1158.3330078125}},
	SwampOfSorrows = {{2293.75, 1529.1669921875}},
	EasternPlaguelands = {{4031.25, 2687.49987792969}},
	BlastedLands = {{3349.99987792969, 2233.333984375}},
	Elwynn = {{3470.83325195313, 2314.5830078125}},
	DeadwindPass = {{2499.99993896484, 1666.6669921875}},
	DunMorogh = {{4924.99975585938, 3283.33325195313}},
	TheExodar = {{1056.7705078125, 704.687744140625}},
	Felwood = {{5749.99963378906, 3833.33325195313}},
	Silverpine = {{4199.99975585938, 2799.99987792969}},
	ThunderBluff = {{1043.74993896484, 695.833312988281}},
	Hinterlands = {{3850.0, 2566.66662597656}},
	StonetalonMountains = {{4883.33312988281, 3256.24981689453}},
	Mulgore = {{5137.49987792969, 3424.99984741211}},
	Hellfire = {{5164.5830078125, 3443.74987792969}},
	Ironforge = {{790.625061035156, 527.6044921875}},
	ThousandNeedles = {{4399.99969482422, 2933.3330078125}},
	Stranglethorn = {{6381.24975585938, 4254.166015625}},
	Badlands = {{2487.5, 1658.33349609375}},
	Teldrassil = {{5091.66650390625, 3393.75}},
	Moonglade = {{2308.33325195313, 1539.5830078125}},
	ShadowmoonValley = {{5500.0, 3666.66638183594}},
	Tirisfal = {{4518.74987792969, 3012.49981689453}},
	Aszhara = {{5070.83276367188, 3381.24987792969}},
	Redridge = {{2170.83325195313, 1447.916015625}},
	BloodmystIsle = {{3262.4990234375, 2174.99993896484}},
	WesternPlaguelands = {{4299.99990844727, 2866.66653442383}},
	Alterac = {{2799.99993896484, 1866.66665649414}},
	Westfall = {{3499.99981689453, 2333.3330078125}},
	Duskwood = {{2699.99993896484, 1800.0}},
	Netherstorm = {{5574.99967193604, 3716.66674804688}},
	Ghostlands = {{3300.0, 2199.99951171875}},
	Zangarmarsh = {{5027.08349609375, 3352.08325195313}},
	Desolace = {{4495.8330078125, 2997.91656494141}},
	Kalimdor = {{36799.810546875, 24533.2001953125}},
	SearingGorge = {{2231.24984741211, 1487.49951171875}},
	--Expansion01 = {{17464.078125, 11642.71875}},
	Feralas = {{6949.99975585938, 4633.3330078125}},
	Hilsbrad = {{3199.99987792969, 2133.33325195313}},
	Sunwell = {{3327.0830078125, 2218.7490234375}},
	Northrend = {{17751.3984375, 11834.2650146484}},
	BoreanTundra = {{5764.5830078125, 3843.74987792969}},
	Dragonblight = {{5608.33312988281, 3739.58337402344}},
	GrizzlyHills = {{5249.99987792969, 3499.99987792969}},
	HowlingFjord = {{6045.83288574219, 4031.24981689453}},
	IcecrownGlacier = {{6270.83331298828, 4181.25}},
	SholazarBasin = {{4356.25, 2904.16650390625}},
	TheStormPeaks = {{7112.49963378906, 4741.666015625}},
	ZulDrak = {{4993.75, 3329.16650390625}},
	ScarletEnclave = {{3162.5, 2108.33337402344}},
	CrystalsongForest = {{2722.91662597656, 1814.5830078125}},
	LakeWintergrasp = {{2974.99987792969, 1983.33325195313}},
	StrandoftheAncients = {{1743.74993896484, 1162.49993896484}},
	Naxxramas = {
		{1093.830078125, 729.219970703125},
		{1093.830078125, 729.219970703125},
		{1200.0, 800.0},
		{1200.330078125, 800.219970703125},
		{2069.80981445313, 1379.8798828125},
		{655.93994140625, 437.2900390625},
	},
	TheForgeofSouls = {{1448.09985351563, 965.400390625}},
	AlteracValley = {{4237.49987792969, 2824.99987792969}},
	WarsongGulch = {{1145.83331298828, 764.583312988281}},
	IsleofConquest = {{2650.0, 1766.66658401489}},
	TheArgentColiseum = {
		{369.986186981201, 246.657989501953},
		{739.996017456055, 493.330017089844}
	},
	HrothgarsLanding = {{3677.08312988281, 2452.083984375}},
	AzjolNerub = {
		{752.973999023438, 501.983001708984},
		{292.973999023438, 195.315979003906},
		{367.5, 245.0}
	},
	Ulduar77 = {{920.196014404297, 613.466064453125}},
	DrakTharonKeep = {
		{619.941009521484, 413.293991088867},
		{619.941009521484, 413.293991088867}
	},
	HallsofReflection = {{879.02001953125, 586.01953125}},
	TheObsidianSanctum = {{1162.49991798401, 775.0}},
	HallsofLightning = {
		{566.235015869141, 377.489990234375},
		{708.237014770508, 472.160034179688}
	},
	IcecrownCitadel = {
		{1355.47009277344, 903.647033691406},
		{1067.0, 711.333690643311},
		{195.469970703125, 130.315002441406},
		{773.710083007813, 515.810302734375},
		{1148.73999023438, 765.820068359375},
		{373.7099609375, 249.1298828125},
		{293.260009765625, 195.507019042969},
		{247.929931640625, 165.287994384766}
	},
	VioletHold = {{256.22900390625, 170.820068359375}},
	NetherstormArena = {{2270.83319091797, 1514.58337402344}},
	CoTStratholme = {{1125.29998779297, 750.199951171875}},
	TheEyeofEternity = {{430.070068359375, 286.713012695313}},
	Nexus80 = {
		{514.706970214844, 343.138977050781},
		{664.706970214844, 443.138977050781},
		{514.706970214844, 343.138977050781},
		{294.700988769531, 196.463989257813}
	},
	VaultofArchavon = {{2599.99987792969, 1733.33325195313}},
	VaultofArchavon1 = {{1398.25500488281, 932.170013427734}},
	Ulduar = {
		{669.450988769531, 446.300048828125},
		{1328.46099853516, 885.639892578125},
		{910.5, 607.0},
		{1569.4599609375, 1046.30004882813},
		{619.468994140625, 412.97998046875}
	},
	Dalaran = {
		{830.015014648438, 553.33984375},
		{563.223999023438, 375.48974609375}
	},
	Gundrak = {{905.033050537109, 603.35009765625}},
	TheNexus = {{1101.2809753418, 734.1875}},
	PitofSaron = {{1533.33331298828, 1022.91667175293}},
	Ahnkahet = {{972.41796875, 648.279022216797}},
	ArathiBasin = {{1756.24992370605, 1170.83325195313}},
	UtgardePinnacle = {
		{548.936019897461, 365.957015991211},
		{756.179943084717, 504.119003295898}
	},
	UtgardeKeep = {
		{734.580993652344, 489.721500396729},
		{481.081008911133, 320.720293045044},
		{736.581008911133, 491.054512023926}
	},
	TheRubySanctum = {{752.083312988281, 502.083251953125}},
}

local function findClosest(toRange)
	local closest = 15
	local closestDiff = math.abs(toRange - 15)
	for range, func in pairs(ranges) do
		local diff = math.abs(toRange - range)
		if diff < closestDiff then
			closest = range
			closestDiff = diff
		end
	end
	return ranges[closest], closest
end

local function getClosestRangeFunction(toRange)
	if ranges[toRange] then return ranges[toRange], toRange end
	SetMapToCurrentZone()
	local floors = mapData[(GetMapInfo())]
	if not floors then return findClosest(toRange) end
	local currentFloor = GetCurrentMapDungeonLevel()
	if currentFloor == 0 then currentFloor = 1 end
	local id = floors[currentFloor]
	if not ranges[id] then
		ranges[id] = function(unit, srcX, srcY)
			local dstX, dstY = GetPlayerMapPosition(unit)
			local x = (dstX - srcX) * id[1]
			local y = (dstY - srcY) * id[2]
			return (x*x + y*y) ^ 0.5 < activeRange
		end
	end
	return ranges[id], toRange
end

--------------------------------------------------------------------------------
-- Options
--

local function updateSoundButton()
	if not anchor then return end
	anchor.sound:SetNormalTexture(plugin.db.profile.sound and unmute or mute)
end
local function toggleSound()
	plugin.db.profile.sound = not plugin.db.profile.sound
	updateSoundButton()
end

-------------------------------------------------------------------------------
-- Display Window
--

local function onDragStart(self) self:StartMoving() end
local function onDragStop(self)
	self:StopMovingOrSizing()
	local s = self:GetEffectiveScale()
	plugin.db.profile.posx = self:GetLeft() * s
	plugin.db.profile.posy = self:GetTop() * s
end
local function OnDragHandleMouseDown(self) self.frame:StartSizing("BOTTOMRIGHT") end
local function OnDragHandleMouseUp(self, button) self.frame:StopMovingOrSizing() end
local function onResize(self, width, height)
	plugin.db.profile.width = width
	plugin.db.profile.height = height
	if inConfigMode then
		if plugin.db.profile.graphical then
			testDots()
			anchor.text:Hide()
		else
			hideDots()
			anchor.rangeCircle:Hide()
			anchor.playerDot:Hide()
			anchor.text:Show()
		end
	else
		local width, height = anchor:GetWidth(), anchor:GetHeight()
		local range = activeRange and activeRange or 10
		local pixperyard = min(width, height) / (range*3)
		anchor.rangeCircle:SetSize(range*2*pixperyard, range*2*pixperyard)
	end
end

local function setConfigureTarget(self, button)
	if not inConfigMode or button ~= "LeftButton" then return end
	plugin:SendMessage("BigWigs_SetConfigureTarget", plugin)
end

local function onDisplayEnter(self)
	if not plugin.db.profile.showTooltip then return end
	if not activeSpellID and not inConfigMode then return end
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	GameTooltip:SetHyperlink("spell:" .. (activeSpellID or 44318))
	GameTooltip:Show()
end
local locked = nil
local function lockDisplay()
	if locked then return end
	anchor:EnableMouse(false)
	anchor:SetMovable(false)
	anchor:SetResizable(false)
	anchor:RegisterForDrag()
	anchor:SetScript("OnSizeChanged", nil)
	anchor:SetScript("OnDragStart", nil)
	anchor:SetScript("OnDragStop", nil)
	anchor:SetScript("OnMouseUp", nil)
	anchor.drag:Hide()
	locked = true
end
local function unlockDisplay()
	if not locked then return end
	anchor:EnableMouse(true)
	anchor:SetMovable(true)
	anchor:SetResizable(true)
	anchor:RegisterForDrag("LeftButton")
	anchor:SetScript("OnSizeChanged", onResize)
	anchor:SetScript("OnDragStart", onDragStart)
	anchor:SetScript("OnDragStop", onDragStop)
	anchor:SetScript("OnMouseUp", setConfigureTarget)
	anchor.drag:Show()
	locked = nil
end

local function onControlEnter(self)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	GameTooltip:AddLine(self.tooltipHeader)
	GameTooltip:AddLine(self.tooltipText, 1, 1, 1, 1)
	GameTooltip:Show()
end
local function onControlLeave() GameTooltip:Hide() end

local function onNormalClose()
	if active then
		BigWigs:Print(L["The proximity display will show next time. To disable it completely for this encounter, you need to toggle it off in the encounter options."])
	end
	plugin:Close()
end

local function breakThings()
	anchor.sound:SetScript("OnEnter", nil)
	anchor.sound:SetScript("OnLeave", nil)
	anchor.sound:SetScript("OnClick", nil)
	anchor.close:SetScript("OnEnter", nil)
	anchor.close:SetScript("OnLeave", nil)
	anchor.close:SetScript("OnClick", nil)
end

local function makeThingsWork()
	anchor.sound:SetScript("OnEnter", onControlEnter)
	anchor.sound:SetScript("OnLeave", onControlLeave)
	anchor.sound:SetScript("OnClick", toggleSound)
	anchor.close:SetScript("OnEnter", onControlEnter)
	anchor.close:SetScript("OnLeave", onControlLeave)
	anchor.close:SetScript("OnClick", onNormalClose)
end

local function ensureDisplay()
	if anchor then return end

	local display = CreateFrame("Frame", "BigWigsProximityAnchor", UIParent)
	display:SetWidth(plugin.db.profile.width)
	display:SetHeight(plugin.db.profile.height)
	display:SetMinResize(100, 30)
	display:SetClampedToScreen(true)
	display:EnableMouse(true)
	display:SetScript("OnEnter", onDisplayEnter)
	display:SetScript("OnLeave", onControlLeave)
	local bg = display:CreateTexture(nil, "PARENT")
	bg:SetAllPoints(display)
	bg:SetBlendMode("BLEND")
	bg:SetTexture(0, 0, 0, 0.3)
	display.background = bg

	local close = CreateFrame("Button", nil, display)
	close:SetPoint("BOTTOMRIGHT", display, "TOPRIGHT", -2, 2)
	close:SetHeight(16)
	close:SetWidth(16)
	close.tooltipHeader = L["Close"]
	close.tooltipText = L["Closes the proximity display.\n\nTo disable it completely for any encounter, you have to go into the options for the relevant boss module and toggle the 'Proximity' option off."]
	close:SetNormalTexture("Interface\\AddOns\\BigWigs\\Textures\\icons\\close")
	display.close = close

	local sound = CreateFrame("Button", nil, display)
	sound:SetPoint("BOTTOMLEFT", display, "TOPLEFT", 2, 2)
	sound:SetHeight(16)
	sound:SetWidth(16)
	sound.tooltipHeader = L["Toggle sound"]
	sound.tooltipText = L["Toggle whether or not the proximity window should beep when you're too close to another player."]
	display.sound = sound

	local header = display:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	header:SetText(L["%d yards"]:format(0))
	header:SetPoint("BOTTOM", display, "TOP", 0, 4)
	display.title = header

	local abilityName = display:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	abilityName:SetText(L["|T%s:20:20:-5|tAbility name"]:format("Interface\\Icons\\spell_nature_chainlightning"))
	abilityName:SetPoint("BOTTOM", header, "TOP", 0, 4)
	display.ability = abilityName

	local text = display:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	text:SetText("")
	text:SetAllPoints(display)
	display.text = text
	display:SetScript("OnShow", function()
		if inConfigMode then
			text:SetText("|cffaad372Legolasftw|r\n|cfff48cbaTirionman|r\n|cfffff468Sneakystab|r\n|cffc69b6dIamconanok|r")
		else
			text:SetText("|cff777777:-)|r")
		end
	end)
	
	local rangeCircle = display:CreateTexture(nil, "ARTWORK")
	rangeCircle:SetPoint("CENTER")
	rangeCircle:SetTexture([[Interface\AddOns\BigWigs\Textures\alert_circle]])
	rangeCircle:SetBlendMode("ADD")
	display.rangeCircle = rangeCircle

	local playerDot = display:CreateTexture(nil, "OVERLAY")
	playerDot:SetSize(32, 32)
	playerDot:SetTexture([[Interface\Minimap\MinimapArrow]])
	playerDot:SetBlendMode("ADD")
	playerDot:SetPoint("CENTER")
	display.playerDot = playerDot
	
	local drag = CreateFrame("Frame", nil, display)
	drag.frame = display
	drag:SetFrameLevel(display:GetFrameLevel() + 10) -- place this above everything
	drag:SetWidth(16)
	drag:SetHeight(16)
	drag:SetPoint("BOTTOMRIGHT", display, -1, 1)
	drag:EnableMouse(true)
	drag:SetScript("OnMouseDown", OnDragHandleMouseDown)
	drag:SetScript("OnMouseUp", OnDragHandleMouseUp)
	drag:SetAlpha(0.5)
	display.drag = drag

	local tex = drag:CreateTexture(nil, "BACKGROUND")
	tex:SetTexture("Interface\\AddOns\\BigWigs\\Textures\\draghandle")
	tex:SetWidth(16)
	tex:SetHeight(16)
	tex:SetBlendMode("ADD")
	tex:SetPoint("CENTER", drag)

	anchor = display

	local x = plugin.db.profile.posx
	local y = plugin.db.profile.posy
	if x and y then
		local s = display:GetEffectiveScale()
		display:ClearAllPoints()
		display:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s)
	else
		display:ClearAllPoints()
		display:SetPoint("CENTER", UIParent)
	end

	plugin:RestyleWindow()
end

function plugin:RestyleWindow()
	updateSoundButton()
	if self.db.profile.showAbility then
		anchor.ability:Show()
	else
		anchor.ability:Hide()
	end
	if self.db.profile.showTitle then
		anchor.title:Show()
	else
		anchor.title:Hide()
	end
	if self.db.profile.showBackground then
		anchor.background:Show()
	else
		anchor.background:Hide()
	end
	if self.db.profile.showSound then
		anchor.sound:Show()
	else
		anchor.sound:Hide()
	end
	if self.db.profile.showClose then
		anchor.close:Show()
	else
		anchor.close:Hide()
	end
	anchor.text:SetFont(media:Fetch("font", self.db.profile.font), self.db.profile.fontSize)
	if self.db.profile.lock then
		locked = nil
		lockDisplay()
	else
		locked = true
		unlockDisplay()
	end
end

-------------------------------------------------------------------------------
-- Proximity Updater
--

local updater = nil
local graphicalUpdater, textUpdater = nil, nil
do
	local proxDots = {}
	local cacheDots = {}
	local lastplayed = 0 -- When we last played an alarm sound for proximity.
	-- dx and dy are in yards
	-- class is player class
	-- facing is radians with 0 being north, counting up clockwise
	setDot = function(dx, dy, class)
		local width, height = anchor:GetWidth(), anchor:GetHeight()
		local range = activeRange and activeRange or 10
		-- range * 3, so we have 3x radius space
		local pixperyard = min(width, height) / (range * 3)

		-- rotate relative to player facing
		local rotangle = (2 * pi) - GetPlayerFacing()
		local x = (dx * cos(rotangle)) - (-1 * dy * sin(rotangle))
		local y = (dx * sin(rotangle)) + (-1 * dy * cos(rotangle))

		x = x * pixperyard
		y = y * pixperyard

		local dot = nil
		if #cacheDots > 0 then
			dot = tremove(cacheDots)
		else
			dot = anchor:CreateTexture(nil, "OVERLAY")
			dot:SetSize(16, 16)
			dot:SetTexture([[Interface\AddOns\BigWigs\Textures\blip]])
		end
		proxDots[#proxDots + 1] = dot

		dot:ClearAllPoints()
		dot:SetPoint("CENTER", anchor, "CENTER", x, y)
		dot:SetVertexColor(unpack(vertexColors[class]))
		dot:Show()
	end

	hideDots = function()
		-- shuffle existing dots into cacheDots
		-- hide those cacheDots
		while #proxDots > 0 do
			proxDots[1]:Hide()
			cacheDots[#cacheDots + 1] = tremove(proxDots, 1)
		end
	end

	testDots = function()
		hideDots()
		setDot(10, 10, "WARLOCK", 0)
		setDot(5, 0, "HUNTER", 0)
		setDot(3, 10, "MAGE", 0)
		setDot(-9, -7, "PRIEST", 0)
		setDot(0, 10, "WARLOCK", 0)
		local width, height = anchor:GetWidth(), anchor:GetHeight()
		local pixperyard = min(width, height) / 30
		anchor.rangeCircle:SetSize(pixperyard * 20,  pixperyard * 20)
		anchor.rangeCircle:SetVertexColor(1,0,0)
		anchor.rangeCircle:Show()
		anchor.playerDot:Show()
	end

	local tooClose = {} -- List of players who are too close.
	local function updateProximityText()
		local srcX, srcY = GetPlayerMapPosition("player")
		if srcX == 0 and srcY == 0 then
			SetMapToCurrentZone()
			srcX, srcY = GetPlayerMapPosition("player")
		end
		for i = 1, maxPlayers do
			local n = format("raid%d", i)
			if UnitInRange(n) and not UnitIsDead(n) and not UnitIsUnit(n, "player") and activeProximityFunction(n, srcX, srcY) then
				local nextIndex = #tooClose + 1
				tooClose[nextIndex] = coloredNames[UnitName(n)]
				if nextIndex > 4 then break end
			end
		end

		if #tooClose == 0 then
			anchor.text:SetText("|cff777777:-)|r")
			lastplayed = 0
		else
			anchor.text:SetText(table.concat(tooClose, "\n"))
			wipe(tooClose)
			if not plugin.db.profile.sound then return end
			local t = GetTime()
			if t > (lastplayed + plugin.db.profile.soundDelay) and not UnitIsDead("player") then
				lastplayed = t
				plugin:SendMessage("BigWigs_Sound", plugin.db.profile.soundName)
			end
		end
	end
	
	local function updateProximityRadar()
		local srcX, srcY = GetPlayerMapPosition("player")
		if srcX == 0 and srcY == 0 then
			SetMapToCurrentZone()
			srcX, srcY = GetPlayerMapPosition("player")
		end

		-- XXX This could probably be checked and set when the proximity
		-- XXX display is opened? We won't change dungeon floors while
		-- XXX it is open, surely.
		local id = nil
		if activeMap then
			local currentFloor = GetCurrentMapDungeonLevel()
			if currentFloor == 0 then currentFloor = 1 end
			id = activeMap[currentFloor]
		end

		-- Fall back to text
		if not id then
			updater:SetScript("OnUpdate", textUpdater)
			anchor.text:Show()
			anchor.rangeCircle:Hide()
			anchor.playerDot:Hide()
			return updateProximityText()
		end

		local anyoneClose = nil

		-- XXX We can't show/hide dots every update, that seems excessive.
		hideDots()
		for i = 1, maxPlayers do
			local n = format("raid%d", i)
			if UnitInRange(n) and not UnitIsDead(n) and not UnitIsUnit(n, "player") then
				local unitX, unitY = GetPlayerMapPosition(n)
				local dx = (unitX - srcX) * id[1]
				local dy = (unitY - srcY) * id[2]
				local range = (dx * dx + dy * dy) ^ 0.5
				if range < (activeRange * 1.5) then
					setDot(dx, dy, classCache[i])
					if range <= activeRange then
						anyoneClose = true
					end
				end
			end
		end

		if not anyoneClose then
			lastplayed = 0
			anchor.rangeCircle:SetVertexColor(0, 1, 0)
		else
			anchor.rangeCircle:SetVertexColor(1, 0, 0)
			if not plugin.db.profile.sound then return end
			local t = GetTime()
			if t > (lastplayed + plugin.db.profile.soundDelay) and not UnitIsDead("player") then


				lastplayed = t
				plugin:SendMessage("BigWigs_Sound", plugin.db.profile.soundName)
			end
		end
	end
	updater = CreateFrame("Frame")
	updater:Hide()
	local total = 0

	-- 20x per second for radar mode
	function graphicalUpdater(self, elapsed)
		total = total + elapsed
		if total >= .05 then
			total = 0
			updateProximityRadar()
		end
	end
	-- 2 times per second for text mode
	function textUpdater(self, elapsed)
		total = total + elapsed
		if total >= .5 then
			total = 0

			updateProximityText()


		end

	end
end

local function updateProfile()
	if not anchor then return end

	anchor:SetWidth(plugin.db.profile.width)
	anchor:SetHeight(plugin.db.profile.height)

	local x = plugin.db.profile.posx
	local y = plugin.db.profile.posy
	if x and y then
		local s = anchor:GetEffectiveScale()
		anchor:ClearAllPoints()
		anchor:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s)
	else
		anchor:ClearAllPoints()
		anchor:SetPoint("CENTER", UIParent)
	end
end

local function resetAnchor()
	anchor:ClearAllPoints()
	anchor:SetPoint("CENTER", UIParent)
	anchor:SetWidth(plugin.defaultDB.width)
	anchor:SetHeight(plugin.defaultDB.height)
	plugin.db.profile.posx = nil
	plugin.db.profile.posy = nil
	plugin.db.profile.width = nil
	plugin.db.profile.height = nil
end

-------------------------------------------------------------------------------
--      Initialization
--

function plugin:OnRegister()
	BigWigs:RegisterBossOption("proximity", L["proximity"], L["proximity_desc"], OnOptionToggled)
	if CUSTOM_CLASS_COLORS then
		local function update()
			wipe(coloredNames)
			for k, v in pairs(CUSTOM_CLASS_COLORS) do
				hexColors[k] = ("|cff%02x%02x%02x"):format(v.r * 255, v.g * 255, v.b * 255)
				vertexColors[k] = { v.r, v.g, v.b }
			end
		end
		CUSTOM_CLASS_COLORS:RegisterCallback(update)
		update()
	end
	self:RegisterMessage("BigWigs_ProfileUpdate", updateProfile)
	local function iterateFloors(map, ...)
		for i = 1, select("#", ...), 2 do
			local w, h = select(i, ...)
			table.insert(mapData[map], { tonumber(w), tonumber(h) })
		end
	end
	local function iterateMaps(addonIndex, ...)
		for i = 1, select("#", ...) do
			local map = select(i, ...)
			local meta = GetAddOnMetadata(addonIndex, "X-BigWigs-MapSize-" .. map)
			if meta then
				if not mapData[map] then mapData[map] = {} end
				iterateFloors(map, strsplit(",", meta))
			end
		end
	end

	for i = 1, GetNumAddOns() do
		local meta = GetAddOnMetadata(i, "X-BigWigs-Maps")
		if meta then
			iterateMaps(i, strsplit(",", meta))
		end
	end

	if not plugin.db.profile.font then
		plugin.db.profile.font = media:GetDefault("font")
	end
	if not plugin.db.profile.fontSize then
		local _, size = GameFontNormalHuge:GetFont()
		plugin.db.profile.fontSize = size
	end
end

function plugin:OnPluginEnable()
	self:RegisterMessage("BigWigs_ShowProximity")
	self:RegisterMessage("BigWigs_HideProximity", "Close")
	self:RegisterMessage("BigWigs_OnBossDisable")

	self:RegisterMessage("BigWigs_StartConfigureMode")
	self:RegisterMessage("BigWigs_StopConfigureMode")
	self:RegisterMessage("BigWigs_SetConfigureTarget")
	self:RegisterMessage("BigWigs_ProfileUpdate", updateProfile)
	self:RegisterMessage("BigWigs_ResetPositions", resetAnchor)
end

function plugin:OnPluginDisable()
	self:Close()
end

-------------------------------------------------------------------------------
-- Options
--

function plugin:BigWigs_StartConfigureMode()
	inConfigMode = true
	self:Test()
end

function plugin:BigWigs_StopConfigureMode()
	inConfigMode = nil
	self:Close()
end

function plugin:BigWigs_SetConfigureTarget(event, module)
	ensureDisplay()
	if module == self then
		anchor.background:SetTexture(0.2, 1, 0.2, 0.3)
	else
		anchor.background:SetTexture(0, 0, 0, 0.3)
	end
end

do
	local function onControlEnter(widget, event, value)
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
		GameTooltip:AddLine(widget.text and widget.text:GetText() or widget.label:GetText())
		GameTooltip:AddLine(widget:GetUserData("tooltip"), 1, 1, 1, 1)
		GameTooltip:Show()
	end
	local function onControlLeave() GameTooltip:Hide() end

	local function checkboxCallback(widget, event, value)
		local key = widget:GetUserData("key")
		plugin.db.profile[key] = value and true or false
		plugin:RestyleWindow()
		if key == "graphical" then
			plugin:Test()
		end
	end
	
	local function dropdownCallback(widget, event, value)
		local list = media:List(widget:GetUserData("type"))
		plugin.db.profile[widget:GetUserData("key")] = list[value]
		plugin:RestyleWindow()
	end
	
	local function sliderCallback(widget, event, value)
		local key = widget:GetUserData("key")
		plugin.db.profile[key] = value
		plugin:RestyleWindow()
	end

	function plugin:GetPluginConfig()
		if not AceGUI then AceGUI = LibStub("AceGUI-3.0") end
		local disable = AceGUI:Create("CheckBox")
		disable:SetValue(self.db.profile.disabled)
		disable:SetLabel(L["Disabled"])
		disable:SetCallback("OnEnter", onControlEnter)
		disable:SetCallback("OnLeave", onControlLeave)
		disable:SetCallback("OnValueChanged", checkboxCallback)
		disable:SetUserData("tooltip", L["Disable the proximity display for all modules that use it."])
		disable:SetUserData("key", "disabled")
		disable:SetRelativeWidth(0.5)

		local lock = AceGUI:Create("CheckBox")
		lock:SetValue(self.db.profile.lock)
		lock:SetLabel(L["Lock"])
		lock:SetCallback("OnEnter", onControlEnter)
		lock:SetCallback("OnLeave", onControlLeave)
		lock:SetCallback("OnValueChanged", checkboxCallback)
		lock:SetUserData("tooltip", L["Locks the display in place, preventing moving and resizing."])
		lock:SetUserData("key", "lock")
		lock:SetRelativeWidth(0.5)
		
		local graphical = AceGUI:Create("CheckBox")
		graphical:SetValue(self.db.profile.graphical)
		graphical:SetLabel(L["Graphical display"])
		graphical:SetCallback("OnEnter", onControlEnter)
		graphical:SetCallback("OnLeave", onControlLeave)
		graphical:SetCallback("OnValueChanged", checkboxCallback)
		graphical:SetUserData("tooltip", L["Let the Proximity monitor display a graphical representation of people who might be too close to you instead of just a list of names. This only works for zones where Big Wigs has access to actual size information; for other zones it will fall back to the list of names."])
		graphical:SetUserData("key", "graphical")
		graphical:SetFullWidth(true)
		
		local font = AceGUI:Create("Dropdown")
		do
			local list = media:List("font")
			local selected = nil
			for k, v in pairs(list) do
				if v == plugin.db.profile.font then
					selected = k
					break
				end
			end
			font:SetList(list)
			font:SetValue(selected)
			font:SetLabel(L["Font"])
			font:SetUserData("type", "font")
			font:SetUserData("key", "font")
			font:SetCallback("OnValueChanged", dropdownCallback)
			font:SetFullWidth(true)
		end
		
		local fontSize = AceGUI:Create("Slider")
		fontSize:SetValue(self.db.profile.fontSize)
		fontSize:SetSliderValues(8, 40, 1)
		fontSize:SetLabel(L["Font size"])
		fontSize:SetUserData("key", "fontSize")
		fontSize:SetCallback("OnValueChanged", sliderCallback)
		fontSize:SetFullWidth(true)
		
		local soundName = AceGUI:Create("Dropdown")
		do
			local list = media:List("sound")
			local selected = nil
			for k, v in pairs(list) do
				if v == plugin.db.profile.soundName then
					selected = k
					break
				end
			end
			soundName:SetList(list)
			soundName:SetValue(selected)
			soundName:SetLabel(L["Sound"])
			soundName:SetUserData("type", "sound")
			soundName:SetUserData("key", "soundName")
			soundName:SetCallback("OnValueChanged", dropdownCallback)
			soundName:SetFullWidth(true)
		end
		
		local soundDelay = AceGUI:Create("Slider")
		soundDelay:SetValue(self.db.profile.soundDelay)
		soundDelay:SetSliderValues(1, 10, 1)
		soundDelay:SetLabel(L["Sound delay"])
		soundDelay:SetUserData("tooltip", L["Specify how long Big Wigs should wait between repeating the specified sound when someone is too close to you."])
		soundDelay:SetUserData("key", "soundDelay")
		soundDelay:SetCallback("OnValueChanged", sliderCallback)
		soundDelay:SetFullWidth(true)
		
		
		
		local showHide = AceGUI:Create("InlineGroup")
		showHide:SetTitle(L["Show/hide"])
		showHide:SetFullWidth(true)

		do
			local title = AceGUI:Create("CheckBox")
			title:SetValue(self.db.profile.showTitle)
			title:SetLabel(L["Title"])
			title:SetCallback("OnEnter", onControlEnter)
			title:SetCallback("OnLeave", onControlLeave)
			title:SetCallback("OnValueChanged", checkboxCallback)
			title:SetUserData("tooltip", L["Shows or hides the title."])
			title:SetUserData("key", "showTitle")
			title:SetFullWidth(true)

			local background = AceGUI:Create("CheckBox")
			background:SetValue(self.db.profile.showBackground)
			background:SetLabel(L["Background"])
			background:SetCallback("OnEnter", onControlEnter)
			background:SetCallback("OnLeave", onControlLeave)
			background:SetCallback("OnValueChanged", checkboxCallback)
			background:SetUserData("tooltip", L["Shows or hides the background."])
			background:SetUserData("key", "showBackground")
			background:SetFullWidth(true)

			local sound = AceGUI:Create("CheckBox")
			sound:SetValue(self.db.profile.showSound)
			sound:SetLabel(L["Sound button"])
			sound:SetCallback("OnEnter", onControlEnter)
			sound:SetCallback("OnLeave", onControlLeave)
			sound:SetCallback("OnValueChanged", checkboxCallback)
			sound:SetUserData("tooltip", L["Shows or hides the sound button."])
			sound:SetUserData("key", "showSound")
			sound:SetFullWidth(true)

			local close = AceGUI:Create("CheckBox")
			close:SetValue(self.db.profile.showClose)
			close:SetLabel(L["Close button"])
			close:SetCallback("OnEnter", onControlEnter)
			close:SetCallback("OnLeave", onControlLeave)
			close:SetCallback("OnValueChanged", checkboxCallback)
			close:SetUserData("tooltip", L["Shows or hides the close button."])
			close:SetUserData("key", "showClose")
			close:SetFullWidth(true)
			
			local ability = AceGUI:Create("CheckBox")
			ability:SetValue(self.db.profile.showAbility)
			ability:SetLabel(L["Ability name"])
			ability:SetCallback("OnEnter", onControlEnter)
			ability:SetCallback("OnLeave", onControlLeave)
			ability:SetCallback("OnValueChanged", checkboxCallback)
			ability:SetUserData("tooltip", L["Shows or hides the ability name above the window."])
			ability:SetUserData("key", "showAbility")
			ability:SetFullWidth(true)
			
			local gameTooltip = AceGUI:Create("CheckBox")
			gameTooltip:SetValue(self.db.profile.showAbility)
			gameTooltip:SetLabel(L["Tooltip"])
			gameTooltip:SetCallback("OnEnter", onControlEnter)
			gameTooltip:SetCallback("OnLeave", onControlLeave)
			gameTooltip:SetCallback("OnValueChanged", checkboxCallback)
			gameTooltip:SetUserData("tooltip", L["Shows or hides a spell tooltip if the Proximity display is currently tied directly to a boss encounter ability."])
			gameTooltip:SetUserData("key", "showTooltip")
			gameTooltip:SetFullWidth(true)

			showHide:AddChildren(title, background, sound, close, ability, gameTooltip)
		end
		return disable, lock, graphical, font, fontSize, soundName, soundDelay, showHide
	end
end

-------------------------------------------------------------------------------
-- Events
--

do
	local opener = nil
	function plugin:BigWigs_ShowProximity(event, module, range, optionKey)
		if plugin.db.profile.disabled or type(range) ~= "number" then return end
		opener = module
		self:Open(range, module, optionKey)
	end

	function plugin:BigWigs_OnBossDisable(event, module)
		if module ~= opener then return end
		self:Close()
	end
end

-------------------------------------------------------------------------------
-- API
--

function plugin:Close()
	activeProximityFunction = nil
	activeRange = nil
	activeSpellID = nil
	activeMap = nil
	if classCache then
		wipe(classCache)
		classCache = nil
	end
	if anchor then
		anchor.title:SetText(L["%d yards"]:format(0))
		anchor.ability:SetText(L["|T%s:20:20:-5|tAbility name"]:format("Interface\\Icons\\spell_nature_chainlightning"))
		-- Just in case we were the last target of
		-- configure mode, reset the background color.
		anchor.background:SetTexture(0, 0, 0, 0.3)
		anchor:Hide()
	end
	updater:SetScript("OnUpdate", nil)
	updater:Hide()
end

local abilityNameFormat = "|T%s:20:20:-5|t%s"
function plugin:Open(range, module, key)
	if type(range) ~= "number" then error("Range needs to be a number!") end
	-- Make sure the anchor is there
	ensureDisplay()
	-- Get the best range function for the given range
	local func, actualRange = getClosestRangeFunction(range)
	activeProximityFunction = func
	activeRange = actualRange
	maxPlayers = select(5, GetInstanceInfo())

	if not classCache then classCache = {} end
	for i=1, maxPlayers do
		local _, class = UnitClass(format("raid%d", i))
		classCache[i] = class
	end

	SetMapToCurrentZone()
	activeMap = mapData[(GetMapInfo())]
	hideDots()
	
	if activeMap and plugin.db.profile.graphical then
		local width, height = anchor:GetWidth(), anchor:GetHeight()
		local ppy = min(width, height) / (actualRange * 3)
		anchor.rangeCircle:SetSize(ppy * actualRange * 2, ppy * actualRange * 2)
		anchor.playerDot:Show()
		anchor.rangeCircle:Show()
		anchor.text:Hide()
		updater:SetScript("OnUpdate", graphicalUpdater)
	else
		anchor.rangeCircle:Hide()
		anchor.playerDot:Hide()
		anchor.text:Show()
		updater:SetScript("OnUpdate", textUpdater)
	end
	-- Update the header to reflect the actual range we're checking
	anchor.title:SetText(L["%d yards"]:format(actualRange))
	-- Update the ability name display
	if module and key then
		local dbKey, name, desc, icon = BigWigs:GetBossOptionDetails(module, key)
		if icon then
			anchor.ability:SetText(abilityNameFormat:format(icon, name))
		else
			anchor.ability:SetText(name)
		end
	else
		anchor.ability:SetText(L["Custom range indicator"])
	end
	if type(key) == "number" then
		activeSpellID = key
	else
		activeSpellID = nil
	end
	-- Unbreak the sound+close buttons
	makeThingsWork()
	-- Start the show!
	anchor:Show()
	updater:Show()
end

function plugin:Test()
	-- Make sure the anchor is there
	ensureDisplay()
	-- Close ourselves in case we entered configure mode DURING a boss fight.
	self:Close()
	-- Break the sound+close buttons
	breakThings()
	if plugin.db.profile.graphical then
		testDots()
		anchor.text:Hide()
	else
		hideDots()
		anchor.rangeCircle:Hide()
		anchor.playerDot:Hide()
		anchor.text:Show()
	end
	anchor:Show()
end

-------------------------------------------------------------------------------
-- Slash command
--

SlashCmdList.BigWigs_Proximity = function(input)
	if not plugin:IsEnabled() then BigWigs:Enable() end
	local range = tonumber(input)
	if not range then
		plugin:Close()
		print("Usage: /proximity 1-100")
	else
		if range > 0 then
			plugin:Open(range)
		else
			plugin:Close()
		end
	end
end
SLASH_BigWigs_Proximity1 = "/proximity"
SLASH_BigWigs_Proximity2 = "/bwproximity" -- In case some other addon already has /proximity


-- Apparently some users (idiots?) don't read through the interface options before using
-- a complicated addon such as BigWigs. Go figure.
SLASH_BigWigs_Proximity3 = "/range"
