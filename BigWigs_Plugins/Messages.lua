-------------------------------------------------------------------------------
-- Module Declaration
--


local plugin = BigWigs:NewPlugin("Messages", "LibSink-2.0")
if not plugin then return end

-------------------------------------------------------------------------------
-- Locals
--

local media = LibStub("LibSharedMedia-3.0")

local scaleUpTime = 0.2
local scaleDownTime = 0.4
local labels = {}
local emphasizedText = nil
local seModule = nil
local colorModule = nil
local messageFrame = nil
local anchor = nil
local floor = math.floor

local AceGUI = nil

local L = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Plugins")
local outlineList = {NONE = L["None"], OUTLINE = L["Thin"], THICKOUTLINE = L["Thick"]}

--------------------------------------------------------------------------------
-- Anchor
--

local function onDragStart(self) self:StartMoving() end
local function onDragStop(self)
	self:StopMovingOrSizing()
	local s = self:GetEffectiveScale()
	plugin.db.profile[self.x] = self:GetLeft() * s
	plugin.db.profile[self.y] = self:GetTop() * s
end

local function onControlEnter(self)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	GameTooltip:AddLine(self.tooltipHeader)
	GameTooltip:AddLine(self.tooltipText, 1, 1, 1, 1)
	GameTooltip:Show()
end
local function onControlLeave() GameTooltip:Hide() end

local createMsgFrame
local function createAnchor(frameName, title)
	local display = CreateFrame("Frame", frameName, UIParent)
	display.x, display.y = frameName .. "_x", frameName .. "_y"
	display:EnableMouse(true)
	display:SetClampedToScreen(true)
	display:SetMovable(true)
	display:RegisterForDrag("LeftButton")
	display:SetWidth(200)
	display:SetHeight(20)
	local bg = display:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(display)
	bg:SetBlendMode("BLEND")
	bg:SetTexture(0, 0, 0, 0.3)
	display.background = bg
	local header = display:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	header:SetText(title)
	header:SetAllPoints(display)
	header:SetJustifyH("CENTER")
	header:SetJustifyV("MIDDLE")
	display:SetScript("OnDragStart", onDragStart)
	display:SetScript("OnDragStop", onDragStop)
	display:SetScript("OnMouseUp", function(self, button)
		if button ~= "LeftButton" then return end
		plugin:SendMessage("BigWigs_SetConfigureTarget", plugin)
	end)
	display.Reset = function(self)
		plugin.db.profile[self.x] = nil
		plugin.db.profile[self.y] = nil
		self:RefixPosition()
	end
	display.RefixPosition = function(self)
		self:ClearAllPoints()
		if plugin.db.profile[self.x] and plugin.db.profile[self.y] then
			local s = self:GetEffectiveScale()
			self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", plugin.db.profile[self.x] / s, plugin.db.profile[self.y] / s)
		else
			self:SetPoint("TOP", RaidWarningFrame, "BOTTOM", 0, 45)
		end
	end
	display:RefixPosition()
	display:Hide()
	return display
end

local function createAnchors()
	normalAnchor = createAnchor("BWMessageAnchor", L["Messages"])
	emphasizeAnchor = createAnchor("BWEmphasizeMessageAnchor", L["Emphasized messages"])

	createAnchors = nil
	createAnchor = nil
end

local function showAnchors()
	if createAnchors then createAnchors() end
	normalAnchor:Show()
	emphasizeAnchor:Show()
end

local function hideAnchors()
	normalAnchor:Hide()
	emphasizeAnchor:Hide()
end

local function resetAnchors()
	normalAnchor:Reset()
	emphasizeAnchor:Reset()
end

--------------------------------------------------------------------------------
-- Options
--

plugin.defaultDB = {
	sink20OutputSink = "BigWigs",
	usecolors = true,
	scale = 1.0,
	fontEmphasized = nil,
	font = nil,
	fontSizeEmphasized = nil,
	fontSize = nil,
	outlineEmphasized = "OUTLINE",
	outline = "THICKOUTLINE",
	growup = false,
	chat = nil,
	useicons = true,
	classcolor = true,
	emphasizedMessages = {
		sink20OutputSink = "BigWigsEmphasized",
	},
}

local fakeEmphasizeMessageAddon = {}
LibStub("LibSink-2.0"):Embed(fakeEmphasizeMessageAddon)

