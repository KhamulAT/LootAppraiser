-- init ace stuff
local LootAppraiser, la = ...;
local LA = LibStub("AceAddon-3.0"):NewAddon(la, LootAppraiser, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "LibSink-2.0")

local AceGUI = LibStub("AceGUI-3.0")
local LibToast = LibStub("LibToast-1.0")
local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")

LA.DEBUG = false

LA.METADATA = {
	NAME = GetAddOnMetadata(..., "Title"), 
	VERSION = GetAddOnMetadata(..., "Version")
}

-- GUI related local vars
-- frames
local START_SESSION_PROMPT, MAIN_UI 
-- single elements
local VALUE_TOTALCURRENCY, VALUE_LOOTEDITEMVALUE, VALUE_LOOTEDITEMCOUNTER, VALUE_NOTEWORTHYITEMCOUNTER, VALUE_SESSIONDURATION, VALUE_ZONE


local sessionIsRunning = false 			-- is currently a session running?
local lootAppraiserDisabled = false		-- is LootAppraiser disabled?

local currentSession = nil

local startSessionPromptAlreadyAnswerd = false -- is the start session prompt already answered?

local totalLootedCurrency = 0   	-- the total looted currency during a session
local totalItemValue = 0        	-- the total looted item value
local lootedItemCounter = 0			-- counter for looted items
local noteworthyItemCounter = 0		-- counter for noteworthy items
local lootedItemValuePerHour = 0	-- looted item value / h

local dbDefaults

local ITEM_FILTER_VENDOR = {
	--DEFAULT ITEM IDs BELOW TO VENDORSELL PRICING
	["1205"] = true, ["3770"] = true, ["104314"] = true, ["11444"] = true, ["104314"] = true, 
	["11444"] = true, ["117437"] = true, ["117439"] = true, ["117442"] = true, ["117453"] = true, 
	["117568"] = true, ["1179"] = true, ["117"] = true, ["159"] = true, ["1645"] = true, 
	["1707"] = true, ["1708"] = true, ["17344"] = true, ["17404"] = true, ["17406"] = true, 
	["17407"] = true, ["19221"] = true, ["19222"] = true, ["19223"] = true, ["19224"] = true, 
	["19225"] = true, ["19299"] = true, ["19300"] = true, ["19304"] = true, ["19305"] = true, 
	["19306"] = true, ["2070"] = true, ["20857"] = true, ["21151"] = true, ["21215"] = true, 
	["2287"] = true, ["2593"] = true, ["2594"] = true, ["2595"] = true, ["2596"] = true, 
	["2723"] = true, ["27854"] = true, ["27855"] = true, ["27856"] = true, ["27857"] = true, 
	["27858"] = true, ["27859"] = true, ["27860"] = true, ["28284"] = true, ["28399"] = true, 
	["29453"] = true, ["29454"] = true, ["33443"] = true, ["33444"] = true, ["33445"] = true, 
	["33449"] = true, ["33451"] = true, ["33452"] = true, ["33454"] = true, ["35947"] = true, 
	["35948"] = true, ["35951"] = true, ["3703"] = true, ["37252"] = true, ["3771"] = true, 
	["3927"] = true, ["40042"] = true, ["414"] = true, ["41731"] = true, ["422"] = true, 
	["44570"] = true, ["44940"] = true, ["44941"] = true, ["4536"] = true, ["4537"] = true, 
	["4538"] = true, ["4539"] = true, ["4540"] = true, ["4541"] = true, ["4542"] = true, 
	["4544"] = true, ["4592"] = true, ["4593"] = true, ["4594"] = true, ["4595"] = true, 
	["4599"] = true, ["4600"] = true, ["4601"] = true, ["4602"] = true, ["4604"] = true, 
	["4605"] = true, ["4606"] = true, ["4607"] = true, ["4608"] = true, ["58256"] = true, 
	["58257"] = true, ["58258"] = true, ["58259"] = true, ["58260"] = true, ["58261"] = true, 
	["58262"] = true, ["58263"] = true, ["58264"] = true, ["58265"] = true, ["58266"] = true, 
	["58268"] = true, ["58269"] = true, ["59029"] = true, ["59230"] = true, ["61982"] = true, 
	["61985"] = true, ["61986"] = true, ["73260"] = true, ["74822"] = true, ["787"] = true, 
	["81400"] = true, ["81401"] = true, ["81402"] = true, ["81403"] = true, ["81404"] = true, 
	["81405"] = true, ["81406"] = true, ["81407"] = true, ["81408"] = true, ["81409"] = true, 
	["81410"] = true, ["81411"] = true, ["81412"] = true, ["81413"] = true, ["81414"] = true, 
	["81415"] = true, ["8766"] = true, ["8932"] = true, ["8948"] = true, ["8950"] = true, 
	["8952"] = true, ["8953"] = true, ["9260"] = true, ["20404"] = true	
}

local ITEM_FILTER_BLACKLIST = {
	--These items are from AQ20.  All of the Idols and Scarabs are Blacklisted.
	["20858"] = true, ["20859"] = true, ["20860"] = true, ["20861"] = true, ["20862"] = true, ["20863"] = true, ["20864"] = true,
	["20865"] = true, ["20874"] = true, ["20866"] = true, ["20868"] = true, ["20869"] = true, ["20870"] = true,
	["20871"] = true, ["20872"] = true, ["20873"] = true, ["20867"] = true, ["20875"] = true, ["20876"] = true, ["20877"] = true,
	["20878"] = true, ["20879"] = true, ["20881"] = true, ["20882"] = true, ["19183"] = true, ["18640"] = true, ["8623"]  = true,
	["114120"] = true, ["114116"] = true, ["9243"] = true
}

LA.QUALITY_FILTER = { -- little hack to sort them in the menu
	["0"] = "|cff9d9d9dPoor|r", 
	["1"] = "|cffffffffCommon|r", 
	["2"] = "|cff1eff00Uncommon|r", 
	["3"] = "|cff0070ddRare|r", 
	["4"] = "|cffa335eeEpic|r"
};

-- TSM predefined price sources + 'Custom'
LA.PRICE_SOURCE = {
	["Custom"] = "Custom Price Source",
	["DBGlobalHistorical"] = "AuctionDB: Global Historical Price",
	["DBGlobalMarketAvg"] = "AuctionDB: Global Market Value Avg",
	["DBGlobalMinBuyoutAvg"] = "AuctionDB: Global Min Buyout Avg",
	["DBGlobalSaleAvg"] = "AuctionDB: Global Sale Average",
	["DBHistorical"] = "AuctionDB: Historical Price",
	["DBMarket"] = "AuctionDB: Market Value",
	["DBMinBuyout"] = "AuctionDB: Min Buyout",
	["VendorSell"] = "VendorSell: Sell to Vendor cost",
	["wowuctionMarket"] = "wowuction: Realm Market Value",
	["wowuctionMedian"] = "wowuction: Realm Median Price",
	["wowuctionRegionMarket"] = "wowuction: Region Market Value",
	["wowuctionRegionMedian"] = "wowuction: Region Median Price"
};

