package commands {

	import engine.BotEngine;

	public class BlankCommand extends BotCommand {

		public var description:String = "";

		public function BlankCommand(description:String = "") {
			super(BotCommand.TYPE_BLANK);
			this.description = (description != null) ? description : "";
		}

		override public function toJSON():Object {
			var obj:Object = {
					"type": type
				};
			if (description != null && description.length > 0) {
				obj["description"] = description;
			}
			return obj;
		}

		public static function fromJSON(data:Object):BlankCommand {
			if (data == null)
				return null;
			var desc:String = data.description != null ? String(data.description) : "";
			if (desc == "" && data.text != null) {
				desc = String(data.text);
			}
			return new BlankCommand(desc);
		}

		override public function execute(bot:BotEngine):void {
			// Spacer command: advance immediately to next step without delay
			bot.advanceStep(0);
		}

		override public function toString():String {
			return description;
		}
	}
}
