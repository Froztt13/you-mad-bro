package commands.conditions {

	import commands.BotCommand;
	import engine.BotEngine;
	import Utils;

	/**
	 * Conditional command to verify if current map does NOT match the specified map name.
	 * var1: mapName
	 * var2: "" (empty/null)
	 */
	public class IsMapNotCommand extends BaseConditionalCommand {

		public static const COMMAND_LABEL:String = "If Map Is Not";
		public static const VAR1_LABEL:String = "Map Name:";
		public static const VAR1_RESTRICT:String = null;
		public static const VAR1_DEFAULT:String = "";
		public static const VAR2_LABEL:String = null;
		public static const VAR2_RESTRICT:String = null;
		public static const VAR2_DEFAULT:String = "";

		public function IsMapNotCommand(mapName:String = "") {
			var mStr:String = (mapName != null) ? Utils.trim(mapName) : "";
			super(BotCommand.TYPE_IS_MAP_NOT, mStr, "");
		}

		public static function fromJSON(data:Object):IsMapNotCommand {
			if (data == null)
				return null;
			var mName:String = data.var1 != null ? String(data.var1) : (data.mapName != null ? String(data.mapName) : "");
			return new IsMapNotCommand(mName);
		}

		override public function get commandLabel():String {
			return COMMAND_LABEL;
		}

		override public function get var1Label():String {
			return VAR1_LABEL;
		}

		override public function get var1Restrict():String {
			return VAR1_RESTRICT;
		}

		override public function get var1Default():String {
			return VAR1_DEFAULT;
		}

		override public function get var2Label():String {
			return VAR2_LABEL;
		}

		override public function get var2Restrict():String {
			return VAR2_RESTRICT;
		}

		override public function get var2Default():String {
			return VAR2_DEFAULT;
		}

		override public function checkCondition(bot:BotEngine):Boolean {
			if (bot == null || var1 == null || var1.length == 0)
				return false;
			return !bot.isCurrentMap(var1);
		}

		override public function toString():String {
			return commandLabel + " [" + var1 + "]";
		}
	}
}