-- define toast template
LibToast:Register(LootAppraiser, 
	function(toast, text, iconTexture, qualityID, amountGained, itemValue)
		local _, _, _, hex = _G.GetItemQualityColor(qualityID)

		toast:SetFormattedTitle("|c%s%s|r %s", hex, text, amountGained > 1 and _G.PARENS_TEMPLATE:format(amountGained) or "")
		toast:SetText(itemValue)

		if iconTexture then
			toast:SetIconTexture(iconTexture)
		end
	end
)

--[[-------------------------------------------------------------------------------------
-- prepare minimap icon
---------------------------------------------------------------------------------------]]
local _laLDB = LibStub("LibDataBroker-1.1"):NewDataObject(LA.METADATA.NAME, {
	type = "launcher",
	text = "Loot Appraiser", -- for what?
	icon = "Interface\\Icons\\Ability_Racial_PackHobgoblin",
	OnClick = function(self, button, down)
		if button == "LeftButton" then
			if not isSessionRunning() then
		        StartSession(true)        
		    end

		    ShowMainWindow()
		elseif button == "RightButton" then
			DEFAULT_CHAT_FRAME:AddMessage("Open LootAppraiser Config")

			InterfaceOptionsFrame_OpenToCategory(LA.METADATA.NAME)
			InterfaceOptionsFrame_OpenToCategory(LA.METADATA.NAME)
		end
	end,
	OnTooltipShow = function (tooltip)
		miniMapIconOnTooltipShow(tooltip)
	end
})
local _icon = LibStub("LibDBIcon-1.0")

function miniMapIconOnTooltipShow(tooltip)
	tooltip:AddLine(LA.METADATA.NAME .. " " .. LA.METADATA.VERSION, 1 , 1, 1)
	tooltip:AddLine("|cFFFFFFCCLeft-Click|r to open the main window")
	tooltip:AddLine("|cFFFFFFCCRight-Click|r to open options window")
	tooltip:AddLine("|cFFFFFFCCDrag|r to move this button")
	tooltip:AddLine(" ") -- spacer

	if isSessionRunning() then
		local delta =  time() - currentSession["start"]

		-- don't show seconds
		local noSeconds = false
		if delta > 3600 then
			noSeconds = true
		end

		tooltip:AddDoubleLine("Session is running: ", SecondsToTime(delta, noSeconds, false))
	else
		tooltip:AddLine("Session is not running")
	end
end

--[[-------------------------------------------------------------------------------------
-- AceAddon-3.0 standard methods
---------------------------------------------------------------------------------------]]
function LA:OnInitialize()
	Debug("LA:OnInitialize()")

	initDB()

	LA:SetSinkStorage(LA.db.profile.notification.sink)

	-- minimap icon --
	_icon:Register(LA.METADATA.NAME, _laLDB, LA.db.profile.minimapIcon)

	-- options
	--LA:SetupOptions()
end

function LA:OnEnable()
	LA:Print("LootAppraiser ENABLED.")

	-- register chat commands
	LA:RegisterChatCommand("la", chatCmdLootAppraiser)

	-- register event for...
	-- ...loot window open
	LA:RegisterEvent("LOOT_OPENED", onLootOpened)

	-- set DEBUG=true if player is Netatik-Antonidas --
	local nameString = GetUnitName("player", true)
	local realm = GetRealmName()

	if nameString == "Netatik" and realm == "Antonidas" then
		Debug("DEBUG enabled")
		LA.DEBUG = true
	end
end

function LA:OnDisable()
	-- nothing to do
end

--[[-------------------------------------------------------------------------------------
-- init lootappriaser db
---------------------------------------------------------------------------------------]]
function initDB()
	Debug("initDB()")

	local parentWidth = UIParent:GetWidth()
	local parentHeight = UIParent:GetHeight()
--[[
	dbDefaults = {
		profile = {
			minimapIcon = {
				-- minimap icon position and visibility
				hide = false,
				minimapPos = 220,
				radius = 80,
			},
			["priceSource"] = "DBGlobalMarketAvg",
			["customPriceSource"] = "",
			["qualityFilter"] = "1",
			["goldAlertThreshold"] = "300",
			["ignoreRandomEnchants"] = true,
			["sellTrashUseTsmGroup"] = false,
			["tsmGroup4SellTrash"] = "LootAppraiser`Trash",
			["blacklistUseTsmGroup"] = false,
			["tsmGroup4Blacklist"] = "LootAppraiser`Blacklist",
			["destroyBlacklistedItems"] = false,
			mainUI = {
				["height"] = 400,
				["top"] = (parentHeight-50),
				["left"] = 50,
				["width"] = 400,
			},
			dockUI = {
				["height"] = 60,
				["top"] = (parentHeight-50),
				["left"] = 50,
				["width"] = 150,
			},
			goldAlertUI = {
				["height"] = 60,
				["top"] = (parentHeight-50),
				["left"] = 475,
				["width"] = 150,
			},
			liteUI = {
				["height"] = 60,
				["top"] = (parentHeight-150),
				["left"] = 475,
				["width"] = 150,
			}
		},
		global = {
			items = {
			},
			runs = {
			},
		},
	}	
]]

	dbDefaults = {
		profile = {
			minimapIcon = {
				-- minimap icon position and visibility
				hide = false,
				minimapPos = 220,
				radius = 80,
			},
			mainUI = {
				["height"] = 400,
				["top"] = (parentHeight-50),
				["left"] = 50,
				["width"] = 400,
			},
			priceSource = "DBGlobalMarketAvg",
			qualityFilter = "1",
			goldAlertThreshold = "300",
			ignoreRandomEnchants = true,
			general = {
				display = {
					showZoneInfo = true,
					showSessionDuration = true,
					showLootedItemValue = true,
					showLootedItemValuePerHour = true,
					showCurrencyLooted = true,
					showItemsLooted = true,
					showNoteworthyItems = true,
				},
			},
			notification = {
				sink = {},
				enableToasts = true,
				playSoundEnabled = true,
				soundName = "Auction Window Open",
			},
			sellTrash = {
				tsmGroupEnabled = false,
				tsmGroup = "LootAppraiser`Trash",
			},
			blacklist = {
				tsmGroupEnabled = false,
				tsmGroup = "LootAppraiser`Blacklist",	
				addBlacklistedItems2DestroyTrash = false,			
			},
			sessionData = {
				groupBy = "datetime",
			},
		},
		global = {			
			sessions = {

			},
		},
	}
	
	-- load the saved db values
	LA.db = LibStub:GetLibrary("AceDB-3.0"):New("LootAppraiserDB", dbDefaults, true)
end


