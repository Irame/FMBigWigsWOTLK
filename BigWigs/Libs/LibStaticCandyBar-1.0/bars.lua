--- **LibStaticCandyBar-3.0** provides elegant timerbars with icons for use in addons.
-- It is based of the original ideas of the CandyBar and CandyBar-2.0 library.
-- In contrary to the earlier libraries LibStaticCandyBar-3.0 provides you with a timerbar object with a simple API.
--
-- Creating a new timerbar using the ':New' function will return a new timerbar object. This timerbar object inherits all of the barPrototype functions listed here. \\
--
-- @usage
-- mybar = Libstub("LibStaticCandyBar-1.0"):New("Interface\\AddOns\\MyAddOn\\media\\statusbar.tga", 100, 16)
-- @class file
-- @name LibStaticCandyBar-1.0

local major = "LibStaticCandyBar-1.0"
local minor = tonumber(("$Rev: 26 $"):match("(%d+)")) or 1
if not LibStub then error("LibStaticCandyBar-1.0 requires LibStub.") end
local cbh = LibStub:GetLibrary("CallbackHandler-1.0")
if not cbh then error("LibStaticCandyBar-1.0 requires CallbackHandler-1.0") end
local lib, old = LibStub:NewLibrary(major, minor)
if not lib then return end
lib.callbacks = lib.callbacks or cbh:New(lib)
local cb = lib.callbacks
-- ninjaed from LibBars-1.0
lib.dummyFrame = lib.dummyFrame or CreateFrame("Frame")
lib.barFrameMT = lib.barFrameMT or {__index = lib.dummyFrame}
lib.barPrototype = lib.barProtoType or setmetatable({}, lib.barFrameMT)
lib.barPrototype_mt = lib.barPrototype_mt or {__index = lib.barPrototype}
lib.availableBars = lib.availableBars or {}

local bar = {}
local barPrototype = lib.barPrototype
local barPrototype_meta = lib.barPrototype_mt
local availableBars = lib.availableBars
local GetTime = GetTime

local function ShorterValue(value)
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

local scripts = {
	"OnUpdate",
	"OnDragStart", "OnDragStop",
	"OnEnter", "OnLeave",
	"OnHide", "OnShow",
	"OnMouseDown", "OnMouseUp", "OnMouseWheel",
	"OnSizeChanged", "OnEvent"
}
local function reset(bar)
	if bar.data then wipe(bar.data) end
	if bar.funcs then wipe(bar.funcs) end
	bar.running = nil
	bar.showTime = true
	for i, script in next, scripts do
		bar:SetScript(script, nil)
	end
	bar.candyBarBackground:SetVertexColor(0.5, 0.5, 0.5, 0.3)
	bar:ClearAllPoints()
	bar:SetWidth(bar.width)
	bar:SetHeight(bar.height)
	bar:SetMovable(1)
	bar:SetScale(1)
	bar:SetAlpha(1)
	bar.candyBarLabel:SetTextColor(1,1,1,1)
	bar.candyBarLabel:SetJustifyH("CENTER")
	bar.candyBarLabel:SetJustifyV("MIDDLE")
	bar.candyBarLabel:SetFontObject("GameFontHighlightSmallOutline")
	bar.candyBarProgress:SetFontObject("GameFontHighlightSmallOutline")
	bar:Hide()
end

local function onUpdate(self)
	local curValue = self.candyBarBar:GetValue()
	local minValue,maxValue = self.candyBarBar:GetMinMaxValues()
	local percent = maxValue ~= 0 and floor((curValue/maxValue)*100) or 100
		
	if curValue < minValue or curValue > maxValue then
		self:Stop()
	elseif self.formatProgress then
		self.candyBarProgress:SetText(self.formatProgress(curValue, maxValue, percent))
		
		if self.funcs then
			for i, v in next, self.funcs do v(self) end
		end
	end
end

-- ------------------------------------------------------------------------------
-- Bar functions
--

local function restyleBar(self)
	if not self.running then return end
	if self.candyBarIconFrame:GetTexture() then
		self.candyBarBar:SetPoint("TOPLEFT", self.candyBarIconFrame, "TOPRIGHT")
		self.candyBarBar:SetPoint("BOTTOMLEFT", self.candyBarIconFrame, "BOTTOMRIGHT")
		self.candyBarIconFrame:SetWidth(self.height)
		self.candyBarIconFrame:Show()
	else
		self.candyBarBar:SetPoint("TOPLEFT", self)
		self.candyBarBar:SetPoint("BOTTOMLEFT", self)
		self.candyBarIconFrame:Hide()
	end
	if self.candyBarLabel:GetText() then self.candyBarLabel:Show()
	else self.candyBarLabel:Hide() end
	if self.formatProgress then
		self.candyBarLabel:SetPoint("RIGHT", self.candyBarProgress, "LEFT", -2, 0)
		self.candyBarProgress:Show()
	else
		self.candyBarLabel:SetPoint("RIGHT", self.candyBarBar, "RIGHT", -2, 0)
		self.candyBarProgress:Hide()
	end
end