plugin.pluginOptions = {
	type = "group",
	name = L["Output"],
	childGroups = "tab",
	args = {
		normal = plugin:GetSinkAce3OptionsDataTable(),
		emphasized = fakeEmphasizeMessageAddon:GetSinkAce3OptionsDataTable(),
	},
}
plugin.pluginOptions.args.normal.name = L["Normal messages"]
plugin.pluginOptions.args.normal.order = 1
plugin.pluginOptions.args.emphasized.name = L["Emphasized messages"]
plugin.pluginOptions.args.emphasized.order = 2

local function updateProfile()
	if normalAnchor then
		normalAnchor:RefixPosition()
		emphasizeAnchor:RefixPosition()
	end
end

-------------------------------------------------------------------------------
-- Initialization
--

function plugin:OnRegister()
	fakeEmphasizeMessageAddon:SetSinkStorage(self.db.profile.emphasizedMessages)
	self:RegisterSink("BigWigsEmphasized", "Big Wigs Emphasized", L.emphasizedSinkDescription, "EmphasizedPrint")
	self:SetSinkStorage(self.db.profile)
	self:RegisterSink("BigWigs", "Big Wigs", L.sinkDescription, "Print")
	self:RegisterMessage("BigWigs_ProfileUpdate", updateProfile)
	
	if not plugin.db.profile.font then
		plugin.db.profile.font = media:GetDefault("font")
	end
	if not plugin.db.profile.fontEmphasized then
		plugin.db.profile.fontEmphasized = media:GetDefault("font")
	end
	if not plugin.db.profile.fontSize then
		local _, size = GameFontNormalHuge:GetFont()
		plugin.db.profile.fontSize = size
	end
	if not plugin.db.profile.fontSizeEmphasized then
		local _, size = GameFontNormalHuge:GetFont()
		plugin.db.profile.fontSizeEmphasized = size
	end
end

function plugin:OnPluginEnable()
	self:RegisterMessage("BigWigs_ResetPositions", resetAnchors)
	self:RegisterMessage("BigWigs_SetConfigureTarget")
	self:RegisterMessage("BigWigs_Message")
	self:RegisterMessage("BigWigs_EmphasizedMessage")
	self:RegisterMessage("BigWigs_StartConfigureMode", showAnchors)
	self:RegisterMessage("BigWigs_StopConfigureMode", hideAnchors)

	seModule = BigWigs:GetPlugin("Super Emphasize", true)
	colorModule = BigWigs:GetPlugin("Colors", true)

	self:RegisterMessage("BigWigs_ProfileUpdate", updateProfile)
end

