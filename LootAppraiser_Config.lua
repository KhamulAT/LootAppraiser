-- LootAppraiser_Config.lua --
local LootAppraiser, LA = ...;

local Config = LA:NewModule("Config", "AceEvent-3.0", "AceConsole-3.0")

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")

local options = {
	type = "group",
	args = {
		general = {
			type = "group", 
			name = LootAppraiser, 
			get = function(info) 
				return LA.db.profile[info[#info]] 
			end,
			set = function(info, value) 
				LA.db.profile[info[#info]] = value;
				LA:refreshStatusText()
			end,
			childGroups = "tab",
			args = {
				generalOptionsGrp = {
					type = "group",
					order = 25,
					name = "General",
					get = function(info) 
						return LA.db.profile.general[info[#info]] 
					end,
					set = function(info, value) 
						LA.db.profile.general[info[#info]] = value;
					end,
					args = {
						qualityFilter = {
							type = "select",
							order = 20,
							name = "Quality Filter",
							desc = "Items below the selected quality will not show in the loot collected list",
							values = LA.QUALITY_FILTER,
							set = function(info, value) 
								local oldValue = LA.db.profile.general[info[#info]]
								if oldValue ~= value then
									LA:Print("Quality Filter set to: " .. LA.QUALITY_FILTER[value] .. " and above.")
								end
								LA.db.profile.general[info[#info]] = value;
								LA:refreshStatusText()
							end,
						},
						spacer = {
							type = "description", 
							order = 25, 
							name = " ", 
							width = "half", 
						},
						goldAlertThreshold = {
							type = "input",
							order = 30,
							name = "Gold Alert Threshold (GAT)",
							desc = "Threshold for gold alert",
							set = function(info, value) 
								local oldValue = LA.db.profile.general[info[#info]]
								if oldValue ~= value then
									LA:Print("Gold alert threshold set: " .. value .. " gold or higher.")
								end
								LA.db.profile.general[info[#info]] = value;
								LA:refreshStatusText()
							end,
						},
						ignoreRandomEnchants = {
							type = "toggle",
							order = 40,
							name = "Ignore random enchants on items",
							desc = "Ignore random enchants on items (like ...of the Bear) and show only the base item",
							width = "double",
							set = function(info, value) 
								local oldValue = LA.db.profile.general[info[#info]]
								if oldValue ~= value then
									LA:Print("Ignore random enchants set: " .. tostring(value) .. ".")
								end
								LA.db.profile.general[info[#info]] = value;
							end,
						},
						surpressSessionStartDialog = {
							type = "toggle",
							order = 50,
							name = "Suppress 'Start Session' dialogue during the first looting.",
							desc = "Attention! If the dialog is suppressed, the session must be started by hand (left-click on the minimap icon)",
							width = "double",
							set = function(info, value) 
								local oldValue = LA.db.profile.general[info[#info]]
								if oldValue ~= value then
									LA:Print("Suppress 'Start Session' dialogue: " .. tostring(value) .. ".")
								end
								LA.db.profile.general[info[#info]] = value;
							end,
						},
					},
				},
				priceSourceGrp = {
					type = "group",
					order = 50,
					name = "Price Source",
					get = function(info) 
						return LA.db.profile.pricesource[info[#info]] 
					end,
					set = function(info, value) 
						LA.db.profile.pricesource[info[#info]] = value;
					end,
					args = {
						source = {
							type = "select",
							order = 20,
							name = "Price Source",
							desc = "TSM predefined price sources for item value calculation.",
							values = LA.PRICE_SOURCE,
							width = "double",
							set = function(info, value) 
								local oldValue = LA.db.profile.pricesource[info[#info]]
								if oldValue ~= value then
									LA:Print("Price source changed to: " .. value)
								end
								LA.db.profile.pricesource[info[#info]] = value;
								LA:refreshStatusText()
							end,
						},
						customPriceSource = {
							type = "input",
							order = 30,
							name = "Custom Price Source",
							desc = "TSM Custom Price Source. See TSM documentation for detailed description.",
							width = "full",
							disabled = function()
								return not (LA.db.profile.pricesource.source == "Custom")
							end,
							set = function(info, value) 
								LA:Print("Custom price source changed to: " .. value)
								LA.db.profile.pricesource[info[#info]] = value;
							end,
							validate = function(info, value)
								local isValidPriceSource = LA:ParseCustomPrice(value)
								if not isValidPriceSource then
									-- error message
									DEFAULT_CHAT_FRAME:AddMessage("Invalid custom price source. See TSM documentation for detailed description.")
									return false
								end
								return true
							end,
						},
					},
				},
				sellTrashGrp = {
					type = "group",
					order = 60,
					name = "Sell Trash",
					get = function(info) 
						return LA.db.profile.sellTrash[info[#info]] 
					end,
					set = function(info, value) 
						LA.db.profile.sellTrash[info[#info]] = value;
					end,
					args = {
						description = {
							type = "description", 
							order = 5, 
							name = "The button sell trash always sells gray items. Here you can add a TSM group to the sell trash function and all items in this group will also sold. Be careful. If your TSM group containts items with value and you click sell trash... all items are gone with the wind... you be warned. Note: TSM uses ` as group seperator.\n", 
							width = "full", 
						}, 
						tsmGroupEnabled = {
							type = "toggle",
							order = 10,
							name = " Sell trash via TSM group",
							desc = "Use a TSM group to define additional none gray items to sell at the vendor with the sell trash button",
							--width = "double",
							set = function(info, value) 
								local oldValue = LA.db.profile.sellTrash[info[#info]]
								if oldValue ~= value then
									LA:Print("Sell trash via TSM group set: " .. tostring(value) .. ".")
								end
								LA.db.profile.sellTrash[info[#info]] = value;
							end,
						},
						tsmGroup = {
							type = "input",
							order = 20,
							name = "TSM Group",
							desc = "The TSM Group with all the none gray items to sell at the vendor.",
							width = "double",
							disabled = function()
								return not (LA.db.profile.sellTrash.tsmGroupEnabled == true)
							end,
							set = function(info, value) 
								LA:Print("Sell trash TSM group set to: " .. value)
								LA.db.profile.sellTrash[info[#info]] = value;
							end,
							-- TODO validation
							validate = function(info, value)
								-- validate the tsn group
								if value == nil or value == "" then
									-- error message
									DEFAULT_CHAT_FRAME:AddMessage("Invalid TSM group.")
									return false
								end
								return true
							end,
						},
					},
				},
				blacklist = {
					type = "group",
					order = 70,
					name = "Blacklist",
					get = function(info) 
						return LA.db.profile.blacklist[info[#info]] 
					end,
					set = function(info, value) 
						LA.db.profile.blacklist[info[#info]] = value;
					end,
					args = {
						description = {
							type = "description",
							order = 10,
							name = "The black list is intended for all worthless items. They can not be sold to the vendor and the auction value is only theoretical (like the idols and scarabs from AQ20). Therefore, these objects are ignored in the calculation of the looted itemvalue. Note: TSM uses ` as group seperator.",
							width = "full"
						},
						addBlacklistedItems2DestroyTrash = {
							type = "toggle",
							order = 15,
							name = " Add blacklisted items to the destroy trash button.",
							desc = "Adds all blacklisted items from the TSM group to the destroyabel items list.",
							width = "full",
							--[[
							disabled = function()
								return not (LA.db.profile.blacklist.tsmGroupEnabled == true)
							end,
							]]
							set = function(info, value) 
								local oldValue = LA.db.profile[info[#info]]
								if oldValue ~= value then
									LA:Print("Add blacklisted items to destroy trash set: " .. tostring(value) .. ".")
								end
								LA.db.profile.blacklist[info[#info]] = value;
							end,
						},
						tsmGroupEnabled = {
							type = "toggle",
							order = 20,
							name = " Blacklist via TSM group",
							desc = "Use a TSM group to define blacklisted items. If deactivated LootAppraiser uses the old unmaintained list.",
							--width = "double",
							set = function(info, value) 
								local oldValue = LA.db.profile.blacklist[info[#info]]
								if oldValue ~= value then
									LA:Print("Blacklist items via TSM group set: " .. tostring(value) .. ".")
								end
								LA.db.profile.blacklist[info[#info]] = value;
							end,
						},
						tsmGroup = {
							type = "input",
							order = 30,
							name = "TSM Group",
							desc = "The TSM Group with all the blacklistes items.",
							width = "double",
							disabled = function()
								return not (LA.db.profile.blacklist.tsmGroupEnabled == true)
							end,
							set = function(info, value) 
								LA:Print("Blacklisted items TSM group set to: " .. value)
								LA.db.profile.blacklist[info[#info]] = value;
							end,
							-- TODO validation
							validate = function(info, value)
								-- validate the tsn group
								if value == nil or value == "" then
									-- error message
									DEFAULT_CHAT_FRAME:AddMessage("Invalid TSM group.")
									return false
								end
								return true
							end,
						},



					},
				},
				notificationOptionsGrp = {
					type = "group",
					order = 75,
					name = "Notifications",
					get = function(info) 
						return LA.db.profile.notification[info[#info]] 
					end,
					set = function(info, value) 
						LA.db.profile.notification[info[#info]] = value;
					end,
					args = {
						noteworthyItemOutputHeader = {
							order = 100,
							type = "header",
							name = "Noteworthy Item Output Channel",
							--cmdHidden = true,
						},
						notificationLibSink = LA:GetSinkAce3OptionsDataTable(),
						enableToasts = {
							type = "toggle",
							order = 300,
							name = "Enable Toasts",
							desc = "Enable Toasts",
							width = "double",
							set = function(info, value) 
								local oldValue = LA.db.profile.notification[info[#info]]
								if oldValue ~= value then
									LA:Print("Enable Toasts set: " .. tostring(value) .. ".")
								end
								LA.db.profile.notification[info[#info]] = value;
							end,
						},
						noteworthyItemSoundHeader = {
							order = 400,
							type = "header",
							name = "Noteworthy Item Sound",
							--cmdHidden = true,
						},
						playSoundEnabled = {
							order = 425,
							type = "toggle",
							name = "Play Sound",
							desc = "Play Sound",
						},
						soundName = {
							order = 450,
							type = "select",
							name = "Sound",
							desc = "Sound",
							width = "double",
							dialogControl = "LSM30_Sound",
							values = LSM:HashTable("sound"),							
							disabled = function() return not LA.db.profile.notification.playSoundEnabled end,
						},
					},
				},
				displayOptions = {
					type = "group",
					order = 90,
					name = "Display",
					hidden = true,
					--inline = true,
					get = function(info) 
						return LA.db.profile.display[info[#info]] 
					end,
					set = function(info, value) 
						LA.db.profile.display[info[#info]] = value
						--LA:refreshMainWindow()
					end,
					args = {
						description = {
							type = "description", 
							order = 1, 
							name = "Attention! All changes will only take effect after a reload.\n", 
							width = "full", 
						}, 
						lootedItemListRowCount = {
							type = "range",
							order = 5, 
							name = "Looted Item List: number of rows",
							desc = "Number of rows in the looted item list",
							min = 0,
							max = 10,
							step = 1,
							width = "double",
						},
						showZoneInfo = {
							type = "toggle",
							order = 10,
							name = "Show Zone Information",
							desc = "Show Zone Information",
							width = "full",
						},
						showSessionDuration = {
							type = "toggle",
							order = 20,
							name = "Show 'Session Duration'",
							desc = "Show 'Session Duration'",
							width = "full",
						},
						showLootedItemValue = {
							type = "toggle",
							order = 30,
							name = "Show 'Looted Item Value'",
							desc = "Show 'Looted Item Value'",
							width = "full",
						},
						showLootedItemValuePerHour = {
							type = "toggle",
							order = 40,
							name = "Show 'Looted Item Value' Per Hour",
							desc = "Show 'Looted Item Value' Per Hour (in parentes behind the Looted Item Value)",
							width = "full",
						},
						showCurrencyLooted = {
							type = "toggle",
							order = 50,
							name = "Show 'Currency Looted'",
							desc = "Show 'Currency Looted'",
							width = "full",
						},
						showItemsLooted = {
							type = "toggle",
							order = 60,
							name = "Show 'Items Looted'",
							desc = "Show 'Items Looted'",
							width = "full",
						},
						showNoteworthyItems = {
							type = "toggle",
							order = 70,
							name = "Show 'Noteworthy Items'",
							desc = "Show 'Noteworthy Items'",
							width = "full",
						},
						reloadUi = {
							type = "execute",
							order = 100,
							name = "Reload UI",
							func = function()
								ReloadUI()
							end
						},
					},
					plugins = {},
				},
				aboutGroup = {
					type = "group", 
					order = 100, 
					name = "About",
					args = {
						generalText = {
							type = "description", 
							order = 10, 
							name = "Thank you for downloading and installing LootAppraiser!\n\nUsage:  Left-Click on the mini-map icon to load the Main user interface.  If you want to load them manually type: /lah for help details.\n\nFAQ:\nWhy is pricing reporting incorrectly or only reporting vendor pricing?\nLootAppraiser leverages pricing through TradeSkillMaster's API. Ensure you have ALL the TradeSkillMaster modules installed by going to TradeSkillMaster.com.  This includes installing the TSM Desktop Application which will keep your pricing current. LootAppraiser does nothing with pricing algoritms and only reports pricing that it is aware of so if your pricing is incorrect, check your addon configurations for pricing.\n\nDoes LootAppraiser work with Auctioneer or Auctionator?\nNo. LootAppraiser specifically leverages TSM API functions for pricing.\n\nWhat do I do if I have a suggestion or want to report a bug?\nAny bug, defect, or enhancement requests can be posted at curse forge: http://wow.curseforge.com/addons/lootappraiser/tickets/ \n\nHappy gaming and Happy earning!", 
							width = "full", 
						}, 
					}, 
				},
			}, 
		},	
		statistic = {
			type = "group", 
			name = LootAppraiser .. " Statistic", 
			get = function(info) 
				return LA.db.profile[info[#info]] 
			end,
			set = function(info, value) 
				LA.db.profile[info[#info]] = value; 
			end,
			childGroups = "select",
			inline = true,
			args = {},
		},
	}, 
}

--[[-------------------------------------------------------------------------------------
-- AceAddon-3.0 - module standard methods
---------------------------------------------------------------------------------------]]
local statisticFrame

function Config:OnInitialize()
	Debug("Config:OnInitialize()")

	-- register sounds
	LSM:Register("sound", "Auction Window Open", "Sound/Interface/AuctionWindowOpen.ogg")
	LSM:Register("sound", "Auction Window Close", "Sound/Interface/AuctionWindowClose.ogg")
	LSM:Register("sound", "Auto Quest Complete", "Sound/Interface/AutoQuestComplete.ogg")
	LSM:Register("sound", "Level Up", "Sound/Interface/LevelUp.ogg")
	LSM:Register("sound", "Player Invite", "Sound/Interface/iPlayerInviteA.ogg")
	LSM:Register("sound", "Raid Warning", "Sound/Interface/RaidWarning.ogg")
	LSM:Register("sound", "Ready Check", "Sound/Interface/ReadyCheck.ogg")

	-- general LootAppraiser configuration
	AceConfigRegistry:RegisterOptionsTable(LootAppraiser, options.args.general)
	AceConfigRegistry:RegisterOptionsTable(LootAppraiser .. " Statistic", options.args.statistic, LootAppraiser)

	AceConfigDialog:AddToBlizOptions(LootAppraiser)
	statisticFrame = AceConfigDialog:AddToBlizOptions(LootAppraiser .. " Statistic", "Statistic", LootAppraiser)

	prepareStatisticGroups() -- prepare statistic groups

	--testFrame = AceConfigDialog:AddToBlizOptions(LootAppraiser .. " Test", "Test", LootAppraiser) -- test

	--test()

	-- Fix sink config options
	options.args.general.args.notificationOptionsGrp.args.notificationLibSink.order = 200
	options.args.general.args.notificationOptionsGrp.args.notificationLibSink.inline = true
	options.args.general.args.notificationOptionsGrp.args.notificationLibSink.name = ""
end


function prepareStatisticGroups()
	options.args.statistic.args = getStatisticGroups()
end


local groups = {}
function test()
	local appName = LootAppraiser .. " Statistic"
	local name = "Statistic 2"
	local parent = LootAppraiser

	-- blizz options group
	local blizzOptionsGrp = AceGUI:Create("BlizOptionsGroup")
	blizzOptionsGrp:SetName(name or appName, parent)
	blizzOptionsGrp:SetTitle(name or appName)
	blizzOptionsGrp:SetUserData("appName", appName)
	blizzOptionsGrp:SetLayout("fill")
	InterfaceOptions_AddCategory(blizzOptionsGrp.frame)

	-- scroll frame
	--[[
	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("flow")
	blizzOptionsGrp:AddChild(scrollFrame)
	]]

	-- dropdown group
	local select = AceGUI:Create("DropdownGroup")
	select:SetLayout("fill")
	select:SetTitle("")

	-- prepare select entries
	local grouplist = {}
	local key

	local sessions = LA:getSessions()
	for _, session in ipairs(sessions) do
		local sessionEnd = session["end"]

		if sessionEnd ~= nil then
			local sessionMapID = session["mapID"]
			local sessionStart = session["start"]
			local sessionEnd = session["end"]
			local liv = session["liv"]

			-- group name
			local grpID
			local groupName
			if sessionMapID ~= nil then
				grpID = "grp" .. tostring(sessionMapID)
				groupName = GetMapNameByID(sessionMapID)
			else
				grpID = "grgUndefined"
				groupName = "-Undefined-"
			end

			-- get group or create new if no group exists
			local grp = groups[grpID]
			if grp == nil then
				--grp = prepareMapGroup(groupName, #groups+1)
				grp = AceGUI:Create("ScrollFrame")
				grp:SetLayout("flow")

				groups[grpID] = grp
			end

			--local scrollFrame = AceGUI:Create("ScrollFrame")
			--scrollFrame:SetLayout("flow")

			--local container = AceGUI:Create("InlineGroup")
			--container:SetTitle(groupName)
			--container:SetLayout("fill")
			--scrollFrame:AddChild(container)

			-- row group (with name-server - datetime)
			local t = date("*t", sessionStart)
			local player = session["player"] or ""
			local rowTitle = player .. " - " .. date("%m/%d/%Y %I:%M %p", session["start"])

			local rowGrp = AceGUI:Create("InlineGroup")
			rowGrp:SetTitle(rowTitle)
			rowGrp:SetLayout("flow")
			rowGrp:SetFullWidth(true)
			grp:AddChild(rowGrp)

			-- duration
			local sessionDuration = sessionEnd - sessionStart

			local labelDuration = AceGUI:Create("Label")
			labelDuration:SetText(SecondsToTime(sessionDuration))
			labelDuration:SetWidth(170)
			labelDuration:SetFontObject(GameFontHighlightSmall)
			rowGrp:AddChild(labelDuration)
			
			-- looted item value
			local formattedLiv = LA:FormatTextMoney(liv) or 0

			local labelLiv = AceGUI:Create("Label")
			labelLiv:SetText(formattedLiv)
			labelLiv:SetWidth(170)
			labelLiv:SetFontObject(GameFontHighlightSmall)
			labelLiv.label:SetJustifyH("RIGHT")
			rowGrp:AddChild(labelLiv)

			-- liv / hour
			local factor = 3600
			if sessionDuration < factor then
				factor = sessionDuration
			end

			local livGold = floor(liv/10000)
			local livGoldPerHour = floor(livGold/sessionDuration*factor)

			local labelLivPerHour = AceGUI:Create("Label")
			labelLivPerHour:SetText(livGoldPerHour .. "|cffffd100g|r/h")
			labelLivPerHour:SetWidth(170)
			labelLivPerHour:SetFontObject(GameFontHighlightSmall)
			labelLivPerHour.label:SetJustifyH("RIGHT")
			rowGrp:AddChild(labelLivPerHour)


			--local label = AceGUI:Create("Label")
			--label:SetText("Label " .. tostring(i))
			--label:SetFontObject(GameFontHighlightSmall)
			--label:SetFullWidth(true)
			--container:AddChild(label)

			--groups[grpID] = scrollFrame

			grouplist[grpID] = groupName
			if not key then
				key = grpID
			end
		end
	end
	
	select:SetGroupList(grouplist)
	select:SetCallback("OnGroupSelected", onGroupSelected)
	--select:SetGroup(key)
	blizzOptionsGrp:AddChild(select)

end


function onGroupSelected(widget, event, value)
	Debug("    value=" .. value)

	widget:ReleaseChildren()

	local group = groups[value]
	if group ~= nil then
		widget:AddChild(groups[value])
	end
end


function Config:OnEnable()

end


function Config:OnDisable()

end

--[[
function onShowStatistics(event, ... )
	Debug("  onShowStatistics")

	local childs = statisticFrame:GetChildren()
	Debug("  #" .. tostring(statisticFrame:GetNumChildren()))

	for i, child in ipairs(childs) do
	  Debug("    " .. type(child))
	end
end
]]

function getOrCreateZoneGrp(groups, session, order)
	-- group name and ID
	local sessionMapID = session["mapID"]

	local grpID
	local groupName
	if sessionMapID ~= nil then
		grpID = "zone" .. tostring(sessionMapID)
		groupName = GetMapNameByID(sessionMapID)
	else
		grpID = "grgUndefined"
		groupName = "-Undefined-"
	end

	local zoneGrp = groups[grpID]
	if zoneGrp == nil then
		zoneGrp = {
			type = "group",
			--order = order,
			name = groupName,
			args = {
				-- group by dropdown
				groupBy = {
					type = "select",
					order = order,
					name = "Group by",
					desc = "TBD",
					values = SESSIONDATA_GROUPBY,
					inline = true,
					get = function(info) 
						if LA.db.profile.sessionData[info[#info]] == nil then
							LA.db.profile.sessionData[info[#info]] = "datetime"
						end
						return LA.db.profile.sessionData[info[#info]] 
					end,
					set = function(info, value) 
						LA.db.profile.sessionData[info[#info]] = value

						options.args.statistic.args = getStatisticGroups()
					end,
				},
				-- empty line
				newline = {
					type = "description",
					order = order+1,
					name = " ",
					width = "full",
				},
			},
			plugins = {
			},
		}

		groups[grpID] = zoneGrp
	end

	return zoneGrp
end


SESSIONDATA_GROUPBY = { -- little hack to sort them in the menu
	["datetime"] = "Date", 
	--["char"] = "Character", 
	--["duration"] = "Duration", 
	["liv"] = "Looted Item Value", 
	["livPerHour"] = "LIV per hour", 
	--["noteworthyItemsCount"] = "Noteworthy Items"
};


function createSessionGrp(session, order)
	-- get group by information
	local groupBy = LA.db.profile.sessionData.groupBy
	if groupBy == nil then
		groupBy = "datetime"
	end

	-- prepare name
	local name
	if groupBy == "datetime" then
		name = date("%m/%d/%Y %I:%M %p", session["start"])
	elseif groupBy == "liv" then
		local liv = session["liv"]

		name = LA:FormatTextMoney(liv) or 0
	elseif groupBy == "livPerHour" then
		local liv = session["liv"] or 0
		local sessionStart = session["start"]
		local sessionEnd = session["end"]
		local sessionDuration = sessionEnd - sessionStart

		local factor = 3600
		if sessionDuration < factor then
			factor = sessionDuration
		end

		local livGold = floor(liv/10000)
		local livGoldPerHour = floor(livGold/sessionDuration*factor)

		name = livGoldPerHour .. "|cffffd100g|r/h"
	end

	local sessionGrp = {
		type = "group",
		--order = order,
		name = name,
		args = {
		},
		plugins = {
		},
	}

	return sessionGrp
end


function addSessionData(group, key, label, value, order)
	-- label
	group.args["label_" .. key .. "_" .. order] = {
		type = "description", 
		order = order, 
		name = label,
		width = "normal", 
	}

	-- value
	group.args["value_" .. key .. "_" .. order] = {
		type = "description", 
		order = order+1, 
		name = value,
		width = "normal", 
	}

	-- new line
	group.args["newline_" .. key .. "_" .. order] = {
		type = "description",
		order = order+2,
		name = "",
		width = "full",
	}
end


function addEmptyLine(group, order)
	-- empty line
	group.args["newline_" .. order] = {
		type = "description",
		order = order,
		name = " ",
		width = "full",
	}
end

--[[-------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------------------]]
function getStatisticGroups()
	Debug("  getStatisticGroups")

	local groups = {}

	local sessions = LA:getSessions()
	for index, session in ipairs(sessions) do
		local sessionEnd = session["end"]
		
		if sessionEnd ~= nil then
			local sessionMapID = session["mapID"]
			local sessionStart = session["start"]
			local liv = session["liv"] or 0

			local zoneGrp = getOrCreateZoneGrp(groups, session, index)

			-- add session to zone
			local sessionGrp = createSessionGrp(session, index) -- TODO add group by
			zoneGrp.args["session" .. index] = sessionGrp

			-- date time
			addSessionData(sessionGrp, "datetime", "Date:", date("%m/%d/%Y %I:%M %p", sessionStart), (index+10))

			-- player-realm
			addSessionData(sessionGrp, "char", "Character:", session["player"], (index+20))

			-- duration
			local sessionDuration = sessionEnd - sessionStart
			addSessionData(sessionGrp, "duration", "Duration:", SecondsToTime(sessionDuration), (index+30))

			-- empty line
			addEmptyLine(sessionGrp, (index+40))

			-- looted item value
			local formattedLiv = LA:FormatTextMoney(liv) or 0
			addSessionData(sessionGrp, "liv", "Looted Item Value:", formattedLiv, (index+50))

			-- ...per hour			
			local factor = 3600
			if sessionDuration < factor then
				factor = sessionDuration
			end

			local livGold = floor(liv/10000)
			local livGoldPerHour = floor(livGold/sessionDuration*factor)
			addSessionData(sessionGrp, "liv", "...per Hour:", livGoldPerHour .. "|cffffd100g|r/h", (index+60))

			-- empty line
			addEmptyLine(sessionGrp, (index+70))

			-- noteworthy items
			local noteworthyItems = session["noteworthyItems"]
			local niCount = tlength(noteworthyItems)
			addSessionData(sessionGrp, "noteworthyItemsCount", "|cffffd100Noteworthy Items:|r", tostring(niCount), (index+70))

			--if niCount > 0 then
				-- add inline group
				local noteworthyItemsGroup = {
					type = "group",
					order = (index+80),
					inline = true,
					args = {
					},
					plugins = {
					},
				}
				sessionGrp.args["noteworthyItems"] = noteworthyItemsGroup

				local i = 0
				for itemID, quantity in pairs(noteworthyItems) do
					Debug("    " .. tostring(itemID) .. " x" .. tostring(quantity))

					if itemID ~= nil then
						local itemLink = select(2, GetItemInfo(itemID))

						noteworthyItemsGroup.args["item_" .. tostring(itemID)] = {
							type = "description",
							order = i,
							name = tostring(itemLink) .. " x" .. tostring(quantity),
							width = "full",
						}

						i = i+10
					end
				end
			--end

		end
	end
	
	return groups
end


function getIconDelete()
	return "Interface\\AddOns\\" .. LA.METADATA.NAME .. "\\Media\\delete2", 16, 16
end


function deleteStatisticEntry(entryID)
	Debug("  deleteStatisticEntry: entryID=" .. tostring(entryID))
end


function tlength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end


function Debug(msg)
	LA:Debug(msg)
end

--[[
function Debug(msg)
	--if LA.DEBUG then
		LA:Print(tostring(msg))
	--end
end
]]