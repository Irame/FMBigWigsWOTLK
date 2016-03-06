--------------------------------------------------------------------------------
-- Module Declaration
--

local plugin = BigWigs:NewPlugin("Health Bars")
if not plugin then return end

--------------------------------------------------------------------------------
-- Locals
--

local colorize = nil
do
	local r, g, b
	colorize = setmetatable({}, { __index =
		function(self, key)
			if not r then r, g, b = GameFontNormal:GetTextColor() end
			self[key] = "|cff" .. string.format("%02x%02x%02x", r * 255, g * 255, b * 255) .. key .. "|r"
			return self[key]
		end
	})
end

local L = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Plugins")

local AceGUI = nil

local colors = nil
local superemp = nil
local staticCandy = LibStub("LibStaticCandyBar-1.0")
local media = LibStub("LibSharedMedia-3.0")
local powerColor = PowerBarColor
local db = nil
local normalAnchor = nil
local powerTypes = {MANA = 0,RAGE = 1, FOCUS = 2, ENERGY = 3, UNUSED = 4, RUNES = 5, RUNIC_POWER = 6, [0] = "MANA", [1] = "RAGE", [2] = "FOCUS", [3] = "ENERGY", [4] = "UNUSED", [5] = "RUNES", [6] = "RUNIC_POWER"}

--- custom bar locals
local times = nil
local messages = nil
local timers = nil
local fmt = string.format

local clickHandlers = {}

--------------------------------------------------------------------------------
-- Options
--

plugin.defaultDB = {
	scale = 1.0,
	texture = "BantoBar",
	font = "Friz Quadrata TT",
	growup = true,
	icon = true,
	value = true,
	maxValue = true,
	percent = true,
	align = "LEFT",
	BigWigsAnchor_width = 200,
	interceptMouse = nil,
	LeftButton = {
		report = true,
	},
	MiddleButton = {
		remove = true,
	},
	RightButton = {
		disable = true,
	},
}

local clickOptions = {
	report = {
		type = "toggle",
		name = colorize[L["Report"]],
		desc = L["Reports the current bars status to the active group chat; either battleground, raid, party or guild, as appropriate."],
		descStyle = "inline",
		order = 2,
	},
	remove = {
		type = "toggle",
		name = colorize[L["Remove"]],
		desc = L["Temporarily removes the bar and all associated messages."],
		descStyle = "inline",
		order = 3,
	},
	removeOther = {
		type = "toggle",
		name = colorize[L["Remove other"]],
		desc = L["Temporarily removes all other bars (except this one) and associated messages."],
		descStyle = "inline",
		order = 4,
	},
	disable = {
		type = "toggle",
		name = colorize[L["Disable"]],
		desc = L["Permanently disables the boss encounter ability option that spawned this bar."],
		descStyle = "inline",
		order = 5,
	},
}

local function shouldDisable() return not plugin.db.profile.interceptMouse end

