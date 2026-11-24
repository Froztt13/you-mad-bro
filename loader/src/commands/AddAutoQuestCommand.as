package commands {

	import engine.BotEngine;

	/**
	 * Dynamically registers a Quest ID into the AutoQuest engine list during script execution.
	 */
	public class AddAutoQuestCommand extends BotCommand {

		public var questId:int = 0;

		public function AddAutoQuestCommand(questId:int = 0) {
			super(BotCommand.TYPE_ADD_AUTO_QUEST);
			this.questId = questId;
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"questId": questId
				};
		}

		public static function fromJSON(data:Object):AddAutoQuestCommand {
			if (data == null)
				return null;
			return new AddAutoQuestCommand(int(data.questId || 0));
		}

		override public function execute(bot:BotEngine):void {
			if (bot != null && questId > 0) {
				bot.addAutoQuest(questId);
			}
			bot.advanceStep(100);
		}

		override public function toString():String {
			return "Add AutoQuest [" + questId + "]";
		}
	}
}
