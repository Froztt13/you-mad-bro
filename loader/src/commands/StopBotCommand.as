package commands {

	import engine.BotEngine;

	public class StopBotCommand extends BotCommand {

		public function StopBotCommand() {
			super(BotCommand.TYPE_STOP_BOT);
		}

		override public function toJSON():Object {
			return {
					"type": type
				};
		}

		public static function fromJSON(data:Object):StopBotCommand {
			return new StopBotCommand();
		}

		override public function execute(bot:BotEngine):void {
			bot.log("Stop Bot: Stopping bot execution.");
			bot.stop();
		}

		override public function toString():String {
			return "Stop Bot";
		}
	}
}