--[[-------------------------------------------------------------------------------------
-- open loot appraiser and start a new session
---------------------------------------------------------------------------------------]]
function chatCmdLootAppraiser()
    if not isSessionRunning() then
        StartSession(true)        
    end

    ShowMainWindow()
end


--[[-------------------------------------------------------------------------------------
-- event handler
---------------------------------------------------------------------------------------]]
function onLootOpened(event, ...)
	-- is LootAppraiser disabled?
	if lootAppraiserDisabled then return end

	-- is a loot appraiser session running?
	if not isSessionRunning() then
		-- no session -> should we ask for session start?
		if not startSessionPromptAlreadyAnswerd then
			-- save current loot
			saveCurrentLoot()

			-- and open dialog
			ShowStartSessionDialog()
		end
	else
		-- Cycle through each looted item --
		for i = 1, GetNumLootItems() do
			local slotType = GetLootSlotType(i)

			if slotType == 1 then
				-- item looted
				--Debug("item looted")
				
				-- Get Information about Item Looted --
				local itemLink = GetLootSlotLink(i)
				local itemID = LA:GetItemID(itemLink, true) -- get item id

				local quantity = select(3, GetLootSlotInfo(i))

				handleItemLooted(itemLink, itemID, quantity)

			elseif slotType == 2 then
				-- currency looted
				--Debug("currency looted")

				local lootedCoin = select(2, GetLootSlotInfo(i))
				local lootedCopper = getLootedCopperFromText(lootedCoin)

				handleCurrencyLooted(lootedCopper)
			end
		end
	end
end

--[[-------------------------------------------------------------------------------------
-- the main logic for item processing
---------------------------------------------------------------------------------------]]
function handleItemLooted(itemLink, itemID, quantity)
	Debug("handleItemLooted itemID=" .. itemID)

    local quality = select(3, GetItemInfo(itemID))

    -- overwrite link if we only want base items					
	if getIgnoreRandomEnchants() then
		itemLink = select(2, GetItemInfo(itemID)) -- we use the link from GetItemInfo(...) because GetLootSlotLink(...) returns not the base item
	end

    local singleItemValue = LA:GetItemValue(itemID, getPriceSource()) or 0 -- single item

    -- blacklisted items
    if ITEM_FILTER_BLACKLIST[tostring(itemID)] then

		Debug("  item filter blacklist -> ignored")
		return

    elseif quality >= getQualityFilter() then

    	-- special handling for poor quality items
    	if quality == 0 then
    		Debug("  poor quality -> VendorSell")

			singleItemValue = LA:GetItemValue(itemID, "VendorSell") or 0
		end

		-- special handling for item filter vendor sell
		if ITEM_FILTER_VENDOR[tostring(itemID)] then
			Debug("  item filter vendor -> VendorSell")

			singleItemValue = LA:GetItemValue(itemID, "VendorSell") or 0
		end

		-- special handling for soulbound items
		if singleItemValue == 0 and quality >= 1 then
			Debug("  item value = 0 -> soulbound item")

			singleItemValue = LA:GetItemValue(itemID, "VendorSell") or 0
		end

    	local itemValue = singleItemValue * quantity

		--handleCurrencyLooted(itemValue)
		incLootedItemCounter(quantity)											-- increase looted item counter
		addItemValue2LootedItemValue(itemValue) 								-- add item value
		addItem2LootCollectedList(itemID, itemLink, quantity, itemValue, false) -- add item

		-- gold alert treshold
		local goldValue = floor(singleItemValue/10000)	
		if goldValue >= getGoldAlertThreshold() then

			incNoteworthyItemCounter(quantity)

			-- print to configured output 'channel'
			local formattedValue = LA:FormatTextMoney(singleItemValue) or 0
			LA:Pour(itemLink.." x"..quantity..": "..formattedValue)

			-- toast
			if isToastsEnabled() then
				local name, _, _, _, _, _, _, _, _, texturePath = _G.GetItemInfo(itemID)
				LibToast:Spawn(LootAppraiser, name, texturePath, quality, quantity, formattedValue)
			end

			-- add item to current session
			local itemCountCurrentSession = currentSession.noteworthyItems[tostring(itemID)]
			if itemCountCurrentSession == nil then
				currentSession.noteworthyItems[tostring(itemID)] = quantity
			else
				currentSession.noteworthyItems[tostring(itemID)] = itemCountCurrentSession + quantity
			end

			-- play sound (if enabled)
			if isPlaySoundEnabled() then
				--PlaySound("AuctionWindowOpen", "master");
				local soundName = LA.db.profile.notification.soundName or "None"
				PlaySoundFile(LSM:Fetch("sound", soundName))
			end

			-- check current mapID with session mapID
			Debug("  current vs. session mapID: " .. GetCurrentMapAreaID() .. " vs. " .. currentSession["mapID"])
		end
	else
		Debug("  item quality to low -> ignored")
    end
end

--[[-------------------------------------------------------------------------------------
-- handle looted currency
---------------------------------------------------------------------------------------]]
function handleCurrencyLooted(lootedCopper)
	-- add to total looted currency 
	totalLootedCurrency = totalLootedCurrency + lootedCopper 

	-- show the new value in main ui (if shown)
	if MAIN_UI then
		if isShowCurrencyLootedEnabled() then
			-- format the total looted currency...
			local formattedValue = LA:FormatTextMoney(totalLootedCurrency) or 0

			-- add to main ui
			VALUE_TOTALCURRENCY:SetText(formattedValue)
		end
	end
end

--[[-------------------------------------------------------------------------------------
-- save the current loot during 'start session?' dialog so we miss no loot if we start
-- a new session
---------------------------------------------------------------------------------------]]
local savedLoot = {}
function saveCurrentLoot()
	if not tablelength(savedLoot) == 0 then Debug("savedLoot is not empty...") end

	savedLoot = {}

	for i = 1, GetNumLootItems() do
		local slotType = GetLootSlotType(i)

		if slotType == 1 then
			-- item looted
			Debug("item looted (save)")
				
			-- Get Information about Item Looted --
			local itemLink = GetLootSlotLink(i)
			local itemID = LA:GetItemID(itemLink, true) -- get item id

			local quantity = select(3, GetLootSlotInfo(i))

			Debug("  item = " .. tostring(itemID))

			local data = {}
			data["link"] = itemLink
			data["quantity"] = quantity

			savedLoot[itemID] = data

		elseif slotType == 2 then
			-- currency looted
			Debug("currency looted (save)")

			local lootedCoin = select(2, GetLootSlotInfo(i))
			local lootedCopper = getLootedCopperFromText(lootedCoin)

			Debug("  lootedCopper = " .. tostring(lootedCopper))

			savedLoot["currency"] = lootedCopper
		end

		Debug("  savedLoot = " .. tostring(tablelength(savedLoot)))
	end
end

