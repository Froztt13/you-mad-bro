package engine {

	import commands.BotCommand;

	/**
	 * Converts Grimoire / Grimlite (.gbot) JSON configurations into
	 * native you-mad-bro bot configuration objects.
	 */
	public class GrimoireImporter {

		public static function isGrimoireConfig(data:Object):Boolean {
			if (data == null) {
				return false;
			}
			if (data["$type"] != null && String(data["$type"]).indexOf("Grimoire.Botting.Configuration") >= 0) {
				return true;
			}
			if (data.Commands != null && data.Commands["$values"] is Array) {
				return true;
			}
			return false;
		}

		public static function convert(data:Object, logFn:Function = null):Object {
			if (data == null) {
				return null;
			}

			var whitelist:Array = [];
			var seenDrops:Object = {};

			function addDrop(name:String):void {
				if (name == null) {
					return;
				}
				var trimmed:String = Utils.trim(name);
				if (trimmed.length == 0) {
					return;
				}
				var key:String = trimmed.toLowerCase();
				if (!seenDrops[key]) {
					seenDrops[key] = true;
					whitelist.push(trimmed);
				}
			}

			if (data.Drops != null && data.Drops["$values"] is Array) {
				for each (var dropItem:* in data.Drops["$values"]) {
					if (dropItem != null) {
						addDrop(String(dropItem));
					}
				}
			}

			var quests:Array = [];
			if (data.Quests != null && data.Quests["$values"] is Array) {
				for each (var qItem:* in data.Quests["$values"]) {
					if (qItem == null) {
						continue;
					}
					if (qItem is Object && qItem.QuestID != null) {
						quests.push(String(qItem.QuestID));
					}
					else {
						quests.push(String(qItem));
					}
				}
			}

			var convertedCmds:Array = [];
			var unsupportedCounts:Object = {};
			var rawCommands:Array = (data.Commands != null && data.Commands["$values"] is Array)
				? data.Commands["$values"] as Array
				: [];

			for each (var cObj:Object in rawCommands) {
				if (cObj == null) {
					continue;
				}
				var cmdName:String = extractCommandName(cObj["$type"]);
				convertCommand(cmdName, cObj, convertedCmds, addDrop, unsupportedCounts);
			}

			if (logFn != null) {
				var skippedList:Array = [];
				for (var uName:String in unsupportedCounts) {
					skippedList.push(uName + " x" + unsupportedCounts[uName]);
				}
				if (skippedList.length > 0) {
					logFn("[GrimoireImporter] Unsupported .gbot commands converted to blank spacers: " + skippedList.join(", "));
				}
			}

			return {
					"name": "Imported .gbot Script",
					"loop": true,
					"leaveCombatOnStop": true,
					"notifyItemDrops": true,
					"whitelist": whitelist,
					"quests": quests,
					"commands": convertedCmds
				};
		}

		private static function extractCommandName(rawType:*):String {
			if (rawType == null) {
				return "";
			}
			var s:String = String(rawType);
			var commaIdx:int = s.indexOf(",");
			if (commaIdx >= 0) {
				s = s.substr(0, commaIdx);
			}
			var dotIdx:int = s.lastIndexOf(".");
			if (dotIdx >= 0) {
				s = s.substr(dotIdx + 1);
			}
			return Utils.trim(s);
		}

		private static function extractQuestId(cObj:Object):int {
			if (cObj.Quest != null && cObj.Quest.QuestID != null) {
				return int(cObj.Quest.QuestID);
			}
			if (cObj.QuestID != null) {
				return int(cObj.QuestID);
			}
			return 0;
		}

		private static function extractQuestItemId(cObj:Object):int {
			if (cObj.Quest != null && cObj.Quest.ItemId != null) {
				return int(cObj.Quest.ItemId);
			}
			if (cObj.ItemId != null) {
				return int(cObj.ItemId);
			}
			return -1;
		}

		private static function convertCommand(
				cmdName:String,
				cObj:Object,
				out:Array,
				addDrop:Function,
				unsupportedCounts:Object
			):void {
			switch (cmdName) {
				// -------------------------------------------------------------
				// Combat
				// -------------------------------------------------------------
				case "CmdShortHunt":
					var mapName:String = cObj.Map != null ? Utils.trim(String(cObj.Map)) : "";
					if (mapName.length > 0) {
						out.push({
								"type": BotCommand.TYPE_JOIN,
								"map": mapName,
								"cell": cObj.Cell != null && String(cObj.Cell).length > 0 ? String(cObj.Cell) : "Enter",
								"pad": cObj.Pad != null && String(cObj.Pad).length > 0 ? String(cObj.Pad) : "Spawn"
							});
					}
					var shItem:String = cObj.ItemName != null ? Utils.trim(String(cObj.ItemName)) : "";
					out.push({
							"type": BotCommand.TYPE_HUNT,
							"monster": cObj.Monster != null && String(cObj.Monster).length > 0 ? String(cObj.Monster) : "*",
							"killMode": shItem.length > 0 ? "item" : "none",
							"killCount": 1,
							"itemName": shItem,
							"itemQty": Math.max(1, int(cObj.Quantity || 1)),
							"mostMonstersOnly": true
						});
					break;

				case "CmdKillFor":
					var kfItem:String = cObj.ItemName != null ? Utils.trim(String(cObj.ItemName)) : "";
					out.push({
							"type": BotCommand.TYPE_HUNT,
							"monster": cObj.Monster != null && String(cObj.Monster).length > 0 ? String(cObj.Monster) : "*",
							"killMode": kfItem.length > 0 ? "item" : "none",
							"killCount": 1,
							"itemName": kfItem,
							"itemQty": Math.max(1, int(cObj.Quantity || 1)),
							"mostMonstersOnly": true
						});
					break;

				case "CmdKill":
				case "CmdAttack":
					out.push({
							"type": BotCommand.TYPE_KILL,
							"monster": cObj.Monster != null && String(cObj.Monster).length > 0 ? String(cObj.Monster) : "*",
							"killMode": "none",
							"killCount": 1
						});
					break;

				case "CmdRest":
					out.push({
							"type": BotCommand.TYPE_DELAY,
							"delaySeconds": 2.0
						});
					break;

				// -------------------------------------------------------------
				// Map
				// -------------------------------------------------------------
				case "CmdJoin":
					out.push({
							"type": BotCommand.TYPE_JOIN,
							"map": cObj.Map != null ? String(cObj.Map) : "",
							"cell": cObj.Cell != null && String(cObj.Cell).length > 0 ? String(cObj.Cell) : "Enter",
							"pad": cObj.Pad != null && String(cObj.Pad).length > 0 ? String(cObj.Pad) : "Spawn"
						});
					break;

				case "CmdMoveToCell":
					out.push({
							"type": BotCommand.TYPE_JUMP,
							"cell": cObj.Cell != null && String(cObj.Cell).length > 0 ? String(cObj.Cell) : "Enter",
							"pad": cObj.Pad != null && String(cObj.Pad).length > 0 ? String(cObj.Pad) : "Spawn"
						});
					break;

				case "CmdWalk":
					out.push({
							"type": BotCommand.TYPE_WALK,
							"x": int(cObj.X != null ? cObj.X : 0),
							"y": int(cObj.Y != null ? cObj.Y : 0)
						});
					break;

				// -------------------------------------------------------------
				// Quest
				// -------------------------------------------------------------
				case "CmdAcceptQuest":
					out.push({
							"type": BotCommand.TYPE_QUEST_ACCEPT,
							"questId": extractQuestId(cObj)
						});
					break;

				case "CmdCompleteQuest":
					out.push({
							"type": BotCommand.TYPE_QUEST_COMPLETE,
							"questId": extractQuestId(cObj),
							"itemId": extractQuestItemId(cObj)
						});
					break;

				// -------------------------------------------------------------
				// Item
				// -------------------------------------------------------------
				case "CmdBuy":
					out.push({
							"type": BotCommand.TYPE_BUY_ITEM,
							"shopId": int(cObj.ShopId || 0),
							"itemName": cObj.ItemName != null ? String(cObj.ItemName) : "",
							"qty": Math.max(1, int(cObj.Qty || 1))
						});
					break;

				case "CmdEquip":
					out.push({
							"type": BotCommand.TYPE_EQUIP_ITEM,
							"itemName": cObj.ItemName != null ? String(cObj.ItemName) : ""
						});
					break;

				case "CmdSell":
					out.push({
							"type": BotCommand.TYPE_SELL_ITEM,
							"itemName": cObj.ItemName != null ? String(cObj.ItemName) : ""
						});
					break;

				case "CmdMapItem":
					out.push({
							"type": BotCommand.TYPE_GET_MAP_ITEM,
							"itemId": int(cObj.ItemId || 0),
							"qty": 1
						});
					break;

				case "CmdBankTransfer":
					out.push({
							"type": Boolean(cObj.TransferFromBank) ? BotCommand.TYPE_TRANSFER_TO_INVENTORY : BotCommand.TYPE_TRANSFER_TO_BANK,
							"itemName": cObj.ItemName != null ? String(cObj.ItemName) : ""
						});
					break;

				case "CmdGetDrop":
					if (cObj.ItemName != null) {
						addDrop(String(cObj.ItemName));
					}
					out.push({
							"type": BotCommand.TYPE_BLANK,
							"description": "Whitelist drop: " + (cObj.ItemName != null ? String(cObj.ItemName) : "")
						});
					break;

				// -------------------------------------------------------------
				// Misc & Flow Control
				// -------------------------------------------------------------
				case "CmdLabel":
					out.push({
							"type": BotCommand.TYPE_LABEL,
							"labelName": cObj.Name != null ? String(cObj.Name).toUpperCase() : ""
						});
					break;

				case "CmdGotoLabel":
					out.push({
							"type": BotCommand.TYPE_GOTO_LABEL,
							"labelName": cObj.Label != null ? String(cObj.Label).toUpperCase() : ""
						});
					break;

				case "CmdDelay":
					var ms:Number = Number(cObj.Delay != null ? cObj.Delay : 1000);
					out.push({
							"type": BotCommand.TYPE_DELAY,
							"delaySeconds": Math.max(0.1, ms / 1000.0)
						});
					break;

				case "CmdRestart":
					out.push({"type": BotCommand.TYPE_RESTART_BOT});
					break;

				case "CmdStop":
					out.push({"type": BotCommand.TYPE_STOP_BOT});
					break;

				case "CmdBlank":
				case "CmdBlank2":
				case "CmdBlank3":
					out.push({
							"type": BotCommand.TYPE_BLANK,
							"description": cObj.Text != null ? String(cObj.Text) : ""
						});
					break;

				case "CmdClientMessage":
				case "CmdLog":
					out.push({
							"type": BotCommand.TYPE_BLANK,
							"description": cObj.Message != null ? String(cObj.Message) : (cObj.Text != null ? String(cObj.Text) : "")
						});
					break;

				// -------------------------------------------------------------
				// Statements / Conditionals
				// -------------------------------------------------------------
				case "CmdInInventory":
					out.push({
							"type": BotCommand.TYPE_IS_ITEM_IN_INV,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": cObj.Value2 != null ? String(cObj.Value2) : "1"
						});
					break;

				case "CmdNotInInventory":
				case "CmdNotInBankAndInvent":
					out.push({
							"type": BotCommand.TYPE_IS_ITEM_NOT_IN_INV,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": cObj.Value2 != null ? String(cObj.Value2) : "1"
						});
					break;

				case "CmdInBank":
					out.push({
							"type": BotCommand.TYPE_IS_ITEM_IN_BANK,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": cObj.Value2 != null ? String(cObj.Value2) : "1"
						});
					break;

				case "CmdNotInBank":
					out.push({
							"type": BotCommand.TYPE_IS_ITEM_NOT_IN_BANK,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": cObj.Value2 != null ? String(cObj.Value2) : "1"
						});
					break;

				case "CmdEquipped":
					out.push({
							"type": BotCommand.TYPE_IS_ITEM_EQUIPED,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": ""
						});
					break;

				case "CmdNotEquipped":
					out.push({
							"type": BotCommand.TYPE_IS_ITEM_NOT_EQUIPED,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": ""
						});
					break;

				case "CmdQuestAvailable":
					out.push({
							"type": BotCommand.TYPE_IS_QUEST_AVAILABLE,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": ""
						});
					break;

				case "CmdQuestNotAvailable":
					out.push({
							"type": BotCommand.TYPE_IS_QUEST_NOT_AVAILABLE,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": ""
						});
					break;

				case "CmdQuestCompleted":
					out.push({
							"type": BotCommand.TYPE_IS_QUEST_CAN_BE_TURNED_IN,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": ""
						});
					break;

				case "CmdQuestInProgress":
					out.push({
							"type": BotCommand.TYPE_IS_QUEST_IN_PROGRESS,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": ""
						});
					break;

				case "CmdQuestNotInProgress":
					out.push({
							"type": BotCommand.TYPE_IS_QUEST_NOT_IN_PROGRESS,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": ""
						});
					break;

				case "CmdHealthGreaterThan":
					out.push({
							"type": BotCommand.TYPE_IS_HEALTH_GREATER,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "1000",
							"var2": ""
						});
					break;

				case "CmdHealthLessThan":
					out.push({
							"type": BotCommand.TYPE_IS_HEALTH_LESS,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "1000",
							"var2": ""
						});
					break;

				case "CmdManaGreaterThan":
					out.push({
							"type": BotCommand.TYPE_IS_MANA_GREATER,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "50",
							"var2": ""
						});
					break;

				case "CmdManaLessThan":
					out.push({
							"type": BotCommand.TYPE_IS_MANA_LESS,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "50",
							"var2": ""
						});
					break;

				case "CmdLevelGreaterThan":
					out.push({
							"type": BotCommand.TYPE_IS_LEVEL_GREATER,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "100",
							"var2": ""
						});
					break;

				case "CmdLevelLessThan":
					out.push({
							"type": BotCommand.TYPE_IS_LEVEL_LESS,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "100",
							"var2": ""
						});
					break;

				case "CmdPlayerAuraGreaterThan":
					out.push({
							"type": BotCommand.TYPE_IS_PLAYER_AURA_GREATER,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": cObj.Value2 != null ? String(cObj.Value2) : "0"
						});
					break;

				case "CmdPlayerAuraLessThan":
					out.push({
							"type": BotCommand.TYPE_IS_PLAYER_AURA_LESS,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": cObj.Value2 != null ? String(cObj.Value2) : "1"
						});
					break;

				case "CmdMonsterInRoom":
					out.push({
							"type": BotCommand.TYPE_IS_MONSTER_IN_ROOM,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "*",
							"var2": ""
						});
					break;

				case "CmdMonsterNotInRoom":
					out.push({
							"type": BotCommand.TYPE_IS_MONSTER_NOT_IN_ROOM,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "*",
							"var2": ""
						});
					break;

				case "CmdGoldGreaterThan":
					out.push({
							"type": BotCommand.TYPE_IS_GOLD_GREATER,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "0",
							"var2": ""
						});
					break;

				case "CmdGoldLessThan":
					out.push({
							"type": BotCommand.TYPE_IS_GOLD_LESS,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "0",
							"var2": ""
						});
					break;

				case "CmdIsMember":
					out.push({
							"type": BotCommand.TYPE_IS_PLAYER_MEMBER,
							"var1": "",
							"var2": ""
						});
					break;

				case "CmdMapIs":
					out.push({
							"type": BotCommand.TYPE_IS_MAP,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": ""
						});
					break;

				case "CmdMapIsNot":
					out.push({
							"type": BotCommand.TYPE_IS_MAP_NOT,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": ""
						});
					break;

				case "CmdCellIs":
					out.push({
							"type": BotCommand.TYPE_IS_CELL,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": ""
						});
					break;

				case "CmdCellIsNot":
					out.push({
							"type": BotCommand.TYPE_IS_CELL_NOT,
							"var1": cObj.Value1 != null ? String(cObj.Value1) : "",
							"var2": ""
						});
					break;

				// -------------------------------------------------------------
				// Unsupported commands -> keep blank spacer to preserve indices
				// -------------------------------------------------------------
				default:
					var key:String = cmdName.length > 0 ? cmdName : "Unknown";
					unsupportedCounts[key] = (unsupportedCounts[key] != null) ? int(unsupportedCounts[key]) + 1 : 1;
					out.push({
							"type": BotCommand.TYPE_BLANK,
							"description": "[Unsupported .gbot: " + key + "]"
						});
					break;
			}
		}
	}
}
