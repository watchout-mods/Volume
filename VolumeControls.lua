local MAJOR, Addon = ...;
LibStub("AceAddon-3.0"):NewAddon(Addon, MAJOR, "AceEvent-3.0");
local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true);
local path = "Interface\\AddOns\\Broker_MicroMenu\\media\\"

local log10, inc, min, max = math.log10, .05, math.min, math.max;
local dataobj;

---
-- @param category string
-- @param level range 0..1
local function Set_Volume(category, level)
	return SetCVar(category, (1/9)*(10^level - 1));
end

---
-- @param category string
local function Get_Volume(category)
	return log10(GetCVar(category) * 9 + 1);
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

function Addon:OnEnable()
	dataobj.text = ("%.2f"):format(self:GetMasterVolume());
end

dataobj = ldb:NewDataObject(MAJOR, {
	type = "data source",
	icon = 1706035,
	label = "Master Volume",
	text  = "",
	OnClick = function(self, button, ...)
		if button == "LeftButton" then
			Addon:DecreaseMasterVolume()
		elseif button == "RightButton" then
			Addon:IncreaseMasterVolume()
		end
		dataobj.text = ("%.2f"):format(Addon:GetMasterVolume());
	end
})