--[[-------------------------------------------------------------------------------------
-- GUIs
---------------------------------------------------------------------------------------]]

-- 'start session' dialog --
function ShowStartSessionDialog() 
	if START_SESSION_PROMPT then return end -- gui is already open
	local openLootAppraiser = true

	-- create 'start session prompt' frame
	START_SESSION_PROMPT = AceGUI:Create("Frame")
	START_SESSION_PROMPT:SetLayout("Flow")
	START_SESSION_PROMPT:SetTitle("Would you like to start a LootAppraiser session?")
	START_SESSION_PROMPT:SetPoint("CENTER")
	START_SESSION_PROMPT:SetWidth(250)
	START_SESSION_PROMPT:SetHeight(115)
	START_SESSION_PROMPT:EnableResize(false)
	START_SESSION_PROMPT:SetCallback("OnClose",
		function(widget) 
			AceGUI:Release(widget)
			START_SESSION_PROMPT = nil
		end
	)
	
	-- Button: Yes
	local btnYes = AceGUI:Create("Button")
	btnYes:SetPoint("CENTER")
	btnYes:SetAutoWidth(true)
	btnYes:SetText("Yes" .. " ")
	btnYes:SetCallback("OnClick", 
		function()
			StartSession(openLootAppraiser)

            START_SESSION_PROMPT:Release()
            START_SESSION_PROMPT = nil
		end
	)
	START_SESSION_PROMPT:AddChild(btnYes)
	
	-- Button: No
	local btnNo = AceGUI:Create("Button")
	btnNo:SetPoint("CENTER")
	btnNo:SetAutoWidth(true)
	btnNo:SetText("No" .. " ")
	btnNo:SetCallback("OnClick", 
		function()
			DisableLootAppraiser()

            START_SESSION_PROMPT:Release()
            START_SESSION_PROMPT = nil
		end
	)	
	START_SESSION_PROMPT:AddChild(btnNo)

	-- Checkbox: Open LA window	
	local checkboxOpenWindow = AceGUI:Create("CheckBox")
	checkboxOpenWindow:SetValue(openLootAppraiser)
	checkboxOpenWindow:SetLabel(" " .. "Open LootAppraiser window")

	START_SESSION_PROMPT:AddChild(checkboxOpenWindow)

	START_SESSION_PROMPT.statustext:Hide()
end

--[[-------------------------------------------------------------------------------------
-- starte a new session
---------------------------------------------------------------------------------------]]
function StartSession(openLootAppraiser)

	startSessionPromptAlreadyAnswerd = true
	lootAppraiserDisabled = false

	if isSessionRunning() then
		LA:Print("LootAppraiser is already running!")
	else
		LA:Print("Session started")
		Debug("  mapID=" .. GetCurrentMapAreaID() .. " (" .. GetMapNameByID(GetCurrentMapAreaID()) .. ")")
		--printSessions() -- TODO remove

		sessionIsRunning = true

		-- start: prepare session (for statistics)
		currentSession = {}
		currentSession["start"] = time()
		currentSession["mapID"] =  GetCurrentMapAreaID()

		currentSession["settings"] = {}
		currentSession.settings["qualityFilter"] = getQualityFilter()
		currentSession.settings["gat"] = getGoldAlertThreshold()

		currentSession["noteworthyItems"] = {}

		local nameString = GetUnitName("player", true)
		local realm = GetRealmName()

		currentSession.player = nameString .. "-" .. realm

		local sessions = LA.db.global.sessions
		local nextId = #sessions + 1

		tinsert(LA.db.global.sessions, currentSession)
		-- end: prepare session (for statistics)

        -- show main window
		if openLootAppraiser then
			ShowMainWindow()
		end

		-- process saved loot
		Debug("  savedLoot = " .. tostring(tablelength(savedLoot)))
		Debug("  process saved loot")
		for k,v in pairs(savedLoot) do
			if k == "currency" then
				-- currency
				handleCurrencyLooted(v)
			else
				-- item
				local itemID = k

				local itemLink = v["link"]
				local quantity = v["quantity"]

				handleItemLooted(itemLink, itemID, quantity)
			end
		end

		-- reset var
		savedLoot = {}
	end
end


function printSessions()
	if not LA.DEBUG then return end

	local sessions = LA.db.global.sessions
	for i,v in ipairs(sessions) do
		local sessionMapID = v["mapID"]
		local sessionStart = v["start"];
		local sessionEnd = v["end"];
		local liv = v["liv"]

		if sessionEnd ~= nil then
			Debug("  session " .. tostring(i))
			Debug("    time: " .. date("%x", sessionStart))

			local mapName
			if sessionMapID ~= nil then
				mapName = GetMapNameByID(sessionMapID)
			end
			Debug("    map: " .. tostring(sessionMapID) .. " (" .. tostring(mapName) .. ")")

			local sessionDuration = sessionEnd - sessionStart
			Debug("    duration: " .. SecondsToTime(sessionDuration))

			local factor = 3600
			if sessionDuration < factor then
				factor = sessionDuration
			end

			local formattedLiv = LA:FormatTextMoney(liv) or 0
			Debug("    looted item value: " .. formattedLiv)

			local livGold = floor(liv/10000)
			local livGoldPerHour = floor(livGold/sessionDuration*factor)
			Debug("    liv/h: " .. tostring(livGoldPerHour) .. "g/h")
		else
			-- missing end -> remove entry
			Debug("  session " .. tostring(i) .. " is invalid (missing end)")
			--sessions[i] = nil
		end
	end
end

function DisableLootAppraiser()
	LA:Print("Disabling LootAppraiser.")

	startSessionPromptAlreadyAnswerd = true
	lootAppraiserDisabled = true

	savedLoot = {}
end

--[[-------------------------------------------------------------------------------------
-- refresh the main ui
---------------------------------------------------------------------------------------]]
function LA:refreshMainWindow()
	if MAIN_UI ~= nil then
		--Debug("refreshMainWindow")
		MAIN_UI:Hide()
		--MAIN_UI:DoLayout()
		--MAIN_UI:Show()
		MAIN_UI = nil
		ShowMainWindow()
	end
end