function plugin:BigWigs_SetConfigureTarget(event, module)
	if module == self then
		normalAnchor.background:SetTexture(0.2, 1, 0.2, 0.3)
		emphasizeAnchor.background:SetTexture(0.2, 1, 0.2, 0.3)
	else
		normalAnchor.background:SetTexture(0, 0, 0, 0.3)
		emphasizeAnchor.background:SetTexture(0, 0, 0, 0.3)
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
		if key=="growup" then
			messageFrame = nil
		end
	end
	
	local function dropdownCallback(widget, event, value)
		if outlineList[value] then
			plugin.db.profile[widget:GetUserData("key")] = value
		else
			local list = media:List(widget:GetUserData("type"))
			plugin.db.profile[widget:GetUserData("key")] = list[value]
		end
	end
	
	local function sliderCallback(widget, event, value)
		local key = widget:GetUserData("key")
		plugin.db.profile[key] = value
	end
	
	function plugin:GetPluginConfig()
		if not AceGUI then AceGUI = LibStub("AceGUI-3.0") end
		
		local normal = AceGUI:Create("InlineGroup")
		normal:SetTitle(L["Normal messages"])
		normal:SetFullWidth(true)

		do
			local chat = AceGUI:Create("CheckBox")
			chat:SetLabel(L["Chat frame"])
			chat:SetValue(self.db.profile.chat and true or false)
			chat:SetCallback("OnEnter", onControlEnter)
			chat:SetCallback("OnLeave", onControlLeave)
			chat:SetCallback("OnValueChanged", checkboxCallback)
			chat:SetUserData("key", "chat")
			chat:SetUserData("tooltip", L["Outputs all BigWigs messages to the default chat frame in addition to the display setting."])

			local colors = AceGUI:Create("CheckBox")
			colors:SetLabel(L["Use colors"])
			colors:SetValue(self.db.profile.usecolors and true or false)
			colors:SetCallback("OnEnter", onControlEnter)
			colors:SetCallback("OnLeave", onControlLeave)
			colors:SetCallback("OnValueChanged", checkboxCallback)
			colors:SetUserData("key", "usecolors")
			colors:SetUserData("tooltip", L["Toggles white only messages ignoring coloring."])

			local classColors = AceGUI:Create("CheckBox")
			classColors:SetLabel(L["Class colors"])
			classColors:SetValue(self.db.profile.classcolor and true or false)
			classColors:SetCallback("OnEnter", onControlEnter)
			classColors:SetCallback("OnLeave", onControlLeave)
			classColors:SetCallback("OnValueChanged", checkboxCallback)
			classColors:SetUserData("key", "classcolor")
			classColors:SetUserData("tooltip", L["Colors player names in messages by their class."])

			local icons = AceGUI:Create("CheckBox")
			icons:SetLabel(L["Use icons"])
			icons:SetValue(self.db.profile.useicons and true or false)
			icons:SetCallback("OnEnter", onControlEnter)
			icons:SetCallback("OnLeave", onControlLeave)
			icons:SetCallback("OnValueChanged", checkboxCallback)
			icons:SetUserData("key", "useicons")
			icons:SetUserData("tooltip", L["Show icons next to messages, only works for Raid Warning."])
			
			local growup = AceGUI:Create("CheckBox")
			growup:SetValue(self.db.profile.growup)
			growup:SetLabel(L["Grow upwards"])
			growup:SetUserData("key", "growup")
			growup:SetCallback("OnValueChanged", checkboxCallback)
			growup:SetUserData("tooltip", L["Toggle bars grow upwards/downwards from anchor."])
			growup:SetCallback("OnEnter", onControlEnter)
			growup:SetCallback("OnLeave", onControlLeave)
			growup:SetFullWidth(true)
			
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
			
			local outline = AceGUI:Create("Dropdown")
			do
				local list = outlineList
				local selected = nil
				for k, v in pairs(list) do
					if k == plugin.db.profile.outline then
						selected = k
						break
					end
				end
				outline:SetList(list)
				outline:SetValue(selected)
				outline:SetLabel(L["Outline"])
				outline:SetUserData("key", "outline")
				outline:SetCallback("OnValueChanged", dropdownCallback)
				outline:SetFullWidth(true)
			end
			
			local fontSize = AceGUI:Create("Slider")
			fontSize:SetValue(self.db.profile.fontSize)
			fontSize:SetSliderValues(8, 40, 1)
			fontSize:SetLabel(L["Font size"])
			fontSize:SetUserData("key", "fontSize")
			fontSize:SetCallback("OnValueChanged", sliderCallback)
			fontSize:SetFullWidth(true)
			
			normal:AddChildren(chat, colors, classColors, icons, growup, font, outline, fontSize)
		end

		local emphasized = AceGUI:Create("InlineGroup")
		emphasized:SetTitle(L["Emphasized messages"])
		emphasized:SetFullWidth(true)
		
		do
			local fontEmphasized = AceGUI:Create("Dropdown")
			do
				local list = media:List("font")
				local selected = nil
				for k, v in pairs(list) do
					if v == plugin.db.profile.fontEmphasized then
						selected = k
						break
					end
				end
				fontEmphasized:SetList(list)
				fontEmphasized:SetValue(selected)
				fontEmphasized:SetLabel(L["Font"])
				fontEmphasized:SetUserData("type", "font")
				fontEmphasized:SetUserData("key", "fontEmphasized")
				fontEmphasized:SetCallback("OnValueChanged", dropdownCallback)
				fontEmphasized:SetFullWidth(true)
			end
			
			local outlineEmphasized = AceGUI:Create("Dropdown")
			do
				local list = outlineList
				local selected = nil
				for k, v in pairs(list) do
					if k == plugin.db.profile.outlineEmphasized then
						selected = k
						break
					end
				end
				outlineEmphasized:SetList(list)
				outlineEmphasized:SetValue(selected)
				outlineEmphasized:SetLabel(L["Outline"])
				outlineEmphasized:SetUserData("key", "outlineEmphasized")
				outlineEmphasized:SetCallback("OnValueChanged", dropdownCallback)
				outlineEmphasized:SetFullWidth(true)
			end
			
			local fontSizeEmphasized = AceGUI:Create("Slider")
			fontSizeEmphasized:SetValue(self.db.profile.fontSizeEmphasized)
			fontSizeEmphasized:SetSliderValues(8, 40, 1)
			fontSizeEmphasized:SetLabel(L["Font size"])
			fontSizeEmphasized:SetUserData("key", "fontSizeEmphasized")
			fontSizeEmphasized:SetCallback("OnValueChanged", sliderCallback)
			fontSizeEmphasized:SetFullWidth(true)
			
			emphasized:AddChildren(fontEmphasized, outlineEmphasized, fontSizeEmphasized)
		end
		
		return normal, emphasized
	end
