package commands {

	import engine.BotEngine;

	public class DelayCommand extends BotCommand {

		public var delaySeconds:Number = 1.0;

		public function DelayCommand(seconds:Number = 1.0) {
			super(BotCommand.TYPE_DELAY);
			this.delaySeconds = Math.max(0.1, seconds);
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"delaySeconds": delaySeconds
				};
		}

		public static function fromJSON(data:Object):DelayCommand {
			if (data == null)
				return null;
			return new DelayCommand(Number(data.delaySeconds || 1.0));
		}

		override public function execute(bot:BotEngine):void {
			if (bot.delayTicksRemaining <= 0) {
				bot.delayTicksRemaining = Math.max(1, Math.round((delaySeconds * 1000) / 500));
			}

			bot.delayTicksRemaining--;
			if (bot.delayTicksRemaining <= 0) {
				bot.advanceStep();
			}
		}

		override public function toString():String {
			return "Wait [" + delaySeconds + "s]";
		}
	}
}