-- main window --
local total = 0
function ShowMainWindow() 
	Debug("ShowMainWindow")

	if MAIN_UI then 
		MAIN_UI:Show()
		return
	end 

	local labelWidth = 120
	local valueWidth = 240

	local mainUiHeight = 270
	local rowHeight = 16

	MAIN_UI = AceGUI:Create("Frame")
	MAIN_UI:SetStatusTable(LA.db.profile.mainUI)
	MAIN_UI:SetTitle(LA.METADATA.NAME .. " v" .. LA.METADATA.VERSION .. ": Make Farming Sexy!")
	MAIN_UI:SetLayout("Flow")
	MAIN_UI:SetWidth(400) 
	MAIN_UI:EnableResize(false)
	MAIN_UI.frame:SetScript("OnUpdate", 
		function(event, elapsed)
			total = total + elapsed
    		if total >= 1 then
		        refreshLivPerHour()
		        refreshSessionDuration()
		        total = 0
		    end	
		end
	)

	LA:refreshStatusText()

	-- TODO add other elemenst to the window

	-- loot collected list --
	local backdrop = {
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], 
		edgeSize = 2,
		insets = { 
			left = 1, 
			right = 1, 
			top = 1, 
			bottom = 1 
		}
	}

	local GUI_SCROLLCONTAINER = AceGUI:Create("SimpleGroup")
	GUI_SCROLLCONTAINER:SetFullWidth(true)
	GUI_SCROLLCONTAINER:SetHeight(140)
	GUI_SCROLLCONTAINER:SetLayout("Fill")
	GUI_SCROLLCONTAINER.frame:SetBackdrop(backdrop)
	GUI_SCROLLCONTAINER.frame:SetBackdropColor(0, 0, 0)
	GUI_SCROLLCONTAINER.frame:SetBackdropBorderColor(0.4, 0.4, 0.4)

	GUI_LOOTCOLLECTED = AceGUI:Create("ScrollFrame")
	GUI_LOOTCOLLECTED:SetLayout("Flow")
	GUI_SCROLLCONTAINER:AddChild(GUI_LOOTCOLLECTED)	
	MAIN_UI:AddChild(GUI_SCROLLCONTAINER)

	addSpacer(MAIN_UI)

	-- current zone (session zone)
	if isShowZoneInfoEnabled() then
		mainUiHeight = mainUiHeight + rowHeight

		local LABEL_ZONE = AceGUI:Create("Label")
		LABEL_ZONE:SetText("Zone:")
		LABEL_ZONE:SetWidth(labelWidth)
		LABEL_ZONE:SetFont("Fonts\\FRIZQT__.TTF", 12)
		MAIN_UI:AddChild(LABEL_ZONE)

		VALUE_ZONE = AceGUI:Create("Label")
		VALUE_ZONE:SetText(" ")
		VALUE_ZONE:SetWidth(valueWidth)
		VALUE_ZONE:SetFont("Fonts\\FRIZQT__.TTF", 12)
		VALUE_ZONE.label:SetJustifyH("RIGHT")
		MAIN_UI:AddChild(VALUE_ZONE)	

		refreshZoneInfo()
	end

	-- session duration
	if isShowSessionDurationEnabled() then
		mainUiHeight = mainUiHeight + rowHeight

		local LABEL_SESSIONDURATION = AceGUI:Create("Label")
		LABEL_SESSIONDURATION:SetText("Session Duration:")
		LABEL_SESSIONDURATION:SetWidth(labelWidth)
		LABEL_SESSIONDURATION:SetFont("Fonts\\FRIZQT__.TTF", 12)
		MAIN_UI:AddChild(LABEL_SESSIONDURATION)

		VALUE_SESSIONDURATION = AceGUI:Create("Label")
		VALUE_SESSIONDURATION:SetText(" ")
		VALUE_SESSIONDURATION:SetWidth(valueWidth)
		VALUE_SESSIONDURATION:SetFont("Fonts\\FRIZQT__.TTF", 12)
		VALUE_SESSIONDURATION.label:SetJustifyH("RIGHT")
		MAIN_UI:AddChild(VALUE_SESSIONDURATION)

		refreshSessionDuration()
	end

	-- looted item value --
	-- format the total looted item value...
	if isShowLootedItemValueEnabled() then
		mainUiHeight = mainUiHeight + rowHeight
		
		local livValue = LA:FormatTextMoney(totalItemValue) or 0
		if isShowLootedItemValuePerHourEnabled() then
			livValue = livValue .. " (" .. lootedItemValuePerHour .. "|cffffd100g|r/h)"
		end

		local LABEL_LOOTEDITEMVALUE = AceGUI:Create("Label")
		LABEL_LOOTEDITEMVALUE:SetText("Looted Item Value:")
		LABEL_LOOTEDITEMVALUE:SetWidth(labelWidth)
		LABEL_LOOTEDITEMVALUE:SetFont("Fonts\\FRIZQT__.TTF", 12)
		MAIN_UI:AddChild(LABEL_LOOTEDITEMVALUE)

		VALUE_LOOTEDITEMVALUE = AceGUI:Create("Label")
		VALUE_LOOTEDITEMVALUE:SetText(livValue)
		VALUE_LOOTEDITEMVALUE:SetWidth(valueWidth)
		VALUE_LOOTEDITEMVALUE:SetFont("Fonts\\FRIZQT__.TTF", 12)
		VALUE_LOOTEDITEMVALUE.label:SetJustifyH("RIGHT")
		MAIN_UI:AddChild(VALUE_LOOTEDITEMVALUE)
	end

	-- currency looted --
	-- format the total looted currency...
	if isShowCurrencyLootedEnabled() then
		mainUiHeight = mainUiHeight + rowHeight
		
		local formattedTotalLootedCurrency = LA:FormatTextMoney(totalLootedCurrency) or 0

		local LABEL_TOTALCURRENCY = AceGUI:Create("Label")
		LABEL_TOTALCURRENCY:SetText("Currency Looted:")
		LABEL_TOTALCURRENCY:SetWidth(labelWidth)
		LABEL_TOTALCURRENCY:SetFont("Fonts\\FRIZQT__.TTF", 12)
		MAIN_UI:AddChild(LABEL_TOTALCURRENCY)

		VALUE_TOTALCURRENCY = AceGUI:Create("Label")
		VALUE_TOTALCURRENCY:SetText(formattedTotalLootedCurrency)
		VALUE_TOTALCURRENCY:SetWidth(valueWidth)
		VALUE_TOTALCURRENCY:SetFont("Fonts\\FRIZQT__.TTF", 12)
		VALUE_TOTALCURRENCY.label:SetJustifyH("RIGHT")
		MAIN_UI:AddChild(VALUE_TOTALCURRENCY)
	end

	-- items looted (counter) --
	if isShowItemsLootedEnabled() then
		mainUiHeight = mainUiHeight + rowHeight
		
		local LABEL_LOOTEDITEMCOUNTER = AceGUI:Create("Label")
		LABEL_LOOTEDITEMCOUNTER:SetText("Items Looted ")
		LABEL_LOOTEDITEMCOUNTER:SetWidth(labelWidth)
		LABEL_LOOTEDITEMCOUNTER:SetFont("Fonts\\FRIZQT__.TTF", 12)
		MAIN_UI:AddChild(LABEL_LOOTEDITEMCOUNTER)

		VALUE_LOOTEDITEMCOUNTER = AceGUI:Create("Label")
		VALUE_LOOTEDITEMCOUNTER:SetText(lootedItemCounter)
		VALUE_LOOTEDITEMCOUNTER:SetWidth(valueWidth)
		VALUE_LOOTEDITEMCOUNTER:SetFont("Fonts\\FRIZQT__.TTF", 12)
		VALUE_LOOTEDITEMCOUNTER.label:SetJustifyH("RIGHT")
		MAIN_UI:AddChild(VALUE_LOOTEDITEMCOUNTER)
	end

	-- noteworthy items (counter) --
	if isShowNoteworthyItemsEnabled() then
		mainUiHeight = mainUiHeight + rowHeight
		
		local LABEL_NOTEWORTHYITEMCOUNTER = AceGUI:Create("Label")
		LABEL_NOTEWORTHYITEMCOUNTER:SetText("Noteworthy Items:")
		LABEL_NOTEWORTHYITEMCOUNTER:SetWidth(labelWidth)
		LABEL_NOTEWORTHYITEMCOUNTER:SetFont("Fonts\\FRIZQT__.TTF", 12)
		MAIN_UI:AddChild(LABEL_NOTEWORTHYITEMCOUNTER)

		VALUE_NOTEWORTHYITEMCOUNTER = AceGUI:Create("Label")
		VALUE_NOTEWORTHYITEMCOUNTER:SetText(noteworthyItemCounter)
		VALUE_NOTEWORTHYITEMCOUNTER:SetWidth(valueWidth)
		VALUE_NOTEWORTHYITEMCOUNTER:SetFont("Fonts\\FRIZQT__.TTF", 12)
		VALUE_NOTEWORTHYITEMCOUNTER.label:SetJustifyH("RIGHT")
		MAIN_UI:AddChild(VALUE_NOTEWORTHYITEMCOUNTER)
	end

	-- main ui height
	MAIN_UI:SetHeight(mainUiHeight)

	addSpacer(MAIN_UI)

	-- button sell trash --
	local BUTTON_SELLTRASH = AceGUI:Create("Button")
	BUTTON_SELLTRASH:SetAutoWidth(true)
	BUTTON_SELLTRASH:SetText("Sell Trash")
	BUTTON_SELLTRASH:SetCallback("OnClick", 
		function()
			onBtnSellTrashClick()
		end
	)
	MAIN_UI:AddChild(BUTTON_SELLTRASH)

	-- button trash grays --
	local BUTTON_DESTROYTRASH = AceGUI:Create("Button")
	BUTTON_DESTROYTRASH:SetAutoWidth(true)
	BUTTON_DESTROYTRASH:SetText("Destroy Trash")
	BUTTON_DESTROYTRASH:SetCallback("OnClick", function()
		onBtnDestroyTrashClick()
	end)
	MAIN_UI:AddChild(BUTTON_DESTROYTRASH)