end

--------------------------------------------------------------------------------
-- Message frame
--

local function newFontString(i)
	local fs = messageFrame:CreateFontString(nil, "ARTWORK")
	fs:SetWidth(800)
	fs:SetHeight(0)
	fs.lastUsed = 0
	FadingFrame_SetFadeInTime(fs, 0.2)
	FadingFrame_SetHoldTime(fs, 10)
	FadingFrame_SetFadeOutTime(fs, 3)
	fs:Hide()
	return fs
end

local function onUpdate(self, elapsed)
	local show = nil
	for i, v in next, labels do
		if v:IsShown() then
			if v.scrollTime then
				local min = v.minHeight
				local max = min + 10
				v.scrollTime = v.scrollTime + elapsed
				if v.scrollTime <= scaleUpTime then
					v:SetTextHeight(floor(min + ((max - min) * v.scrollTime / scaleUpTime)))
				elseif v.scrollTime <= scaleDownTime then
					v:SetTextHeight(floor(max - ((max - min) * (v.scrollTime - scaleUpTime) / (scaleDownTime - scaleUpTime))))
				else
					v:SetTextHeight(min)
					v.scrollTime = nil
				end
			end
			FadingFrame_OnUpdate(v)
			show = true
		end
	end
	if not show then self:Hide() end
end

local function onUpdateEmphasized(self, elapsed)
	local v = emphasizedText
	if v:IsShown() then
		if v.scrollTime then
			local min = v.minHeight
			local max = min + 10
			v.scrollTime = v.scrollTime + elapsed
			if v.scrollTime <= scaleUpTime then
				v:SetTextHeight(floor(min + ((max - min) * v.scrollTime / scaleUpTime)))
			elseif v.scrollTime <= scaleDownTime then
				v:SetTextHeight(floor(max - ((max - min) * (v.scrollTime - scaleUpTime) / (scaleDownTime - scaleUpTime))))
			else
				v:SetTextHeight(min)
				v.scrollTime = nil
			end
		end
		FadingFrame_OnUpdate(v)
		show = true
	end
end

function createMsgFrame()
	messageFrame = CreateFrame("Frame", "BWMessageFrame", UIParent)
	messageFrame:SetWidth(512)
	messageFrame:SetHeight(80)
	if plugin.db.profile.growup then
		messageFrame:SetPoint("BOTTOM", normalAnchor, "TOP")
	else
		messageFrame:SetPoint("TOP", normalAnchor, "BOTTOM")
	end
	messageFrame:SetScale(plugin.db.profile.scale or 1)
	messageFrame:SetFrameStrata("HIGH")
	messageFrame:SetToplevel(true)
	messageFrame:SetScript("OnUpdate", onUpdate)
	if plugin.db.profile.growup then
		for i = 1, 4 do
			local fs = newFontString(i)
			labels[i] = fs
			if i == 1 then
				fs:SetPoint("BOTTOM")
			else
				fs:SetPoint("BOTTOM", labels[i - 1], "TOP")
			end
		end
	else
		for i = 1, 4 do
			local fs = newFontString(i)
			labels[i] = fs
			if i == 1 then
				fs:SetPoint("TOP")
			else
				fs:SetPoint("TOP", labels[i - 1], "BOTTOM")
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Event Handlers
--

