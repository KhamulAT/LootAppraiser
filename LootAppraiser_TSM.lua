-- LootAppraiser_TSM.lua --
local LA = LibStub("AceAddon-3.0"):GetAddon("LootAppraiser")
--local L = LibStub("AceLocale-3.0"):GetLocale("LootAppraiser", true)


local TSM = LibStub("AceAddon-3.0"):GetAddon("TradeSkillMaster")
if(not TSM) then return end

local TSMAPI = _G.TSMAPI;
local TSMVERSION = TSM._version;

LA.TSM3 = string.startsWith("" .. TSMVERSION, "3X")

--------------------------------
-- Wrapper for TSMAPI methods --
--------------------------------

function LA:isItemInList(itemID, itemList)
	if not LA.TSM3 then
		local searchText = "item:" .. tostring(itemID)
		for a, _ in pairs(itemList) do
			if string.startsWith(a, searchText) then
				return true
			end
		end
		return false
	else
		return itemList["i:" .. itemID]
	end
end


function LA:ImportGroup(importStr, groupPath)
	if not LA.TSM3 then
		TSM:ImportGroup(importStr, groupPath) -- TSM2
	else
		TSM.Groups:Import(importStr, groupPath) -- TSM3
	end
end


function LA:GetGroupItems(path)
	if not LA.TSM3 then
		return TSM:GetGroupItems(path) -- TSM2
	else
		return TSM.Groups:GetItems(path) -- TSM3
	end
end

--[[-------------------------------------------------------------------------------------
-- this method encapsulate the spezial price source 'custom'
---------------------------------------------------------------------------------------]]
function LA:GetItemValue(itemID, priceSource)
	-- special handling for priceSource = 'Custom'
	if priceSource == "Custom" then
		if not LA.TSM3 then
			return TSMAPI:GetCustomPriceSourceValue(itemID, LootAppraiser.db.profile.customPriceSource) -- TSM2
		else 
			return TSMAPI:GetCustomPriceValue(LootAppraiser.db.profile.customPriceSource, itemID) -- TSM3
		end
	end

	-- TSM default price sources
	return TSMAPI:GetItemValue(itemID, priceSource)
end


function LA:GetItemID(itemString)
	if not LA.TSM3 then
		return TSMAPI:GetItemID(itemString, true) -- TSM2
	else 
		return TSMAPI.Item:ToItemID(itemString, true) -- TSM3
	end
end


function LA:FormatTextMoney(value) 
	if not LA.TSM3 then
		return TSMAPI:FormatTextMoney(value, nil, true, true, disabled) -- TSM2
	else
		return TSMAPI:MoneyToString(value, nil, true, true, disabled) -- TSM3
	end
end


function LA:ParseCustomPrice(value) 
	LA:Print("ParseCustomPrice(value=" .. tostring(value) .. ")")
	if not LA.TSM3 then
		return TSMAPI:ParseCustomPrice(value)
	else 
		return TSMAPI:ValidateCustomPrice(value)
	end
end