end

function refreshSessionDuration( ... )
	if not isShowSessionDurationEnabled() then return end

	if isSessionRunning() then
		local delta =  time() - currentSession["start"]

		-- don't show seconds
		local noSeconds = false
		if delta > 3600 then
			noSeconds = true
		end

		--tooltip:AddDoubleLine("Session is running: ", SecondsToTime(delta, noSeconds, false))
		VALUE_SESSIONDURATION:SetText(SecondsToTime(delta, noSeconds, false))
	else
		--tooltip:AddLine("Session is not running")
		VALUE_SESSIONDURATION:SetText("not running")
	end
end


--[[------------------------------------------------------------------------
-- Event handler for button 'destroy trash'
--------------------------------------------------------------------------]]
function onBtnDestroyTrashClick()
	--Debug("  onBtnDestroyTrashClick")

	local destroyCounter = 0

	-- prepare blacklist (if activated for destroy trash)
	--[[
	local blacklistItems = ITEM_FILTER_BLACKLIST
	if isDestroyBlacklistedItems() then
		-- preload blacklist from TSM group
	 	blacklistItems = LA:GetGroupItems(getTsmGroup4Blacklist())
	end
	]]

	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)

			-- grey items
			if link and link:find("ff9d9d9d") then -- Poor = ff9d9d9d	
				PickupContainerItem(bag,slot)
				DeleteCursorItem()

				destroyCounter = destroyCounter + 1
			end

			-- blacklist
			--Debug("    isDestroyBlacklistedItems=" .. tostring(isDestroyBlacklistedItems()))
			if link and isDestroyBlacklistedItems() then
				local itemID = LA:GetItemID(link)
				--if LA:isItemInList(itemID, blacklistItems) then
				--Debug("    isItemBlacklisted=" .. tostring(isItemBlacklisted(itemID)))
				if isItemBlacklisted(itemID) then
					PickupContainerItem(bag, slot)
					DeleteCursorItem()

					destroyCounter = destroyCounter + 1
				end
			end
		end
	end

	if destroyCounter == 0 then
		LA:Print("There are currently no items to trash.")
	end

	if destroyCounter >= 1 then
		LA:Print("Destroyed " .. destroyCounter .. " item(s).")
	end
end


--[[-------------------------------------------------------------------------------------
-- Event handler for button 'sell trash'
---------------------------------------------------------------------------------------]]
function onBtnSellTrashClick()
	--Validate whether there is an NPC open and how many items sold
	local itemCounter = 0

	-- get items in group 'LootAppraiser`Trash' from TSM
	local trashItems
	if isSellTrashTsmGroupEnabled() == true then
	 	trashItems = LA:GetGroupItems(getSellTrashTsmGroup())
	end

	for n = 1, GetMerchantNumItems() do	
		local merchantItemName = select(1, GetMerchantItemInfo(n))
		itemCounter = itemCounter + 1
	end
	
	--If not vendor open (unable to count vendor items) alert to go to merchant
	if itemCounter == 0 then
		LA:Print("Travel to a vendor first to sell your items.")
		return
	end

	local itemsSold = 0
	for bag=0,4 do
		for slot=1, GetContainerNumSlots(bag) do
			-- first: we sell all grays
			local link = GetContainerItemLink(bag, slot)
			if link and link:find("ff9d9d9d") then			--Poor = ff9d9d9d
				UseContainerItem(bag, slot)
				itemsSold = itemsSold + 1
			end

			--second: sell items in TSM group
			if isSellTrashTsmGroupEnabled() == true then
				local id = GetContainerItemID(bag, slot)
				if id and LA:isItemInList(id, trashItems) then
					Debug("  id=" .. id .. ", found=" .. tostring(trashItems["i:" .. id]) .. ", link=" .. link)
					UseContainerItem(bag, slot)
					itemsSold = itemsSold + 1
				end
			end
		end
	end

	if itemsSold == 0 then
		LA:Print("No items sold.")
	else
		LA:Print(tostring(itemsSold) .. " item(s) sold") --for " .. LA:FormatTextMoney(moneyEarned))
	end
end


