package commands {

	import engine.BotEngine;
	import Utils;

	public class LabelCommand extends BotCommand {

		public var labelName:String = "";

		public function LabelCommand(labelName:String = "") {
			super(BotCommand.TYPE_LABEL);
			this.labelName = (labelName != null) ? Utils.trim(labelName).toUpperCase() : "";
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"labelName": labelName
				};
		}

		public static function fromJSON(data:Object):LabelCommand {
			if (data == null)
				return null;
			var name:String = data.labelName != null ? String(data.labelName).toUpperCase() : "";
			return new LabelCommand(name);
		}

		override public function execute(bot:BotEngine):void {
			// Marker command: advance immediately to next step
			bot.advanceStep(100);
		}

		override public function toString():String {
			return "Label [" + labelName + "]";
		}
	}
}
