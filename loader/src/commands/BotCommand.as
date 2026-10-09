package commands {

	import engine.BotEngine;

	public class BotCommand {

		public static const TYPE_KILL:String = "kill";
		public static const TYPE_JOIN:String = "join";
		public static const TYPE_JUMP:String = "jump";
		public static const TYPE_QUEST_ACCEPT:String = "quest_accept";
		public static const TYPE_QUEST_COMPLETE:String = "quest_complete";
		public static const TYPE_DELAY:String = "delay";
		public static const TYPE_TRANSFER_TO_BANK:String = "transfer_to_bank";
		public static const TYPE_TRANSFER_TO_INVENTORY:String = "transfer_to_inventory";
		public static const TYPE_NOTIF:String = "notif";

		public var type:String;

		public function BotCommand(type:String) {
			this.type = type;
		}

		public function toJSON():Object {
			return {"type": type};
		}

		public static function fromJSON(data:Object):BotCommand {
			if (data == null || data.type == null)
				return null;
			switch (String(data.type)) {
				case TYPE_KILL:
					return KillCommand.fromJSON(data);
				case TYPE_JOIN:
					return JoinCommand.fromJSON(data);
				case TYPE_JUMP:
					return JumpCommand.fromJSON(data);
				case TYPE_QUEST_ACCEPT:
					return QuestAcceptCommand.fromJSON(data);
				case TYPE_QUEST_COMPLETE:
					return QuestCompleteCommand.fromJSON(data);
				case TYPE_DELAY:
					return DelayCommand.fromJSON(data);
				case TYPE_TRANSFER_TO_BANK:
					return TransferToBankCommand.fromJSON(data);
				case TYPE_TRANSFER_TO_INVENTORY:
					return TransferToInventoryCommand.fromJSON(data);
				case TYPE_NOTIF:
					return NotifCommand.fromJSON(data);
				default:
					return null;
			}
		}

		public static function createKill(
				monster:String = "*",
				killMode:String = "none",
				killCount:int = 1,
				itemName:String = "",
				itemQty:int = 1
			):KillCommand {
			return new KillCommand(monster, killMode, killCount, itemName, itemQty);
		}

		public static function createJoin(map:String, cell:String = "Enter", pad:String = "Spawn"):JoinCommand {
			return new JoinCommand(map, cell, pad);
		}

		public static function createJump(cell:String = "Enter", pad:String = "Spawn"):JumpCommand {
			return new JumpCommand(cell, pad);
		}

		public static function createQuestAccept(questId:int):QuestAcceptCommand {
			return new QuestAcceptCommand(questId);
		}

		public static function createQuestComplete(questId:int, itemId:int = -1):QuestCompleteCommand {
			return new QuestCompleteCommand(questId, itemId);
		}

		public static function createDelay(seconds:Number):DelayCommand {
			return new DelayCommand(seconds);
		}

		public static function createTransferToBank(itemName:String):TransferToBankCommand {
			return new TransferToBankCommand(itemName);
		}

		public static function createTransferToInventory(itemName:String):TransferToInventoryCommand {
			return new TransferToInventoryCommand(itemName);
		}

		public static function createNotif(message:String, title:String = "Bot Alert"):NotifCommand {
			return new NotifCommand(message, title);
		}

		public function execute(bot:BotEngine):void {
			bot.advanceStep();
		}

		public function toString():String {
			return "Command [" + type + "]";
		}
	}
}