--[[-------------------------------------------------------------------------------------
-- calculate looted item value / hour and refresh UI with the new value
---------------------------------------------------------------------------------------]]
function refreshLivPerHour()
	if not isShowLootedItemValuePerHourEnabled() then return end

	-- calc lootedItemValuePerHour
	local currentTime = time()

	local delta = currentTime - currentSession["start"]

	local factor = 3600
	if delta < factor then
		factor = delta
	end

	local livPerHour = (totalItemValue/delta*factor)
	local livGoldPerHour = floor(livPerHour/10000)
	local formattedTotalItemValue = LA:FormatTextMoney(totalItemValue) or 0

	VALUE_LOOTEDITEMVALUE:SetText(formattedTotalItemValue .. " (" .. tostring(livGoldPerHour) .. "|cffffd100g|r/h)")

	-- save to session (for statistics)
	if totalItemValue > 0 then
		currentSession["liv"] = totalItemValue
		currentSession["end"] = currentTime
	end
end

--[[-------------------------------------------------------------------------------------
-- increase the noteworthy item counter
---------------------------------------------------------------------------------------]]
function incNoteworthyItemCounter(quantity)
	noteworthyItemCounter = noteworthyItemCounter + quantity

	-- show the new value in main ui (if shown)
	if MAIN_UI then
		if isShowNoteworthyItemsEnabled() then
			-- add to main ui
			VALUE_NOTEWORTHYITEMCOUNTER:SetText(noteworthyItemCounter)
		end
	end
end

--[[-------------------------------------------------------------------------------------
-- increase the looted item counter
---------------------------------------------------------------------------------------]]
function incLootedItemCounter(quantity)
	lootedItemCounter = lootedItemCounter + quantity

	-- show the new value in main ui (if shown)
	if MAIN_UI then
		if isShowItemsLootedEnabled() then
			-- add to main ui
			VALUE_LOOTEDITEMCOUNTER:SetText(lootedItemCounter)
		end
	end
end

--[[-------------------------------------------------------------------------------------
-- add item value to looted item value and refresh ui
---------------------------------------------------------------------------------------]]
function addItemValue2LootedItemValue(itemValue)
	totalItemValue = totalItemValue + itemValue

	-- show the new value in main ui (if shown)
	if MAIN_UI then
		if isShowLootedItemValueEnabled() then
			local livValue = LA:FormatTextMoney(totalItemValue) or 0
			if isShowLootedItemValuePerHourEnabled() then
				livValue = livValue .. " (" .. lootedItemValuePerHour .. "|cffffd100g|r/h)"
			end

			-- add to main ui
			VALUE_LOOTEDITEMVALUE:SetText(livValue)
		end
	end

	-- save current session (for statistics)
	if totalItemValue > 0 then
		currentSession["liv"] = totalItemValue
		currentSession["end"] = time() -- fallback if we found no way to identify session end
	end
end

--[[-------------------------------------------------------------------------------------
-- add a given item to the top of the loot colletced list
---------------------------------------------------------------------------------------]]
local lootCollectedLastEntry = nil  -- remember last element from loot collected list to add elemnts before this (on top of the list)
function addItem2LootCollectedList(itemID, link, quantity, marketValue, noteworthyItemFound)
	--Debug("addItem2LootCollectedList(itemID=" .. itemID .. ", link=" .. tostring(link) .. ", quantity=" .. quantity .. ")")

	-- prepare text
	local formattedItemValue = LA:FormatTextMoney(marketValue) or 0
	local preparedText = " " .. link .. " x" .. quantity .. ": " .. formattedItemValue

	--[[
	if noteworthyItemFound then
		local context = format("LA_NOTEWORTH_%s_%s_%s", itemID, quantity, marketValue)
		preparedText = preparedText .. Social_GetShareItemLink(itemID, context, true)
	end
	]]
	
	-- item / link
	local LABEL = AceGUI:Create("InteractiveLabel")
	LABEL.frame:Hide()
	LABEL:SetText(preparedText)
	LABEL:SetWidth(350)
	--LABEL:SetFont("Fonts\\FRIZQT__.TTF", 12)
	LABEL:SetCallback("OnEnter", 
		function()
			GameTooltip:SetOwner(MAIN_UI.frame, "ANCHOR_CURSOR")  -- LootAppraiser.GUI is the AceGUI-Frame but we need the real frame
			GameTooltip:SetHyperlink(link)
			GameTooltip:Show()
		end
	)
	LABEL:SetCallback("OnLeave", 
		function()
			GameTooltip:Hide()
		end
	)
	
	if lootCollectedLastEntry then
		GUI_LOOTCOLLECTED:AddChild(LABEL, lootCollectedLastEntry)
	else
		GUI_LOOTCOLLECTED:AddChild(LABEL)
	end
	
	-- rember the created entry to add the next entry before this -> reverse list with newest entry on top
	lootCollectedLastEntry = LABEL
end


--[[-------------------------------------------------------------------------------------
-- refresh the zone informations
---------------------------------------------------------------------------------------]]
function refreshZoneInfo()
	if not isShowZoneInfoEnabled() then return end

	local zoneInfo = ""

	-- current zone
	local currentMapID = GetCurrentMapAreaID()
	if currentMapID ~= nil then
		--zoneInfo = zoneInfo .. GetMapNameByID(currentMapID)
	end

	-- session zone (if a session is running)
	if currentSession ~= nil and currentSession["mapID"] ~= nil then
		local sessionMapID = currentSession["mapID"]

		if sessionMapID ~= nil then
			local zoneName = GetMapNameByID(sessionMapID)

			--zoneInfo = zoneInfo .. " (" .. zoneName .. ")"
			zoneInfo = zoneInfo ..  zoneName
		end
	end

	VALUE_ZONE:SetText(zoneInfo)
end

--[[-------------------------------------------------------------------------------------
-- refresh the status bar with the current settings
---------------------------------------------------------------------------------------]]
function LA:refreshStatusText()
	if MAIN_UI ~= nil then
		-- prepare status text
		local preparedText = "Quality filter: " .. LA.QUALITY_FILTER[tostring(getQualityFilter())]
		preparedText = preparedText .. " - GAT: |cffffffff" .. getGoldAlertThreshold() .. "|cffffd100g|r"
		
		MAIN_UI:SetStatusText(preparedText)
	end
end

--[[-------------------------------------------------------------------------------------
-- helper methods
---------------------------------------------------------------------------------------]]

-- add a spacer 
function addSpacer(frame)
	local SPACER = AceGUI:Create("Label")
	SPACER:SetText("   ")
	SPACER:SetWidth(350)
	--SPACER:SetFont("Fonts\\FRIZQT__.TTF", 12)
	frame:AddChild(SPACER)
end

