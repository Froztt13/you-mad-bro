package commands.conditions {

	import commands.BotCommand;
	import engine.BotEngine;
	import Utils;

	/**
	 * Conditional command to verify if player's level is less than the specified value.
	 * var1: level
	 */
	public class IsLevelLessThanCommand extends BaseConditionalCommand {

		public static const COMMAND_LABEL:String = "If Level Less Than";
		public static const VAR1_LABEL:String = "Level:";
		public static const VAR1_RESTRICT:String = "0-9";
		public static const VAR1_DEFAULT:String = "100";
		public static const VAR2_LABEL:String = null;
		public static const VAR2_RESTRICT:String = null;
		public static const VAR2_DEFAULT:String = "";

		public function IsLevelLessThanCommand(level:* = 100) {
			var lStr:String = (level != null) ? Utils.trim(String(level)) : "100";
			super(BotCommand.TYPE_IS_LEVEL_LESS, lStr, "");
		}

		public static function fromJSON(data:Object):IsLevelLessThanCommand {
			if (data == null)
				return null;
			var lvl:String = data.var1 != null ? String(data.var1) : (data.level != null ? String(data.level) : "100");
			return new IsLevelLessThanCommand(lvl);
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
			var targetLvl:int = parseInt(var1);
			if (isNaN(targetLvl))
				return false;
			return bot.getLevel() < targetLvl;
		}

		override public function toString():String {
			return commandLabel + " [" + var1 + "]";
		}
	}
}