function plugin:Print(addon, text, r, g, b, font, size, _, _, _, icon)
	if createAnchors then createAnchors() end
	if not messageFrame then createMsgFrame() end
	messageFrame:SetScale(self.db.profile.scale)
	messageFrame:Show()
	
	-- move 4 -> 1
	local old = labels[4]
	labels[4] = labels[3]
	labels[3] = labels[2]
	labels[2] = labels[1]
	labels[1] = old
	
	-- reposition
	if plugin.db.profile.growup then
		for i = 1, 4 do
			labels[i]:ClearAllPoints()
			if i == 1 then
				labels[i]:SetPoint("BOTTOM")
			else
				labels[i]:SetPoint("BOTTOM", labels[i - 1], "TOP")
			end
		end
	else
		for i = 1, 4 do
			labels[i]:ClearAllPoints()
			if i == 1 then
				labels[i]:SetPoint("TOP")
			else
				labels[i]:SetPoint("TOP", labels[i - 1], "BOTTOM")
			end
		end
	end
	
	local slot = labels[1]
	
	slot:SetFont(media:Fetch("font", plugin.db.profile.font), plugin.db.profile.fontSize, plugin.db.profile.outline)
	
	--slot:SetFontObject(font or GameFontNormalHuge)
	slot.minHeight = plugin.db.profile.fontSize
	if icon then text = "|T"..icon..":" .. slot.minHeight .. ":" .. slot.minHeight .. ":-5|t"..text end
	slot:SetText(text)
	slot:SetTextColor(r, g, b, 1)
	slot.scrollTime = 0
	FadingFrame_Show(slot)
end
do
	
	local frame = nil
	function plugin:EmphasizedPrint(addon, text, r, g, b, font, size, _, _, _, icon)
		if createAnchors then createAnchors() end
		if not emphasizedText then
			frame = CreateFrame("Frame", nil, UIParent)
			frame:SetFrameStrata("HIGH")
			frame:SetPoint("BOTTOM", emphasizeAnchor, "TOP")
			frame:SetWidth(UIParent:GetWidth())
			frame:SetHeight(100)
			emphasizedText = frame:CreateFontString("BigWigsEmphasizedMessage", "OVERLAY")
			emphasizedText:SetWidth(UIParent:GetWidth())
			emphasizedText:SetHeight(40)
			emphasizedText:SetPoint("BOTTOM")
			FadingFrame_OnLoad(emphasizedText)
			FadingFrame_SetFadeInTime(emphasizedText, 0.2)
			-- XXX is 1.5 + 3.5 fade enough for a super emphasized message?
			FadingFrame_SetHoldTime(emphasizedText, 4)
			FadingFrame_SetFadeOutTime(emphasizedText, 3.5)
			frame:SetScript("OnUpdate", onUpdateEmphasized)
		end
		
		emphasizedText:SetFont(media:Fetch("font", plugin.db.profile.fontEmphasized), plugin.db.profile.fontSizeEmphasized, plugin.db.profile.outlineEmphasized)
		emphasizedText.minHeight = plugin.db.profile.fontSizeEmphasized
		emphasizedText.scrollTime = 0
		if icon then text = "|T"..icon..":" .. emphasizedText.minHeight .. ":" .. emphasizedText.minHeight .. ":-5|t"..text.."|T"..icon..":" .. emphasizedText.minHeight .. ":" .. emphasizedText.minHeight .. ":5|t" end
		emphasizedText:SetText(text)
		emphasizedText:SetTextHeight(plugin.db.profile.fontSizeEmphasized)
		emphasizedText:SetTextColor(r, g, b)
		FadingFrame_Show(emphasizedText)
	end
	function plugin:BigWigs_EmphasizedMessage(event, ...)
		fakeEmphasizeMessageAddon:Pour(...)
	end
end

function plugin:BigWigs_Message(event, module, key, text, color, _, sound, broadcastonly, icon)
	if broadcastonly or not text then return end

	local r, g, b = 1, 1, 1 -- Default to white.
	if self.db.profile.usecolors then
		if type(color) == "table" then
			if color.r and color.g and color.b then
				r, g, b = color.r, color.g, color.b
			else
				r, g, b = unpack(color)
			end
		elseif colorModule then
			r, g, b = colorModule:GetColor(color, module, key)
		end
	end

	if icon and self.db.profile.useicons then
		local _, _, gsiIcon = GetSpellInfo(icon)
		icon = gsiIcon or icon
	else
		icon = nil
	end

	if seModule and module and key and seModule:IsSuperEmphasized(module, key) then
		if seModule.db.profile.upper then
			text = text:upper()
		end
		fakeEmphasizeMessageAddon:Pour(text, r, g, b, nil, nil, nil, nil, nil, icon)
	else
		self:Pour(text, r, g, b, nil, nil, nil, nil, nil, icon)
	end
	if self.db.profile.chat then
		BigWigs:Print("|cff" .. string.format("%02x%02x%02x", r * 255, g * 255, b * 255) .. text .. "|r")
	end
end