--[[------------------------------------------------------------------------
-- checks if a item is blacklisted
--   check depends on the blacklist options (see config)
--------------------------------------------------------------------------]]
function isItemBlacklisted(itemID)
	--Debug("isItemBlacklisted(): itemID=" .. itemID)
	--Debug("  isBlacklistTsmGroupEnabled()=" .. tostring(isBlacklistTsmGroupEnabled()))
	if not isBlacklistTsmGroupEnabled() then
		-- only use static list
		return ITEM_FILTER_BLACKLIST[tostring(itemID)]
	end

	-- use TSM group
	-- get items in group 'LootAppraiser`Blacklist' from TSM
	--Debug("  getBlacklistTsmGroup()=" .. getBlacklistTsmGroup())
	local blacklistItems = LA:GetGroupItems(getBlacklistTsmGroup())

	local result = LA:isItemInList(itemID, blacklistItems)
	--Debug("  isItemInList=" .. tostring(result))
	return result
end

function isBlacklistTsmGroupEnabled()
	if LA.db.profile.blacklist.tsmGroupEnabled == nil then
		LA.db.profile.blacklist.tsmGroupEnabled = dbDefaults.profile.blacklist.tsmGroupEnabled
	end

	return LA.db.profile.blacklist.tsmGroupEnabled
end

function isDestroyBlacklistedItems()
	--if isBlacklistTsmGroupEnabled() and LA.db.profile.addBlacklistedItems2DestroyTrash then
	if LA.db.profile.blacklist.addBlacklistedItems2DestroyTrash then
		return true
	end
	return false
end

function getBlacklistTsmGroup()
	if LA.db.profile.blacklist.tsmGroup == nil then
		LA.db.profile.blacklist.tsmGroup = dbDefaults.profile.blacklist.tsmGroup
	end

	return LA.db.profile.blacklist.tsmGroup
end

function getGoldAlertThreshold()
	if LA.db.profile.goldAlertThreshold == nil then
		LA.db.profile.goldAlertThreshold = dbDefaults.profile.goldAlertThreshold
	end

	return tonumber(LA.db.profile.goldAlertThreshold)
end

function getQualityFilter()
	if LA.db.profile.qualityFilter == nil then
		LA.db.profile.qualityFilter = dbDefaults.profile.qualityFilter
	end

	return tonumber(LA.db.profile.qualityFilter)
end

function getIgnoreRandomEnchants()
	if LA.db.profile.ignoreRandomEnchants == nil then
		LA.db.profile.ignoreRandomEnchants = dbDefaults.profile.ignoreRandomEnchants
	end

	return LA.db.profile.ignoreRandomEnchants
end

function LA:getSessions()
	if LA.db.global.sessions == nil then
		LA.db.global.sessions = {}
	end

	return LA.db.global.sessions
end

function getPriceSource()
	if LA.db.profile.priceSource == nil then
		LA.db.profile.priceSource = dbDefaults.profile.priceSource
	end

	return LA.db.profile.priceSource
end

function isToastsEnabled()
	if LA.db.profile.notification.enableToasts == nil then
		LA.db.profile.notification.enableToasts = dbDefaults.profile.enableToasts
	end

	return LA.db.profile.notification.enableToasts
end

function isSessionRunning()
	return sessionIsRunning
end

function isPlaySoundEnabled()
	if LA.db.profile.notification.playSoundEnabled == nil then
		LA.db.profile.notification.playSoundEnabled = dbDefaults.profile.notification.playSoundEnabled
	end

	return LA.db.profile.notification.playSoundEnabled
end

function isSellTrashTsmGroupEnabled()
	if LA.db.profile.sellTrash.tsmGroupEnabled == nil then
		LA.db.profile.sellTrash.tsmGroupEnabled = dbDefaults.profile.sellTrash.tsmGroupEnabled
	end

	return LA.db.profile.sellTrash.tsmGroupEnabled
end

function getSellTrashTsmGroup()
	if LA.db.profile.sellTrash.tsmGroup == nil then
		LA.db.profile.sellTrash.tsmGroup = dbDefaults.profile.sellTrash.tsmGroup
	end

	return LA.db.profile.sellTrash.tsmGroup
end

function isShowZoneInfoEnabled()
	if LA.db.profile.general.display.showZoneInfo == nil then
		LA.db.profile.general.display.showZoneInfo = dbDefaults.profile.general.display.showZoneInfo
	end

	return LA.db.profile.general.display.showZoneInfo
end

function isShowSessionDurationEnabled()
	if LA.db.profile.general.display.showSessionDuration == nil then
		LA.db.profile.general.display.showSessionDuration = dbDefaults.profile.general.display.showSessionDuration
	end

	return LA.db.profile.general.display.showSessionDuration
end

function isShowLootedItemValueEnabled()
	if LA.db.profile.general.display.showLootedItemValue == nil then
		LA.db.profile.general.display.showLootedItemValue = dbDefaults.profile.general.display.showLootedItemValue
	end

	return LA.db.profile.general.display.showLootedItemValue
end

function isShowLootedItemValuePerHourEnabled()
	if LA.db.profile.general.display.showLootedItemValuePerHour == nil then
		LA.db.profile.general.display.showLootedItemValuePerHour = dbDefaults.profile.general.display.showLootedItemValuePerHour
	end

	return LA.db.profile.general.display.showLootedItemValuePerHour
end

function isShowCurrencyLootedEnabled()
	if LA.db.profile.general.display.showCurrencyLooted == nil then
		LA.db.profile.general.display.showCurrencyLooted = dbDefaults.profile.general.display.showCurrencyLooted
	end

	return LA.db.profile.general.display.showCurrencyLooted
end

function isShowItemsLootedEnabled()
	if LA.db.profile.general.display.showItemsLooted == nil then
		LA.db.profile.general.display.showItemsLooted = dbDefaults.profile.general.display.showItemsLooted
	end

	return LA.db.profile.general.display.showItemsLooted
end

function isShowNoteworthyItemsEnabled()
	if LA.db.profile.general.display.showNoteworthyItems == nil then
		LA.db.profile.general.display.showNoteworthyItems = dbDefaults.profile.general.display.showNoteworthyItems
	end

	return LA.db.profile.general.display.showNoteworthyItems
end

--[[-------------------------------------------------------------------------------------
-- parse currency text from loot window and covert the result to copper
-- e.g. 2 silve, 2 copper
-- result: 202 copper
---------------------------------------------------------------------------------------]]
function getLootedCopperFromText(lootedCurrencyAsText)
	local digits = {}
	local digitsCounter = 0;
	lootedCurrencyAsText:gsub("%d+", 
		function(i)
			table.insert(digits, i)
			digitsCounter = digitsCounter + 1
		end
	)
	local copper = 0
	if digitsCounter == 3 then
		-- gold + silber + copper
		copper = (digits[1]*10000)+(digits[2]*100)+(digits[3])
	elseif digitsCounter == 2 then
		-- silber + copper
		copper = (digits[1]*100)+(digits[2])
	else
		-- copper
		copper = digits[1]
	end
	
	return copper
end

function Debug(msg)
	if LA.DEBUG then
		LA:Print(tostring(msg))
	end
end

function string.startsWith(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end