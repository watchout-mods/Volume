local MAJOR, Addon = ...;
LibStub("AceAddon-3.0"):NewAddon(Addon, MAJOR, "AceEvent-3.0");
local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true);
local path = "Interface\\AddOns\\VolumeControls\\media\\"

local log10, inc, min, max = math.log10, .05, math.min, math.max;
local dataobj, frame;

---
-- @param category string
-- @param level range 0..1
local function Set_Volume(category, level)
	return SetCVar(category, (1 / 9) * (10 ^ level - 1));
end

---
-- @param category string
local function Get_Volume(category)
	return log10(GetCVar(category) * 9 + 1);
end

---
-- @param category string
local function Increase_Volume(category)
	return Set_Volume(category, min(1, Get_Volume(category) + inc));
end

---
-- @param category string
local function Decrease_Volume(category)
	return Set_Volume(category, max(0, Get_Volume(category) - inc));
end

---
-- @param category
-- @param direction if negative, decreases volume, increases volume if positive. Only the sign is
--                  used, the size does not matter.
local function Change_Volume(category, direction)
	if direction > 0 then
		Set_Volume(category, min(1, Get_Volume(category) + inc));
	elseif direction < 0 then
		Set_Volume(category, max(0, Get_Volume(category) - inc));
	end
	return Get_Volume(category);
end

-- https://github.com/tekkub/wow-globalstrings/blob/master/GlobalStrings/enUS.lua
local labels = {
	["Sound_MasterVolume"] = MASTER_VOLUME,
	["Sound_AmbienceVolume"] = AMBIENCE_VOLUME,
	["Sound_SFXVolume"] = SOUND_VOLUME,
	["Sound_MusicVolume"] = MUSIC_VOLUME,
	["Sound_DialogVolume"] = DIALOG_VOLUME,
}
local function Get_Label_Text(category)
	return labels[category];
end

---
-- @param value
local function GetFormattedValue(value)
	return ("%.0f%%"):format(value * 100)
end

---
-- @param level range 0..1
function Addon:SetMasterVolume(level)
	return Set_Volume("Sound_MasterVolume", level);
end

---
-- @return Modified master volume level
function Addon:GetMasterVolume()
	return Get_Volume("Sound_MasterVolume");
end

---
-- Increases the master volume by one increment
function Addon:IncreaseMasterVolume()
	return self:SetMasterVolume(min(1, self:GetMasterVolume() + inc));
end

---
-- Decreases the master volume by one increment
function Addon:DecreaseMasterVolume()
	return self:SetMasterVolume(max(0, self:GetMasterVolume() - inc));
end

---
function Addon:UpdateLdb()
	dataobj.text = GetFormattedValue(self:GetMasterVolume());
end

function Addon:OnEnable()
	dataobj.text = GetFormattedValue(self:GetMasterVolume());
	frame = self:CreateSliderFrame();
end

function Addon:ScheduleTimer()
end

function Addon:CancelTimer()
end

function Addon:ShowFrame(this)
	local point, relativePoint = "TOPLEFT", "BOTTOMLEFT";
	frame:ClearAllPoints();
	frame:SetPoint(point, this, relativePoint, 0, 0);
	frame:Show();
	GameTooltip:Hide();
end

function Addon:ToggleFrame(this)
	if frame:IsVisible() then
		frame:Hide();
	else
		self:ShowFrame(this);
	end
end

dataobj = ldb:NewDataObject(MAJOR, {
	type = "data source",
	icon = path .. "Speaker",
	label = "Master Volume",
	text  = "",
	OnClick = function(self, button, ...)
		Addon:ToggleFrame(self);
		Addon:UpdateLdb();
	end,
	OnMouseWheel = function(self, direction)
		Change_Volume("Sound_MasterVolume", direction);
		Addon:UpdateLdb();
	end
})


