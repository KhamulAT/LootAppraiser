-- LootAppraiser_Config.lua --
local LootAppraiser, LA = ...;

local Config = LA:NewModule("Config", "AceEvent-3.0")

AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
AceConfigDialog = LibStub("AceConfigDialog-3.0")

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")

local statisticsPanel

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
					args = {
						qualityFilter = {
							type = "select",
							order = 20,
							name = "Quality Filter",
							desc = "Items below the selected quality will not show in the loot collected list",
							values = LA.QUALITY_FILTER,
							set = function(info, value) 
								local oldValue = LA.db.profile[info[#info]]
								if oldValue ~= value then
									LA:Print("Quality Filter set to: " .. LA.QUALITY_FILTER[value] .. " and above.")
								end
								LA.db.profile[info[#info]] = value;
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
								local oldValue = LA.db.profile[info[#info]]
								if oldValue ~= value then
									LA:Print("Gold alert threshold set: " .. value .. " gold or higher.")
								end
								LA.db.profile[info[#info]] = value;
								LA:refreshStatusText()
							end,
						},
						ignoreRandomEnchants = {
							type = "toggle",
							order = 40,
							name = " Ignore random enchants on items",
							desc = "Ignore random enchants on items (like ...of the Bear) and show only the base item",
							width = "double",
							set = function(info, value) 
								local oldValue = LA.db.profile[info[#info]]
								if oldValue ~= value then
									LA:Print("Ignore random enchants set: " .. tostring(value) .. ".")
								end
								LA.db.profile[info[#info]] = value;
							end,
						},
					},
				},
				priceSourceGrp = {
					type = "group",
					order = 50,
					name = "Price Source",
					args = {
						priceSource = {
							type = "select",
							order = 20,
							name = "Price Source",
							desc = "TSM predefined price sources for item value calculation.",
							values = LA.PRICE_SOURCE,
							width = "double",
							set = function(info, value) 
								local oldValue = LA.db.profile[info[#info]]
								if oldValue ~= value then
									LA:Print("Price source changed to: " .. value)
								end
								LA.db.profile[info[#info]] = value;
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
								return not (LA.db.profile.priceSource == "Custom")
							end,
							set = function(info, value) 
								LA:Print("Custom price source changed to: " .. value)
								LA.db.profile[info[#info]] = value;
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
						addBlacklistedItems2DestroyTrash = {
							type = "toggle",
							order = 40,
							name = " Add blacklisted items to the destroy trash button.",
							desc = "Adds all blacklisted items from the TSM group to the destroyabel items list.",
							width = "full",
							disabled = function()
								return not (LA.db.profile.blacklist.tsmGroupEnabled == true)
							end,
							set = function(info, value) 
								local oldValue = LA.db.profile[info[#info]]
								if oldValue ~= value then
									LA:Print("Add blacklisted items to destroy trash set: " .. tostring(value) .. ".")
								end
								LA.db.profile.blacklist[info[#info]] = value;
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
								local oldValue = LA.db.profile[info[#info]]
								if oldValue ~= value then
									LA:Print("Enable Toasts set: " .. tostring(value) .. ".")
								end
								LA.db.profile[info[#info]] = value;
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
			args = {}
		},
	}, 
}

--[[-------------------------------------------------------------------------------------
-- AceAddon-3.0 - module standard methods
---------------------------------------------------------------------------------------]]
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


	AceConfigRegistry:RegisterOptionsTable(LootAppraiser, options.args.general)
	AceConfigRegistry:RegisterOptionsTable(LootAppraiser .. " Statistic", options.args.statistic, LootAppraiser)

	AceConfigDialog:AddToBlizOptions(LootAppraiser)
	AceConfigDialog:AddToBlizOptions(LootAppraiser .. " Statistic", "Statistic", LootAppraiser)

	options.args.statistic.args = getStatisticGroups()

	statisticsPanel = CreateFrame("Frame")
	statisticsPanel.name = "Statistics"
	statisticsPanel.parent = "LootAppraiser" --panel.name

	--InterfaceOptions_AddCategory(statisticsPanel)

	-- Fix sink config options
	options.args.general.args.notificationOptionsGrp.args.notificationLibSink.order = 200
	options.args.general.args.notificationOptionsGrp.args.notificationLibSink.inline = true
	options.args.general.args.notificationOptionsGrp.args.notificationLibSink.name = ""
end


function Config:OnEnable()
	Debug("Config:OnEnable()")

end


function Config:OnDisable()

end


function getStatisticGroups()
	Debug("  getStatisticGroups")

	local groups = {}

	local baseorder = 100;

	local i = 0

	local sessions = LA:getSessions()
	for i,v in ipairs(sessions) do
		local sessionMapID = v["mapID"]
		local sessionStart = v["start"];
		local sessionEnd = v["end"];
		local liv = v["liv"]
		
		if sessionEnd ~= nil then
			-- group name
			local grpID
			local groupName
			if sessionMapID ~= nil then
				grpID = "grp" .. tostring(sessionMapID)
				groupName = GetMapNameByID(sessionMapID)
			else
				grpID = "grgUndefined"
				groupName = "Undefined"
			end

			-- get group or create new if no group exists
			local grp = groups[grpID]
			if grp == nil then
				grp = {
					type = "group",
					order = 20,
					name = groupName,
					args = {
					},
					plugins = {
					},
				}
				groups[grpID] = grp
			end

			-- add row to group
			grp.args["sessionStart" .. (baseorder+i)] = {
				type = "description", 
				order = baseorder + (i * 10), 
				name = date("%x", sessionStart),
				width = "half", 
			}

--[[
			grp.args["player" .. (baseorder+i)] = {
				type = "description", 
				order = baseorder + (i * 10) + 1, 
				name = v["player"] or "",
				width = "normal", 
			}
]]

			local sessionDuration = sessionEnd - sessionStart
			grp.args["sessionDuration" .. (baseorder+1)] = {
				type = "description", 
				order = baseorder + (i * 10) + 2, 
				name = SecondsToTime(sessionDuration),
				width = "normal", 
			}
			
			local formattedLiv = LA:FormatTextMoney(liv) or 0
			grp.args["liv" .. (baseorder+1)] = {
				type = "description", 
				order = baseorder + (i * 10) + 3, 
				name = formattedLiv,
				width = "half", 
			}

			local factor = 3600
			if sessionDuration < factor then
				factor = sessionDuration
			end
			local livGold = floor(liv/10000)
			local livGoldPerHour = floor(livGold/sessionDuration*factor)
			grp.args["livPerHour" .. (baseorder+1)] = {
				type = "description", 
				order = baseorder + (i * 10) + 4, 
				name = livGoldPerHour .. "|cffffd100g|r/h",
				width = "half", 
			}
--[[
			grp.args["delete" .. (baseorder+1)] = {
				type = "execute",
				order = baseorder + (i * 10) + 4,
				func = deleteStatisticEntry(sessionStart),
				--image = getIconDelete()
				name = "delete entry 2",
				desc = "delete entry",
				image = "Interface\\AddOns\\" .. LA.METADATA.NAME .. "\\Media\\delete2",
				imageWidth = 16,
				imageHeight = 16,
				width = "half"
			}
]]
			-- new line
			grp.args["newline" .. (baseorder+i)] = {
				order = baseorder + (i * 10) + 6,
				type = "description",
				name = "",
				width = "full",
				cmdHidden = true,
			}
		else
			-- remove unclosed sessions (clean up)
			--sessions[i] = nil
		end
		i = i + 1
		baseorder = baseorder + 200
	end
	
	return groups
end

function getIconDelete()
	return "Interface\\AddOns\\" .. LA.METADATA.NAME .. "\\Media\\delete2", 16, 16
end

function deleteStatisticEntry(entryID)
	Debug("  deleteStatisticEntry: entryID=" .. tostring(entryID))
end

