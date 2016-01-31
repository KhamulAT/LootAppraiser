-- LootAppraiser_TSM.lua --
local LA = LibStub("AceAddon-3.0"):GetAddon("LootAppraiser")
--local L = LibStub("AceLocale-3.0"):GetLocale("LootAppraiser", true)


local TSM = LibStub("AceAddon-3.0"):GetAddon("TradeSkillMaster")
if(not TSM) then return end

local TSMAPI = _G.TSMAPI;
local TSMVERSION = TSM._version;

LA.TSM3 = string.startsWith("" .. TSMVERSION, "v3") or string.startsWith("" .. TSMVERSION, "3X")

--------------------------------
-- Wrapper for TSMAPI methods --
--------------------------------

function LA:isItemInGroup(itemID, group)
	if not LA.TSM3 then
		-- tsm 2
		local path = TSMAPI:GetGroupPath("item:" .. tostring(itemID))
		return path == group
	else
		-- tsm 3
		local path = TSMAPI.Groups:GetPath("i:" .. tostring(itemID))
		return path == group
	end
end

--[[
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
		--local path = TSMAPI.Groups:GetPath("i:" .. tostring(itemID))
		--LA:D("    #### get path for item " .. tostring(itemID) .. ": " ..  tostring(path))

		return itemList["i:" .. itemID]
	end
end
]]

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
		LA:D("    price source (custom): " ..  LA.db.profile.pricesource.customPriceSource)
		if not LA.TSM3 then
			return TSMAPI:GetCustomPriceSourceValue(itemID, LA.db.profile.pricesource.customPriceSource) -- TSM2
		else 
			return TSMAPI:GetCustomPriceValue(LA.db.profile.pricesource.customPriceSource, itemID) -- TSM3
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
	local disabled -- ???
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


function LA:GetPriceSources()
	if not LA.TSM3 then
		return TSMAPI:GetPriceSources()
	else
		return select(1, TSMAPI:GetPriceSources())
	end
end


--[[-------------------------------------------------------------------------------------
-- returns a table with the filtered available price sources
---------------------------------------------------------------------------------------]]
function LA:GetAvailablePriceSources()
	--LA:D("GetAvailablePriceSources()")

	local priceSources = {}
	local keys = {}

	-- filter
	local tsmPriceSources = LA:GetPriceSources()
	--LA:print_r(tsmPriceSources)
	for k, v in pairs(tsmPriceSources) do
		if LA.PRICE_SOURCE[k] then
			--LA:D("  add price source " .. tostring(k))
			--priceSources[k] = LA.PRICE_SOURCE[k]
			table.insert(keys, k)
		else
			--LA:D("  skip price source " .. tostring(k))
		end
	end
	
	--LA:print_r(keys)

	-- add custom
	table.insert(keys, "Custom")

	sort(keys)

	--LA:print_r(keys)

	for _,v in ipairs(keys) do
		priceSources[v] = LA.PRICE_SOURCE[v]
	end

	return priceSources
end