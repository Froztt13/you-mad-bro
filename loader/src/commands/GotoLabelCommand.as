package commands {

	import engine.BotEngine;
	import Utils;

	public class GotoLabelCommand extends BotCommand {

		public var labelName:String = "";

		public function GotoLabelCommand(labelName:String = "") {
			super(BotCommand.TYPE_GOTO_LABEL);
			this.labelName = (labelName != null) ? Utils.trim(labelName).toUpperCase() : "";
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"labelName": labelName
				};
		}

		public static function fromJSON(data:Object):GotoLabelCommand {
			if (data == null)
				return null;
			var name:String = data.labelName != null ? String(data.labelName).toUpperCase() : "";
			return new GotoLabelCommand(name);
		}

		override public function execute(bot:BotEngine):void {
			if (labelName != null && labelName.length > 0) {
				var jumped:Boolean = bot.gotoLabel(labelName);
				if (!jumped) {
					bot.log("GotoLabel: Label '" + labelName + "' not found, continuing.");
					bot.advanceStep(500);
				}
			}
			else {
				bot.advanceStep(500);
			}
		}

		override public function toString():String {
			return "Goto Label [" + labelName + "]";
		}
	}
}
