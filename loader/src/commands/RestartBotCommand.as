package commands {

	import engine.BotEngine;

	public class RestartBotCommand extends BotCommand {

		public function RestartBotCommand() {
			super(BotCommand.TYPE_RESTART_BOT);
		}

		override public function toJSON():Object {
			return {
					"type": type
				};
		}

		public static function fromJSON(data:Object):RestartBotCommand {
			return new RestartBotCommand();
		}

		override public function execute(bot:BotEngine):void {
			bot.log("Restart Bot: Restarting script from step 1.");
			bot.restart();
		}

		override public function toString():String {
			return "Restart Bot";
		}
	}
}