function Addon:CreateSliderWidget(frame, name, category, offset)
	-- Master Volume Slider
	local sliderName = "VolumeControls" .. name .. "Slider";

	-- Slider Label Text
	local sliderText = frame:CreateFontString();
	sliderText:SetFontObject(GameFontHighlightSmallLeft);
	sliderText:SetText(Get_Label_Text(category));
	sliderText:SetPoint("TOPLEFT", frame, 10, offset);

	-- Slider Text Value
	local sliderValue = frame:CreateFontString();
	sliderValue:SetFontObject(GameFontHighlightSmallLeft);
	sliderValue:SetPoint("TOPRIGHT", frame, -10, offset);

	-- Slider
	local sliderFrame = CreateFrame("Slider", sliderName, frame, "OptionsSliderTemplate");
	sliderFrame:SetWidth(180);
	sliderFrame:SetHeight(20);
	sliderFrame:SetOrientation("HORIZONTAL");
	sliderFrame:SetMinMaxValues(0, 1);
	sliderFrame.tooltipText = ("|cffffffff%s|r\nUse mouse wheel to change value."):format(category);
	sliderFrame:SetValue(-1);
	sliderFrame:SetValueStep(inc);
	sliderFrame:SetPoint("TOPLEFT", frame, 10, offset - 10);
	sliderFrame:EnableMouseWheel(1);

	sliderFrame:SetScript("OnShow", function(self, value)
		self:SetValue(Get_Volume(category));
	end);

	sliderFrame:SetScript("OnValueChanged", function(self, value)
		Set_Volume(category, value);
		sliderValue:SetText(GetFormattedValue(value));
		Addon:UpdateLdb();
	end);

	sliderFrame:SetScript("OnMouseWheel", function(self, delta)
		self:SetValue(Change_Volume(category, delta));
	end);

	sliderFrame:HookScript("OnEnter", function(self)
		Addon:CancelTimer(self);
	end);

	sliderFrame:Show();

	local labelLow = _G[sliderName .. "Low"];
	local labelHigh = _G[sliderName .. "High"];
	labelLow:SetText("");
	labelHigh:SetText("");

	return sliderFrame;
end

function Addon:CreateSliderFrame()
	local frame = CreateFrame("Frame", "VolumeControlsFrame", UIParent, "BackdropTemplate");
	frame:SetFrameStrata("DIALOG");
	frame:SetSize(200, 230);
	frame:SetClampedToScreen(true);
	frame:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }});
	frame:SetBackdropBorderColor(
		TOOLTIP_DEFAULT_COLOR.r,
		TOOLTIP_DEFAULT_COLOR.g,
		TOOLTIP_DEFAULT_COLOR.b );
	frame:SetBackdropColor(
		TOOLTIP_DEFAULT_BACKGROUND_COLOR.r,
		TOOLTIP_DEFAULT_BACKGROUND_COLOR.g,
		TOOLTIP_DEFAULT_BACKGROUND_COLOR.b );
	frame:Hide();

	frame:SetScript("OnShow", function(self)
		Addon:ScheduleTimer(self, 3);
	end);

	frame:SetScript("OnEnter", function(self)
		Addon:CancelTimer(self)
	end);

	frame:SetScript("OnLeave", function(self)
		if not MouseIsOver(self) then
			Addon:ScheduleTimer(self, 2);
		end
	end);

	local o, i = -10, -45;
	frame.SliderMaster = self:CreateSliderWidget(frame, "Master", "Sound_MasterVolume", o + 0 * i);
	frame.SliderSound = self:CreateSliderWidget(frame, "Sound", "Sound_SFXVolume", o + 1 * i);
	frame.SliderMusic = self:CreateSliderWidget(frame, "Music", "Sound_MusicVolume", o + 2 * i);
	frame.SliderAmbience = self:CreateSliderWidget(frame, "Ambience", "Sound_AmbienceVolume", o + 3 * i);
	frame.SliderDialog = self:CreateSliderWidget(frame, "Dialog", "Sound_DialogVolume", o + 4 * i);
	return frame;
end
