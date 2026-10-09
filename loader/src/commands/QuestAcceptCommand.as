package commands {
	import engine.BotEngine;

	public class QuestAcceptCommand extends BotCommand {

		public var questId:int = 0;

		public function QuestAcceptCommand(questId:int = 0) {
			super(BotCommand.TYPE_QUEST_ACCEPT);
			this.questId = questId;
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"questId": questId
				};
		}

		public static function fromJSON(data:Object):QuestAcceptCommand {
			if (data == null)
				return null;
			return new QuestAcceptCommand(int(data.questId || 0));
		}

		private var loadAttempts:int = 0;

		override public function execute(bot:BotEngine):void {
			var game:Object = bot.getGame();
			if (game == null || game.world == null) {
				bot.log("[QuestAccept] Error: Game or World instance not found.");
				bot.advanceStep();
				return;
			}

			try {
				if (game.world.isQuestInProgress != null && game.world.isQuestInProgress(questId)) {
					loadAttempts = 0;
					bot.log("[QuestAccept] Quest [" + questId + "] already in progress.");
					bot.advanceStep();
					return;
				}

				// 1. Jika quest belum ter-load di questTree, request data quest dulu
				if (game.world.questTree == null || game.world.questTree[questId] == null) {
					if (loadAttempts < 3) {
						loadAttempts++;
						bot.log("[QuestAccept] Loading quest data [" + questId + "] (attempt " + loadAttempts + ")...");
						game.world.getQuests([questId]);
						bot.delay(1000); // Beri jeda 1 detik agar data quest tiba dari server
						return; // Belum advanceStep, tick berikutnya akan coba accept
					}
					else {
						loadAttempts = 0;
						bot.log("[QuestAccept] Quest data [" + questId + "] not found after 3 attempts. Skipping...");
						bot.advanceStep();
						return;
					}
				}

				// 2. Data quest sudah ada di questTree, lakukan accept
				loadAttempts = 0;
				game.world.acceptQuest(questId);
				bot.log("Accepted Quest [" + questId + "]");
				bot.advanceStep();
			}
			catch (e:Error) {
				loadAttempts = 0;
				bot.log("[QuestAccept] Error: " + e.message);
				bot.advanceStep();
			}
		}

		override public function toString():String {
			return "Accept Quest [" + questId + "]";
		}
	}
}
