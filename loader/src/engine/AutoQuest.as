package engine {

	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class AutoQuest {

		private var game:Object;
		private var autoQuestTimer:Timer;
		private var trackedIds:Array = [];

		public function AutoQuest(game:Object) {
			this.game = game;
		}

		public function getQuestTree():Array {
			var quests:Array = [];

			if (game == null || game.world == null || game.world.questTree == null) {
				return quests;
			}

			for each (var q:Object in game.world.questTree) {
				var questData:QuestData = new QuestData();

				// Basic quest info
				questData.QuestID = q.QuestID || 0;
				questData.sName = q.sName || "";
				questData.sField = q.sField || "";
				questData.bStaff = q.bStaff || false;

				// Requirements
				if (q.turnin != null && q.oItems != null) {
					for each (var req:Object in q.turnin) {
						var item:Object = q.oItems[req.ItemID];
						if (item != null) {
							var reqData:QuestItemData = new QuestItemData();
							reqData.sName = item.sName || "";
							reqData.ItemID = item.ItemID || 0;
							reqData.bTemp = item.bTemp || 0;
							reqData.iQty = req.iQty || 0;
							questData.requirements.push(reqData);
						}
					}
				}

				// Rewards
				if (q.reward != null && q.oRewards != null) {
					for each (var rew:Object in q.reward) {
						for each (var rewContainer:* in q.oRewards) {
							for each (var _item:Object in rewContainer) {
								if (_item.ItemID != null && _item.ItemID == rew.ItemID) {
									var rewardData:QuestRewardData = new QuestRewardData();
									rewardData.sName = _item.sName || "";
									rewardData.ItemID = rew.ItemID || 0;
									rewardData.iQty = rew.iQty || 0;
									rewardData.iRate = rew.iRate || 0;
									rewardData.DropChance = String(rew.iRate || 0) + "%";
									questData.rewards.push(rewardData);
								}
							}
						}
					}
				}

				quests.push(questData);
			}

			// Sort by QuestID ascending
			quests.sortOn("QuestID", Array.NUMERIC);

			return quests;
		}

		public function isInProgress(id:int):Boolean {
			return game.world.isQuestInProgress(id);
		}

		public function tryToComplete(id:int, qty:int = 1, itemID:String = "-1", special:String = "False"):void {
			game.world.tryQuestComplete(id, parseInt(itemID), special == "True", qty);
		}

		public function accept(id:int):void {
			game.world.acceptQuest(id);
		}

		public function load(id:String):void {
			game.world.showQuests([id], "q");
		}

		public function loadMultiple(ids:String):void {
			game.world.showQuests(ids.split(","), "q");
		}

		public function getQuests(ids:Array):void {
			game.world.getQuests(ids);
		}

		public function isAvailable(questId:int):Boolean {
			return getQuestValidationString(questId) == "";
		}

		public function canComplete(questId:int):Boolean {
			var validation:String = getQuestValidationString(questId);
			return game.world.canTurnInQuest(questId) && validation == "";
		}

		public function hasRequiredItemsForQuest(quest:Object):Boolean {
			var item:Object = null;
			var itemId:int = 0;
			var requiredQty:int = 0;
			var inventoryItem:Object = null;

			if (quest.reqd != null && quest.reqd.length > 0) {
				for each (item in quest.reqd) {
					itemId = item.ItemID;
					requiredQty = int(item.iQty);
					inventoryItem = game.world.invTree[itemId];

					if (inventoryItem == null || inventoryItem.iQty < requiredQty) {
						return false;
					}
				}
			}

			return true;
		}

		public function getQuestValidationString(questId:int):String {
			var rank:int = 0;
			var requiredCp:int = 0;
			var requiredRep:int = 0;
			var reqItem:Object = null;
			var reqItemId:int = 0;
			var reqQty:int = 0;
			var invItem:Object = null;
			var validationMsg:String = null;
			var quest:Object = game.world.questTree[questId];

			if (quest.sField != null && game.world.getAchievement(quest.sField, quest.iIndex) != 0) {
				if (quest.sField == "im0") {
					return "Monthly Quests are only available once per month.";
				}
				return "Daily Quests are only available once per day.";
			}

			if (quest.bUpg == 1 && !game.world.myAvatar.isUpgraded()) {
				return "Upgrade is required for this quest!";
			}

			if (quest.iSlot >= 0 && game.world.getQuestValue(quest.iSlot) < quest.iValue - 1) {
				return "Quest has not been unlocked!";
			}

			if (quest.iLvl > game.world.myAvatar.objData.intLevel) {
				return "Unlocks at Level " + quest.iLvl + ".";
			}

			if (quest.iClass > 0 && game.world.myAvatar.getCPByID(quest.iClass) < quest.iReqCP) {
				rank = game.getRankFromPoints(quest.iReqCP);
				requiredCp = quest.iReqCP - game.arrRanks[rank - 1];
				if (requiredCp > 0) {
					return "Requires " + requiredCp + " Class Points on " + quest.sClass + ", Rank " + rank + ".";
				}
				return "Requires " + quest.sClass + ", Rank " + rank + ".";
			}

			if (quest.FactionID > 1 && game.world.myAvatar.getRep(quest.FactionID) < quest.iReqRep) {
				rank = game.getRankFromPoints(quest.iReqRep);
				requiredRep = quest.iReqRep - game.arrRanks[rank - 1];
				if (requiredRep > 0) {
					return "Requires " + requiredRep + " Reputation for " + quest.sFaction + ", Rank " + rank + ".";
				}
				return "Requires " + quest.sFaction + ", Rank " + rank + ".";
			}

			if (quest.reqd != null && !hasRequiredItemsForQuest(quest)) {
				validationMsg = "Required Item(s): ";
				for each (reqItem in quest.reqd) {
					reqItemId = reqItem.ItemID;
					reqQty = int(reqItem.iQty);
					invItem = game.world.invTree[reqItemId];

					if (invItem.sES == "ar") {
						rank = game.getRankFromPoints(reqQty);
						requiredCp = reqQty - game.arrRanks[rank - 1];
						if (requiredCp > 0) {
							validationMsg += requiredCp + " Class Points on ";
						}
						validationMsg += invItem.sName + ", Rank " + rank;
					}
					else {
						validationMsg += invItem.sName;
						if (reqQty > 1) {
							validationMsg += "x" + reqQty;
						}
					}
					validationMsg += ", ";
				}
				return validationMsg.substr(0, validationMsg.length - 2) + ".";
			}

			return "";
		}

		public function startAutoQuest(ids:String):void {
			stopAutoQuest();

			// Normalize and store IDs as string array
			trackedIds = ids.replace(/\s+/g, "").split(",");
			if (trackedIds.length == 0)
				return;

			var missingIds:Array = [];
			for each (var id:String in trackedIds) {
				if (game.world.questTree[id] == null) {
					missingIds.push(id);
				}
			}

			if (missingIds.length > 0) {
				getQuests(missingIds);
			}

			autoQuestTimer = new Timer(1000);
			autoQuestTimer.addEventListener(TimerEvent.TIMER, onAutoQuestTick, false, 0, true);
			autoQuestTimer.start();
		}

		public function stopAutoQuest():void {
			if (autoQuestTimer != null) {
				autoQuestTimer.stop();
				autoQuestTimer.removeEventListener(TimerEvent.TIMER, onAutoQuestTick);
				autoQuestTimer = null;
			}
		}

		private function onAutoQuestTick(e:TimerEvent):void {
			if (trackedIds == null || trackedIds.length == 0)
				return;

			for each (var id:String in trackedIds) {
				var questId:int = parseInt(id);
				if (game.world.questTree[questId] == null)
					continue;

				if (isAvailable(questId) && !isInProgress(questId)) {
					accept(questId);
				}
				else {
					if (canComplete(questId)) {
						tryToComplete(questId);
					}
				}
			}
		}
	}
}

// Quest Data Model
class QuestData {
	public var QuestID:int = 0;
	public var sName:String = "";
	public var sField:String = "";
	public var bStaff:Boolean = false;
	public var requirements:Array = [];
	public var rewards:Array = [];

	public function QuestData() {
		requirements = [];
		rewards = [];
	}
}

// Quest Item Data Model (for requirements)
class QuestItemData {
	public var sName:String = "";
	public var ItemID:int = 0;
	public var bTemp:int = 0;
	public var iQty:int = 0;

	public function QuestItemData() {
	}
}

// Quest Reward Data Model
class QuestRewardData {
	public var sName:String = "";
	public var ItemID:int = 0;
	public var iQty:int = 0;
	public var iRate:int = 0;
	public var DropChance:String = "0%";

	public function QuestRewardData() {
	}
}