plugin.subPanelOptions = {
	key = "Big Wigs: Clickable Health Bars",
	name = L["Clickable Health Bars"],
	options = {
		name = L["Clickable Health Bars"],
		type = "group",
		childGroups = "tab",
		args = {
			heading = {
				type = "description",
				name = L.clickableBarsDesc,
				order = 1,
				width = "full",
				fontSize = "medium",
			},
			interceptMouse = {
				type = "toggle",
				name = colorize[L["Enable"]],
				desc = L["Enables bars to receive mouse clicks."],
				order = 2,
				width = "full",
				get = function() return plugin.db.profile.interceptMouse end,
				set = function(_, value) plugin.db.profile.interceptMouse = value end,
			},
			left = {
				type = "group",
				name = KEY_BUTTON1 or "Left",
				order = 10,
				args = clickOptions,
				disabled = shouldDisable,
				get = function(info) return plugin.db.profile.LeftButton[info[#info]] end,
				set = function(info, value) plugin.db.profile.LeftButton[info[#info]] = value end,
			},
			middle = {
				type = "group",
				name = KEY_BUTTON3 or "Middle",
				order = 11,
				args = clickOptions,
				disabled = shouldDisable,
				get = function(info) return plugin.db.profile.MiddleButton[info[#info]] end,
				set = function(info, value) plugin.db.profile.MiddleButton[info[#info]] = value end,
			},
			right = {
				type = "group",
				name = KEY_BUTTON2 or "Right",
				order = 12,
				args = clickOptions,
				disabled = shouldDisable,
				get = function(info) return plugin.db.profile.RightButton[info[#info]] end,
				set = function(info, value) plugin.db.profile.RightButton[info[#info]] = value end,
			},
		},
	},
}

--------------------------------------------------------------------------------
-- Bar arrangement
--

local function barSorter(a, b)
	return a.remaining < b.remaining and true or false
end
local tmp = {}
local function rearrangeBars(anchor)
	wipe(tmp)
	for bar in pairs(anchor.bars) do
		tmp[#tmp + 1] = bar
	end
	local lastDownBar, lastUpBar = nil, nil
	local up = nil
	up = db.growup
	for i, bar in next, tmp do
		bar:ClearAllPoints()
		if up then
			bar:SetPoint("BOTTOMLEFT", lastUpBar or anchor, "TOPLEFT")
			bar:SetPoint("BOTTOMRIGHT", lastUpBar or anchor, "TOPRIGHT")
			lastUpBar = bar
		else
			bar:SetPoint("TOPLEFT", lastDownBar or anchor, "BOTTOMLEFT")
			bar:SetPoint("TOPRIGHT", lastDownBar or anchor, "BOTTOMRIGHT")
			lastDownBar = bar
		end
		bar:SetValue(bar:GetValue())
	end
end

local function barStopped(event, bar)
	local a = bar:Get("bigwigs:anchor")
	if a and a.bars and a.bars[bar] then
		a.bars[bar] = nil
		rearrangeBars(a)
	end
end

--------------------------------------------------------------------------------
-- Anchors
--
local defaultPositions = {
	BigWigsAnchor = {"CENTER", "UIParent", "CENTER", 0, -150},
}

local function onDragHandleMouseDown(self) self:GetParent():StartSizing("BOTTOMRIGHT") end
local function onDragHandleMouseUp(self, button) self:GetParent():StopMovingOrSizing() end
local function onResize(self, width)
	db[self.w] = width
	rearrangeBars(self)
end
local function onDragStart(self) self:StartMoving() end
local function onDragStop(self)
	self:StopMovingOrSizing()
	local s = self:GetEffectiveScale()
	db[self.x] = self:GetLeft() * s
	db[self.y] = self:GetTop() * s
end

local function onControlEnter(self)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	GameTooltip:AddLine(self.tooltipHeader)
	GameTooltip:AddLine(self.tooltipText, 1, 1, 1, 1)
	GameTooltip:Show()
end
local function onControlLeave() GameTooltip:Hide() end

local function createAnchor(frameName, title)
	local display = CreateFrame("Frame", frameName, UIParent)
	local wKey, xKey, yKey = frameName .. "_width", frameName .. "_x", frameName .. "_y"
	display.w, display.x, display.y = wKey, xKey, yKey
	display:EnableMouse(true)
	display:SetClampedToScreen(true)
	display:SetMovable(true)
	display:SetResizable(true)
	display:RegisterForDrag("LeftButton")
	display:SetWidth(db[wKey] or 200)
	display:SetHeight(20)
	display:SetMinResize(80, 20)
	display:SetMaxResize(1920, 20)
	display:ClearAllPoints()
	if db[xKey] and db[yKey] then
		local s = display:GetEffectiveScale()
		display:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db[xKey] / s, db[yKey] / s)
	else
		display:SetPoint(unpack(defaultPositions[frameName]))
	end
	local bg = display:CreateTexture(nil, "PARENT")
	bg:SetAllPoints(display)
	bg:SetBlendMode("BLEND")
	bg:SetTexture(0, 0, 0, 0.3)
	display.background = bg
	local header = display:CreateFontString(nil, "OVERLAY")
	header:SetFontObject(GameFontNormal)
	header:SetText(title)
	header:SetAllPoints(display)
	header:SetJustifyH("CENTER")
	header:SetJustifyV("MIDDLE")
	local drag = CreateFrame("Frame", nil, display)
	drag:SetFrameLevel(display:GetFrameLevel() + 10)
	drag:SetWidth(16)
	drag:SetHeight(16)
	drag:SetPoint("BOTTOMRIGHT", display, -1, 1)
	drag:EnableMouse(true)
	drag:SetScript("OnMouseDown", onDragHandleMouseDown)
	drag:SetScript("OnMouseUp", onDragHandleMouseUp)
	drag:SetAlpha(0.5)
	local tex = drag:CreateTexture(nil, "BACKGROUND")
	tex:SetTexture("Interface\\AddOns\\BigWigs\\Textures\\draghandle")
	tex:SetWidth(16)
	tex:SetHeight(16)
	tex:SetBlendMode("ADD")
	tex:SetPoint("CENTER", drag)
	display:SetScript("OnSizeChanged", onResize)
	display:SetScript("OnDragStart", onDragStart)
	display:SetScript("OnDragStop", onDragStop)
	display:SetScript("OnMouseUp", function(self, button)
		if button ~= "LeftButton" then return end
		plugin:SendMessage("BigWigs_SetConfigureTarget", plugin)
	end)
	display.bars = {}
	display:Hide()
	return display
end

local function createAnchors()
	if not normalAnchor then
		normalAnchor = createAnchor("BigWigsAnchor", L["Health bars"])
	end
end

local function showAnchors()
	if not normalAnchor then createAnchors() end
	normalAnchor:Show()
end

local function hideAnchors()
	normalAnchor:Hide()
end

local function resetAnchors()
	normalAnchor:ClearAllPoints()
	normalAnchor:SetPoint(unpack(defaultPositions[normalAnchor:GetName()]))
	db[normalAnchor.x] = nil
	db[normalAnchor.y] = nil
	db[normalAnchor.w] = nil
	normalAnchor:SetWidth(plugin.defaultDB[normalAnchor.w])
end

local function updateAnchor(anchor)
	local frameName = anchor:GetName()
	local wKey, xKey, yKey = frameName .. "_width", frameName .. "_x", frameName .. "_y"
	anchor.w, anchor.x, anchor.y = wKey, xKey, yKey
	if db[xKey] and db[yKey] then
		local s = anchor:GetEffectiveScale()
		anchor:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db[xKey] / s, db[yKey] / s)
	else
		anchor:SetPoint(unpack(defaultPositions[frameName]))
	end
	anchor:SetWidth(db[wKey] or 200)
end

local function updateProfile()
	db = plugin.db.profile
	if normalAnchor then
		updateAnchor(normalAnchor)
	end
end

--------------------------------------------------------------------------------
-- Initialization
--
function plugin:OnRegister()
	media:Register("statusbar", "Otravi", "Interface\\AddOns\\BigWigs\\Textures\\otravi")
	media:Register("statusbar", "Smooth", "Interface\\AddOns\\BigWigs\\Textures\\smooth")
	media:Register("statusbar", "Glaze", "Interface\\AddOns\\BigWigs\\Textures\\glaze")
	media:Register("statusbar", "Charcoal", "Interface\\AddOns\\BigWigs\\Textures\\Charcoal")
	media:Register("statusbar", "BantoBar", "Interface\\AddOns\\BigWigs\\Textures\\default")
	staticCandy.RegisterCallback(self, "LibStaticCandyBar_Stop", barStopped)

	db = self.db.profile
	self:RegisterMessage("BigWigs_ProfileUpdate", updateProfile)
end

function plugin:OnPluginEnable()
	times = times or {}
	messages = messages or {}
	timers = timers or {}

	colors = BigWigs:GetPlugin("Colors")
	
	if not media:Fetch("statusbar", db.texture, true) then db.texture = "BantoBar" end
	self:RegisterMessage("BigWigs_AddHealthBar")
	self:RegisterMessage("BigWigs_AddPowerBar")
	self:RegisterMessage("BigWigs_AddGeneralBar")
	self:RegisterMessage("BigWigs_RemoveBar")
	self:RegisterMessage("BigWigs_HideHealthBars", "BigWigs_OnBossDisable")
	self:RegisterMessage("BigWigs_OnBossDisable")
	self:RegisterMessage("BigWigs_OnPluginDisable", "BigWigs_OnBossDisable")
	self:RegisterMessage("BigWigs_StartConfigureMode")
	self:RegisterMessage("BigWigs_SetConfigureTarget")
	self:RegisterMessage("BigWigs_StopConfigureMode")
	self:RegisterMessage("BigWigs_ResetPositions", resetAnchors)
	self:RegisterMessage("BigWigs_ProfileUpdate", updateProfile)
	
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_MAXHEALTH")
	
	self:RegisterEvent("UNIT_ENERGY", "updatePower")
	self:RegisterEvent("UNIT_MANA", "updatePower")
	self:RegisterEvent("UNIT_RAGE", "updatePower")
	self:RegisterEvent("UNIT_FOCUS", "updatePower")
	self:RegisterEvent("UNIT_HAPPINESS", "updatePower")
	self:RegisterEvent("UNIT_RUNIC_POWER", "updatePower")
	
	self:RegisterEvent("UNIT_MAXENERGY", "updateMaxPower")
	self:RegisterEvent("UNIT_MAXMANA", "updateMaxPower")
	self:RegisterEvent("UNIT_MAXRAGE", "updateMaxPower")
	self:RegisterEvent("UNIT_MAXFOCUS", "updateMaxPower")
	self:RegisterEvent("UNIT_MAXHAPPINESS", "updateMaxPower")
	self:RegisterEvent("UNIT_MAXRUNIC_POWER", "updateMaxPower")
	
	--  custom bars
	BigWigs:AddSyncListener(self, "BWCustomHealthBar")
end

local function transferPowerType(powerType,inString)
	if not powerTypes[powerType] then return powerType end
	if type(powerType) == "number" and inString then
		return powerTypes[powerType]
	elseif type(powerType) == "string" and not inString then
		return powerTypes[powerType]
	end
end

do
	local t = {"target", "targettarget", "focus", "focustarget", "mouseover", "mouseovertarget"}
	for i = 1, 4 do t[#t+1] = fmt("boss%d", i) end
	for i = 1, 4 do t[#t+1] = fmt("party%dtarget", i) end
	for i = 1, 4 do t[#t+1] = fmt("party%d", i) end
	for i = 1, 40 do t[#t+1] = fmt("raid%dtarget", i) end
	for i = 1, 40 do t[#t+1] = fmt("raid%d", i) end
	local function findTargetByGUID(id)
		local idType = type(id)
		for i, unit in next, t do
			if UnitExists(unit) and not UnitIsPlayer(unit) then
				local unitId = UnitGUID(unit)
				if idType == "number" then unitId = tonumber(unitId:sub(-12, -7), 16) end
				if unitId == id then return unit end
			end
		end
	end
	function plugin:GetUnitIdByGUID(mob) return findTargetByGUID(mob) end
end

local function updateBarValues(GUID, power)
	if not string.find(tostring(GUID),"0x") then return end
	local bar = findBar(GUID, power)
	if bar then
		local unitId = plugin:GetUnitIdByGUID(tonumber(GUID:sub(-12, -7), 16))
		bar:SetLabel(UnitName(unitId))
		if transferPowerType(power,true) == "HAELTH" then
			bar:SetMinMaxValues(0,UnitHealthMax(unitId))
			bar:SetValue(UnitHealth(unitId))
		else 
			bar:SetMinMaxValues(0,UnitPowerMax(unitId,transferPowerType(power,false)))
			bar:SetValue(UnitPower(unitId,transferPowerType(power,false)))
		end
	end
end

local function findBar(ID, power)
	if not normalAnchor then return end
	local GUID,NUMID = "",0
	if type(ID)=="string" and not ID:find("0x") then
		GUID = UnitGUID(ID)
		NUMID = tonumber(GUID:sub(-12, -7), 16)
	elseif type(ID)=="number" then
		GUID = plugin:GetUnitIdByGUID(ID)
		NUMID = ID
	else
		GUID = ID
		NUMID = tonumber(GUID:sub(-12, -7), 16)
	end
	if normalAnchor.bars then
		for k in pairs(normalAnchor.bars) do
			if (k:Get("bigwigs:ID") == GUID or k:Get("bigwigs:ID") == NUMID) and (not power or k:Get("bigwigs:power") == transferPowerType(power,true) or k:Get("bigwigs:power") == transferPowerType(power,false)) then
				if type(k:Get("bigwigs:ID")) == "number" then
					k:Set("bigwigs:ID",GUID)
					updateBarValues(GUID, power)
				end
				return k
			end
		end
	end
end

function plugin:BigWigs_SetConfigureTarget(event, module)
	if module == self then
		normalAnchor.background:SetTexture(0.2, 1, 0.2, 0.3)
	else
		normalAnchor.background:SetTexture(0, 0, 0, 0.3)
	end
end

function plugin:BigWigs_AddGeneralBar(message, module, key, Id, powerType, icon, text, minValue, maxValue, Value, func)
	if powerType == "HEALTH" then
		plugin:BigWigs_AddHealthBar(message, module, key, Id, text, minValue, maxValue, Value, icon, func)
	else
		plugin:BigWigs_AddPowerBar(message, module, key, Id, text, minValue, maxValue, Value, icon, powerType, func)
	end
end
function plugin:UNIT_HEALTH(event, unitId)
	local bar = findBar(unitId,"HEALTH")
	if bar then
		bar:SetValue(UnitHealth(unitId))
	end
end

function plugin:UNIT_MAXHEALTH(event, unitId)
	local bar = findBar(unitId,"HEALTH")
	if bar then
		bar:SetMinMaxValues(0,UnitHealthMax(unitId))
	end
end

function plugin:updatePower(event, unitId)
	local power = string.gsub(event, "UNIT_","")
	local bar = findBar(unitId,power)
	if bar then
		bar:SetValue(UnitPower(unitId,transferPowerType(power,false)))
	end
end

function plugin:updateMaxPower(event, unitId)
	local power = string.gsub(event, "UNIT_MAX","")
	local bar = findBar(unitId,power)
	if bar then
		bar:SetMinMaxValues(0,UnitPowerMax(unitId,transferPowerType(power,false)))
	end
end

function plugin:BigWigs_StartConfigureMode()
	showAnchors()
	plugin:BigWigs_AddHealthBar("BigWigs_AddHealthBar", "test", "config", "player")
	plugin:BigWigs_AddPowerBar("BigWigs_AddPowerBar", "test", "config", "player", nil, nil, nil, nil, nil, (UnitPowerType("player")))
end

local function barClicked(bar, button)
	for action, enabled in pairs(plugin.db.profile[button]) do
		if enabled then clickHandlers[action](bar) end
	end
end

local function barOnEnter(bar)
	bar.candyBarLabel:SetJustifyH("CENTER")
	bar.candyBarBackground:SetVertexColor(1, 1, 1, 0.8)
end
local function barOnLeave(bar)
	bar.candyBarLabel:SetJustifyH(db.align)
	bar.candyBarBackground:SetVertexColor(0.5, 0.5, 0.5, 0.3)
end

do
	local function updateBars()
		for bar in pairs(normalAnchor.bars) do
			bar:SetTexture(media:Fetch("statusbar", db.texture))
			bar.candyBarLabel:SetJustifyH(db.align)
			bar.candyBarLabel:SetFont(media:Fetch("font", db.font), 10)
			bar.candyBarProgress:SetFont(media:Fetch("font", db.font), 10)
			bar:SetProgressVisibility(db.value, db.maxValue, db.percent)
			bar:SetScale(db.scale)
			if db.interceptMouse then
				bar:EnableMouse(true)
				bar:SetScript("OnMouseDown", barClicked)
				bar:SetScript("OnEnter", barOnEnter)
				bar:SetScript("OnLeave", barOnLeave)
			else
				bar:EnableMouse(false)
				bar:SetScript("OnMouseDown", nil)
				bar:SetScript("OnEnter", nil)
				bar:SetScript("OnLeave", nil)
			end
		end
		rearrangeBars(normalAnchor)
	end

	local function onControlEnter(widget, event, value)
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
		GameTooltip:AddLine(widget.text and widget.text:GetText() or widget.label:GetText())
		GameTooltip:AddLine(widget:GetUserData("tooltip"), 1, 1, 1, 1)
		GameTooltip:Show()
	end
	local function onControlLeave() GameTooltip:Hide() end

	local function standardCallback(widget, event, value)
		local key = widget:GetUserData("key")
		db[key] = value
		updateBars()
	end

	local function dropdownCallback(widget, event, value)
		local list = media:List(widget:GetUserData("type"))
		db[widget:GetUserData("key")] = list[value]
		updateBars()
	end

	function plugin:GetPluginConfig()
		if not AceGUI then AceGUI = LibStub("AceGUI-3.0") end
		local tex = AceGUI:Create("Dropdown")
		do
			local list = media:List("statusbar")
			local selected = nil
			for k, v in pairs(list) do
				if v == db.texture then
					selected = k
					break
				end
			end
			tex:SetList(list)
			tex:SetValue(selected)
			tex:SetLabel(L["Texture"])
			tex:SetUserData("type", "statusbar")
			tex:SetUserData("key", "texture")
			tex:SetCallback("OnValueChanged", dropdownCallback)
			tex:SetFullWidth(true)
		end

		local font = AceGUI:Create("Dropdown")
		do
			local list = media:List("font")
			local selected = nil
			for k, v in pairs(list) do
				if v == db.font then
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
		
		local align = AceGUI:Create("InlineGroup")
		align:SetTitle(L["Align"])
		align:SetFullWidth(true)
		align:SetLayout("Flow")

		do
			local left = AceGUI:Create("CheckBox")
			local center = AceGUI:Create("CheckBox")
			local right = AceGUI:Create("CheckBox")

			local function set(widget, event, value)
				db.align = widget:GetUserData("value")
				left:SetValue(db.align == "LEFT")
				center:SetValue(db.align == "CENTER")
				right:SetValue(db.align == "RIGHT")
				updateBars()
			end

			left:SetValue(db.align == "LEFT")
			left:SetUserData("value", "LEFT")
			left:SetType("radio")
			left:SetLabel(L["Left"])
			left:SetCallback("OnValueChanged", set)
			left:SetRelativeWidth(0.33)

			center:SetValue(db.align == "CENTER")
			center:SetUserData("value", "CENTER")
			center:SetType("radio")
			center:SetLabel(L["Center"])
			center:SetCallback("OnValueChanged", set)
			center:SetRelativeWidth(0.33)

			right:SetValue(db.align == "RIGHT")
			right:SetUserData("value", "RIGHT")
			right:SetType("radio")
			right:SetLabel(L["Right"])
			right:SetCallback("OnValueChanged", set)
			right:SetRelativeWidth(0.33)

			align:AddChildren(left, center, right)
		end
		
		local icon = AceGUI:Create("CheckBox")
		icon:SetValue(db.icon)
		icon:SetLabel(L["Icon"])
		icon:SetUserData("key", "icon")
		icon:SetCallback("OnValueChanged", standardCallback)
		icon:SetUserData("tooltip", L["Shows or hides the bar icons."])
		icon:SetCallback("OnEnter", onControlEnter)
		icon:SetCallback("OnLeave", onControlLeave)
		icon:SetFullWidth(true)

		local growup = AceGUI:Create("CheckBox")
		growup:SetValue(db.growup)
		growup:SetLabel(L["Grow upwards"])
		growup:SetUserData("key", "growup")
		growup:SetCallback("OnValueChanged", standardCallback)
		growup:SetUserData("tooltip", L["Toggle bars grow upwards/downwards from anchor."])
		growup:SetCallback("OnEnter", onControlEnter)
		growup:SetCallback("OnLeave", onControlLeave)
		growup:SetFullWidth(true)
		
		local value = AceGUI:Create("CheckBox")
		value:SetValue(db.value)
		value:SetLabel(L["Value"])
		value:SetUserData("key", "value")
		value:SetCallback("OnValueChanged", standardCallback)
		value:SetUserData("tooltip", L["Whether to show or hide the value right on the bars."])
		value:SetCallback("OnEnter", onControlEnter)
		value:SetCallback("OnLeave", onControlLeave)
		value:SetFullWidth(true)
		
		local maxValue = AceGUI:Create("CheckBox")
		maxValue:SetValue(db.maxValue)
		maxValue:SetLabel(L["Max Value"])
		maxValue:SetUserData("key", "maxValue")
		maxValue:SetCallback("OnValueChanged", standardCallback)
		maxValue:SetUserData("tooltip", L["Whether to show or hide the max value right on the bars."])
		maxValue:SetCallback("OnEnter", onControlEnter)
		maxValue:SetCallback("OnLeave", onControlLeave)
		maxValue:SetFullWidth(true)
		
		local percent = AceGUI:Create("CheckBox")
		percent:SetValue(db.percent)
		percent:SetLabel(L["Percent"])
		percent:SetUserData("key", "percent")
		percent:SetCallback("OnValueChanged", standardCallback)
		percent:SetUserData("tooltip", L["Whether to show or hide the percent right on the bars."])
		percent:SetCallback("OnEnter", onControlEnter)
		percent:SetCallback("OnLeave", onControlLeave)
		percent:SetFullWidth(true)

		local scale = AceGUI:Create("Slider")
		scale:SetValue(db.scale)
		scale:SetSliderValues(0.2, 2.0, 0.1)
		scale:SetLabel(L["Scale"])
		scale:SetUserData("key", "scale")
		scale:SetCallback("OnValueChanged", standardCallback)
		scale:SetFullWidth(true)

		return tex, font, align, icon, value, maxValue, percent, growup, scale
	end
end

--------------------------------------------------------------------------------
-- Bars
--





--------------------------------------------------------------------------------
-- Event Handlers
--

local function stopBars(bars, module, ID, power)
	local dirty = nil
	for k in pairs(bars) do
		if k:Get("bigwigs:module") == module and (not ID or k:Get("bigwigs:ID") == ID) and (not power or k:Get("bigwigs:power") == transferPowerType(power,true) or k:Get("bigwigs:power") == transferPowerType(power,false)) then
			k:Stop()
			dirty = true
		end
	end
	return dirty
end

local function stop(module, ID, power)
	if not normalAnchor then return end
	local d = stopBars(normalAnchor.bars, module, ID, power)
	if d then rearrangeBars(normalAnchor) end
end

function plugin:BigWigs_OnBossDisable(message, module) stop(module) end
function plugin:BigWigs_RemoveBar(message, module, ID, power) stop(module, ID, power) end

-- Report the bar status to the active group type (raid, party, solo)
do
	local function SorterValue(value)
		if value >= 10^3 and value < 10^8 then
			local len = string.len(tostring(value))
			local pot = len-3
			local conversion = len<7 and 10^3 or 10^6
			local unit = len<7 and "k" or "m"
			return tostring((floor((value+5*(10^(pot-1)))/(10^pot))*(10^pot))/conversion)..unit
		elseif value >= 10^8 then
			return tostring(floor((value+5*10^5)/10^6)).."m"
		else
			return tostring(value)
		end
	end
	clickHandlers.report = function(bar)
		local channel = "SAY"
		if UnitInBattleground("player") then
			channel = "BATTLEGROUND"
		elseif UnitInRaid("player") then
			channel = "RAID"
		elseif GetNumPartyMembers() > 1 then
			channel = "PARTY"
		end
		local curValue = bar:GetValue()
		local minValue,maxValue = bar:GetMinMaxValues()
		local text = string.format("%s: %s",bar.candyBarLabel:GetText(),bar.candyBarDuration:GetText())
		text = string.gsub(text,"|","\||")
		SendChatMessage(text, channel)
	end
end

-- Removes the clicked bar
clickHandlers.remove = function(bar)
	bar:Stop()
	rearrangeBars(normalAnchor)
end

-- Removes all bars EXCEPT the clicked one
clickHandlers.removeOther = function(bar)
	if normalAnchor then
		for k in pairs(normalAnchor.bars) do
			if k ~= bar then
				k:Stop()
			end
		end
		rearrangeBars(normalAnchor)
	end
end

-- Disables the option that launched this bar
clickHandlers.disable = function(bar)
	local m = bar:Get("bigwigs:module")
	if m and m.db and m.db.profile and bar:Get("bigwigs:option") then
		m.db.profile[bar:Get("bigwigs:option")] = 0
	end
end

local function createBar(module, key, ID, text, minValue, maxValue, Value, icon, power, r, g, b, a, func)
	if not normalAnchor then createAnchors() end
	stop(module, ID, power)
	local bar = staticCandy:New(media:Fetch("statusbar", db.texture), 200, 14)
	normalAnchor.bars[bar] = true
	bar.candyBarBackground:SetVertexColor(0.5, 0.5, 0.5, 0.3)
	bar:Set("bigwigs:module", module)
	bar:Set("bigwigs:anchor", normalAnchor)
	bar:Set("bigwigs:option", key)
	bar:Set("bigwigs:ID", ID)
	bar:Set("bigwigs:power", power)
	bar:SetColor(r, g, b, a)
	bar.candyBarLabel:SetTextColor(1, 1, 1, 1)
	bar.candyBarLabel:SetJustifyH(db.align)
	bar.candyBarLabel:SetFont(media:Fetch("font", db.font), 10)
	bar.candyBarProgress:SetFont(media:Fetch("font", db.font), 10)
	bar:SetLabel(text)
	bar:SetClampedToScreen(true)
	bar:SetMinMaxValues(minValue,maxValue)
	bar:SetValue(Value)
	bar:SetProgressVisibility(db.value, db.maxValue, db.percent)
	bar:SetIcon(db.icon and icon or nil)
	bar:SetScale(db.scale)
	bar:AddUpdateFunction(func)
	if db.interceptMouse then
		bar:EnableMouse(true)
		bar:SetScript("OnMouseDown", barClicked)
		bar:SetScript("OnEnter", barOnEnter)
		bar:SetScript("OnLeave", barOnLeave)
	end
	bar:Start()
	rearrangeBars(normalAnchor)
end

function plugin:BigWigs_AddHealthBar(message, module, key, Id, text, minValue, maxValue, Value, icon, func)
	local t = type(Id)
	local unitId,GUID,bossId = "",""
	if t == "string" then
		if string.find(Id,"0x") then
			GUID = id
			id = tonumber(Id:sub(-12, -7), 16)
			unitId = plugin:GetUnitIdByGUID(Id)
		else
			unitId = Id
			GUID = UnitGUID(unitId)
		end
	elseif t == "number" then
		bossId = plugin:GetUnitIdByGUID(Id)
		if bossId then
			GUID = UnitGUID(bossId)
			unitId = bossId
		else
			GUID = Id
		end
	end
	if UnitExists(unitId) then
		minValue = minValue or 0
		maxValue = maxValue or UnitHealthMax(unitId)
		Value = Value or UnitHealth(unitId)
		text = text or UnitName(unitId)
		createBar(module, key, GUID, text, minValue, maxValue, Value, icon, "HEALTH", 0.5, 1, 0 ,1, func)
	elseif not UnitExists(unitId) then
		minValue = minValue or 0
		maxValue = maxValue or 0
		Value = Value or 0
		text = text or ""
		createBar(module, key, GUID, text, minValue, maxValue, Value, icon, "HEALTH", 0.5, 1, 0 ,1, func)
	end
end

function plugin:BigWigs_AddPowerBar(message, module, key, Id, text, minValue, maxValue, Value, icon, powerType, r, g, b, func)
	local t = type(Id)
	local unitId,GUID,bossId = "",""
	if t == "string" then
		if string.find(Id,"0x") then
			GUID = id
			id = tonumber(Id:sub(-12, -7), 16)
			unitId = plugin:GetUnitIdByGUID(Id)
		else
			unitId = Id
			GUID = UnitGUID(unitId)
		end
	elseif t == "number" then
		bossId = plugin:GetUnitIdByGUID(Id)
		if bossId then
			GUID = UnitGUID(bossId)
			unitId = bossId
		else
			GUID = Id
		end
	end
	minValue = minValue or 0
	r = r or powerColor[powerType]["r"] or 0.5
	g = g or powerColor[powerType]["g"] or 0.5
	b = b or powerColor[powerType]["b"] or 0.5
	if UnitExists(unitId) then
		maxValue = maxValue or UnitPowerMax(unitId, powerType)
		Value = Value or UnitPower(unitId, powerType)
		text = text or UnitName(unitId)
		createBar(module, key, GUID, text, minValue, maxValue, Value, icon, powerType, r, g, b, 1, func)
	elseif not UnitExists(unitId) then
		maxValue = maxValue or 0
		Value = Value or 0
		text = text or ""
		createBar(module, key, GUID, text, minValue, maxValue, Value, icon, powerType, r, g, b, 1, func)
	end
end

function plugin:BigWigs_StopConfigureMode()
	hideAnchors()
	stop("test")
end

--------------------------------------------------------------------------------
-- Custom Bars
--

local function parseTime(input)
	if type(input) == "nil" then return end
	if tonumber(input) then return tonumber(input) end
	if type(input) == "string" then
		input = input:trim()
		if input:find(":") then
			local m, s = select(3, input:find("^(%d+):(%d+)$"))
			if not tonumber(m) or not tonumber(s) then return end
			return (tonumber(m) * 60) + tonumber(s)
		elseif input:find("^%d+mi?n?$") then
			return tonumber(select(3, input:find("^(%d+)mi?n?$"))) * 60
		end
	end
end

local function sendCustomMessage(msg)
	if not messages[msg] then return end
	plugin:SendMessage("BigWigs_Message", nil, nil, unpack(messages[msg]))
	wipe(messages[msg])
	messages[msg] = nil
end

local function startCustomBar(bar, nick, localOnly)
	local time, barText = select(3, bar:find("(%S+) (.*)"))
	local seconds = parseTime(time)
	if type(seconds) ~= "number" or type(barText) ~= "string" then
		BigWigs:Print(L["Invalid time (|cffff0000%q|r) or missing bar text in a custom bar started by |cffd9d919%s|r. <time> can be either a number in seconds, a M:S pair, or Mm. For example 5, 1:20 or 2m."]:format(tostring(time), nick or UnitName("player")))
		return
	end

	if not nick then nick = L["Local"] end
	local id = "bwcb" .. nick .. barText
	if seconds == 0 then
		if timers[id] then
			plugin:CancelTimer(timers[id], true)
			wipe(messages[id])
			timers[id] = nil
		end
		plugin:SendMessage("BigWigs_StopBar", plugin, nick..": "..barText)
	else
		messages[id] = { L["%s: Timer [%s] finished."]:format(nick, barText), "Attention", localOnly }
		timers[id] = plugin:ScheduleTimer(sendCustomMessage, seconds, id)
		plugin:SendMessage("BigWigs_StartBar", plugin, nil, nick..": "..barText, seconds, "Interface\\Icons\\INV_Misc_PocketWatch_01")
	end
end

function plugin:OnSync(sync, rest, nick)
	if sync ~= "BWCustomBar" or not rest or not nick then return end
	if not UnitIsRaidOfficer(nick) then return end
	startCustomBar(rest, nick, false)
end

-------------------------------------------------------------------------------
-- Slashcommand
--


-------------------------------------------------------------------------------
-- Interactive bars
--