--- Adds a function to the timerbar. The function will run every update and will receive the bar as a parameter.
-- @param func Function to run every update
-- @usage
-- -- The example below will print the time remaining to the chatframe every update. Yes, that's a whole lot of spam
-- mybar:AddUpdateFunction( function(bar) print(bar.remaining) end )
function barPrototype:AddUpdateFunction(func) if not self.funcs then self.funcs = {} end; tinsert(self.funcs, func) end
--- Sets user data in the timerbar object. 
-- @param key Key to use for the data storage
-- @param data Data to store
function barPrototype:Set(key, data) if not self.data then self.data = {} end; self.data[key] = data end
--- Retrieves user data from the timerbar object.
-- @param key Key to retrieve
function barPrototype:Get(key) return self.data[key] end
--- Sets the color of the bar
-- This is basically a direct call to SetStatusBarColor and
-- @param r Red component 0-1
-- @param g Green component 0-1
-- @param b Blue component 0-1
-- @param a Alpha 0-1
function barPrototype:SetColor(r, g, b, a) self.candyBarBar:SetStatusBarColor(r, g, b, a) end
--- Sets the texture of the bar
-- This should only be needed on running bars that get changed on the fly
-- @param texture Path to the bar texture
function barPrototype:SetTexture(texture)
	self.candyBarBar:SetStatusBarTexture(texture)
	self.candyBarBackground:SetTexture(texture)
end
--- Sets the label on the bar
-- @param text Label text
function barPrototype:SetLabel(text) self.candyBarLabel:SetText(text); restyleBar(self) end
--- Sets the icon next to the bar
-- @param icon Path to the icon texture or nil to not display an icon
function barPrototype:SetIcon(icon) self.candyBarIconFrame:SetTexture(icon); restyleBar(self) end
--- Sets wether or not the time indicator on the right of the bar should be shown
-- Time is shown by default
-- @param bool true to show the time, false/nil to hide the time.
function barPrototype:SetProgressVisibility(showCurValue, showMaxValue, showPercent)
	if showCurValue and not showMaxValue and not showPercent then
		self.formatProgress = function(curValue, maxValue, percent) return ShorterValue(curValue) end
	elseif showCurValue and showMaxValue and not showPercent then
		self.formatProgress = function(curValue, maxValue, percent) return string.format("%s/%s",ShorterValue(curValue),ShorterValue(maxValue)) end
	elseif showCurValue and showMaxValue and showPercent then
		self.formatProgress = function(curValue, maxValue, percent) return string.format("%s/%s | %d%%",ShorterValue(curValue),ShorterValue(maxValue),percent) end
	elseif showCurValue and not showMaxValue and showPercent then
		self.formatProgress = function(curValue, maxValue, percent) return string.format("%s | %d%%",ShorterValue(curValue),percent) end
	elseif not showCurValue and showPercent then
		self.formatProgress = function(curValue, maxValue, percent) return string.format("%d%%",percent) end
	else
		self.formatProgress = nil
	end
	restyleBar(self)
end

function barPrototype:SetMinMaxValues(minValue,maxValue)
	self.candyBarBar:SetMinMaxValues(minValue,maxValue)
end

function barPrototype:SetValue(value)
	self.candyBarBar:SetValue(value)
end

function barPrototype:GetMinMaxValues()
	return self.candyBarBar:GetMinMaxValues()
end

function barPrototype:GetValue()
	return self.candyBarBar:GetValue()
end

--- Shows the bar and starts it off
function barPrototype:Start()
	self.running = true
	restyleBar(self)
	self:SetScript("OnUpdate", onUpdate)
	self:Show()
end
--- Stops the bar
-- This will stop the timerbar running fire the LibStaticCandyBar_Stop callback and then recycle the bar into the candybar barpool
-- Note: make sure you remove all references to the bar in your addon upon receiving the LibStaticCandyBar_Stop callback for that bar
-- @usage
-- -- The example below shows the use of the LibStaticCandyBar_Stop callback by printing the contents of the label in the chatframe
-- local function barstopped( callback, bar )
--   print( bar.candybarLabel:GetText(), "stopped")
-- end
-- LibStub("LibStaticCandyBar-1.0"):RegisterCallback(myaddonobject, "LibStaticCandyBar_Stop", barstopped)
function barPrototype:Stop()
	cb:Fire("LibStaticCandyBar_Stop", self)
	reset(self)
	tinsert(availableBars, self)
end

-- ------------------------------------------------------------------------------
-- Library functions
--

--- Creates a new timerbar object
--
-- @paramsig texture, width, height
-- @param texture Path to the texture used for the bar
-- @param width Width of the bar
-- @param height Height of the bar
-- @usage
-- -- Create a simple bar using a custom texture
-- mybar = Libstub("LibStaticCandyBar-1.0"):New("Interface\\AddOns\\MyAddOn\\media\\statusbar.tga", 100, 16)
local barCount = 1
function lib:New(texture, width, height)
	local bar = tremove(availableBars)
	if not bar then
		local frame = CreateFrame("Frame", "StaticCandyBar" .. barCount, UIParent)
		barCount = barCount + 1
		bar = setmetatable(frame, barPrototype_meta)
		local icon = bar:CreateTexture(nil, "BACKGROUND")
		icon:SetPoint("TOPLEFT", bar)
		icon:SetPoint("BOTTOMLEFT", bar)
		--icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		bar.candyBarIconFrame = icon
		local statusbar = CreateFrame("StatusBar", nil, bar)
		statusbar:SetPoint("TOPRIGHT", bar)
		statusbar:SetPoint("BOTTOMRIGHT", bar)
		bar.candyBarBar = statusbar
		local bg = statusbar:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bar.candyBarBackground = bg
		local progress = statusbar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmallOutline")
		progress:SetPoint("RIGHT", statusbar, -2, 0)
		bar.candyBarProgress = progress
		local name = statusbar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmallOutline")
		name:SetPoint("LEFT", statusbar, 2, 0)
		name:SetPoint("RIGHT", progress, "LEFT", -2, 0)
		bar.candyBarLabel = name
	else
		bar:SetLabel(nil)
		bar:SetIcon(nil)
	end
	bar.candyBarBar:SetStatusBarTexture(texture)
	bar.candyBarBackground:SetTexture(texture)
	bar.width = width
	bar.height = height
	reset(bar)
	return bar
end

