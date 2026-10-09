package commands {

	import engine.BotEngine;

	public class QuestCompleteCommand extends BotCommand {

		public var questId:int = 0;
		public var itemId:int = -1;

		public function QuestCompleteCommand(questId:int = 0, itemId:int = -1) {
			super(BotCommand.TYPE_QUEST_COMPLETE);
			this.questId = questId;
			this.itemId = itemId;
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"questId": questId,
					"itemId": itemId
				};
		}

		public static function fromJSON(data:Object):QuestCompleteCommand {
			if (data == null)
				return null;
			return new QuestCompleteCommand(int(data.questId || 0), int(data.itemId != null ? data.itemId : -1));
		}

		override public function execute(bot:BotEngine):void {
			var game:Object = bot.getGame();
			try {
				if (game != null && game.world != null) {
					game.world.tryQuestComplete(questId, itemId, false, 1);
					if (itemId > -1) {
						bot.log("Turned in Quest [" + questId + "] (Item: " + itemId + ")");
					}
					else {
						bot.log("Turned in Quest [" + questId + "]");
					}
				}
			}
			catch (e:Error) {
			}
			bot.advanceStep();
		}

		override public function toString():String {
			if (itemId > -1) {
				return "Turn-in Quest [" + questId + "] (Item: " + itemId + ")";
			}
			return "Turn-in Quest [" + questId + "]";
		}
	}
}
