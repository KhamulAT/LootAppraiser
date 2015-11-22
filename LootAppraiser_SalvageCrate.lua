-- LootAppraiser_SalavageCrate.lua --
local LootAppraiser, LA = ...;

local SalvageCrate = LA:NewModule("SalvageCrate", "AceEvent-3.0")


--[[-------------------------------------------------------------------------------------
-- AceAddon-3.0 - module standard methods
---------------------------------------------------------------------------------------]]
function SalvageCrate:OnInitialize()
	Debug("SalvageCrate:OnInitialize()")

end

function SalvageCrate:OnEnable()
	Debug("SalvageCrate:OnEnable()")

	-- events for opening of salvage crates
	SalvageCrate:RegisterEvent("UNIT_SPELLCAST_START", onUnitSpellcast)
	SalvageCrate:RegisterEvent("UNIT_SPELLCAST_STOP", onUnitSpellcast)
	SalvageCrate:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", onUnitSpellcast)
	SalvageCrate:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", onUnitSpellcast)
	SalvageCrate:RegisterEvent("BAG_UPDATE", onBagUpdate)
end

function SalvageCrate:OnDisable()

end


--[[-------------------------------------------------------------------------------------
-- event handler for UNIT_SPELLCAST_...
-- ...START ("unitID", "spell", "rank", lineID, spellID)
-- ...STOP ("unitID", "spell", "rank", lineID, spellID)
-- ...SUCCEEDED ("unitID", "spell", "rank", lineID, spellID)
-- ...INTERRUPTED ("unitID", "spell", "rank", lineID, spellID)
---------------------------------------------------------------------------------------]]
local salvageSpellIDs = {["174798"] = true, ["168179"] = true, ["168178"] = true, ["168180"] = true}

local currentLineID = nil -- spell lineID counter.
local openEndTime = nil -- spell ends on this time
local bagSnapshot = {} -- bag snapshot
local newItems = {} -- list of new items
function onUnitSpellcast(event, unitID, spell, rank, lineID, spellID)

	if not isSessionRunning() then return end
	
	-- only salvage spells
	if not spellID or not salvageSpellIDs[tostring(spellID)] then
		return
	end

	if event == "UNIT_SPELLCAST_START" then
		-- store lineID for the upcomming events
		currentLineID = lineID
		bagSnapshot = {}
		openEndTime = nil

		Debug("    started: unitID=" .. unitID .. ", spell=" .. spell .. ", rank=" .. rank .. ", lineID=" .. tostring(lineID) .. ", spellID=" .. tostring(spellID))

		-- take a snapshot from the bags
		local freeSlots = 0
		for bag = 1, NUM_BAG_SLOTS, 1 do
			freeSlots = freeSlots + select(1, GetContainerNumFreeSlots(bag))
			for slot = 1, GetContainerNumSlots(bag), 1 do
				local itemID = GetContainerItemID(bag, slot)
				local count = select(2, GetContainerItemInfo(bag, slot))

				-- prepare key and value
				local key = "" .. tostring(bag) .. ":" .. tostring(slot)
				local value = "" .. tostring(itemID) .. ":" .. tostring(count)

				bagSnapshot[key] = value
			end
		end

		Debug("    free slots=" .. freeSlots)

	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then

		-- only events for the same lineID
		if currentLineID ~= lineID then
			return
		end

		Debug("    succeeded: unitID=" .. unitID .. ", spell=" .. spell .. ", rank=" .. rank .. ", lineID=" .. tostring(lineID) .. ", spellID=" .. tostring(spellID))

		openEndTime = time()
		newItems = {}

		Debug("    openEndTime=" .. tostring(openEndTime))

	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then

		-- only events for the same lineID
		if currentLineID ~= lineID then
			return
		end

		Debug("    interrupted: unitID=" .. unitID .. ", spell=" .. spell .. ", rank=" .. rank .. ", lineID=" .. tostring(lineID) .. ", spellID=" .. tostring(spellID))

		-- reset data
		currentLineID = nil
		openEndTime = nil
		bagSnapshot = {}

	end
end


--[[-------------------------------------------------------------------------------------
-- event handler for
-- ...BAG_UPDATE (bagID)
---------------------------------------------------------------------------------------]]
function onBagUpdate(event, bagID)

	if not isSessionRunning() then return end

	local currentTime = time()

	if not openEndTime or currentTime - openEndTime >= 3 then
		Debug("  loot window expired...")
		return
	end

	Debug("onBagUpdate(): bagID=" .. tostring(bagID))

	-- compare snapshot with the current bag and store diff
	for slot = 1, GetContainerNumSlots(bagID), 1 do
		local itemID = GetContainerItemID(bagID, slot)
		local newCount = select(2, GetContainerItemInfo(bagID, slot))

		-- prepare key and current value
		local key = "" .. tostring(bagID) .. ":" .. tostring(slot)
		local newValue = "" .. tostring(itemID) .. ":" .. tostring(newCount)

		-- compare with snapshot
		local oldValue = bagSnapshot[key]
		if oldValue ~= newValue then				
			Debug("    different value for key=" .. key .. ", " .. tostring(oldValue) .. " vs. " .. tostring(newValue))

			-- first time see?
			if newItems[key] == nil then
				Debug("      processing")
				
				-- new item
				newItems[key] = newValue -- store so we only process once

				-- prepare input for processItem(...)
				local oldItemId = nil
				local oldCount = 0

				if oldValue ~= nil then
					local oldValueTokens = split(oldValue, ":")

					oldItemId = oldValueTokens[1]
					oldCount = tonumber(oldValueTokens[2]) or 0
				end


				if oldItemId ~= newItemID then
					Debug("        item on this pos changed: " .. tostring(oldItemId) .. " vs. " .. tostring(newItemID) .. " -> set count to 0")
					-- old item is gone (e.g. open the last salvage crate on this position) so we also don't want the old count
					oldCount = 0
				end

				if newCount == nil then
					newCount = 0
				end

				-- only process this item if the newCount > oldCount
				if newCount > oldCount then
					-- give item info to loot appraiser processing
					local itemLink = select(7, GetContainerItemInfo(bagID, slot))
					local quantity = newCount - oldCount

					--processItem(itemLink, ItemID, ItemQty)
					handleItemLooted(itemLink, itemID, quantity)
				end
			else
				Debug("      already processed -> ignore")
			end
		end
	end
end


function split(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, 
    	function(c) 
    		fields[#fields+1] = c 
    	end
    )
    return fields
end
