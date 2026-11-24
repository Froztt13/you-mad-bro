package commands.conditions {

	import commands.BotCommand;
	import engine.BotEngine;
	import Utils;

	/**
	 * Conditional command to verify if player's MP is less than the specified amount.
	 * var1: amount
	 */
	public class IsManaLessThanCommand extends BaseConditionalCommand {

		public static const COMMAND_LABEL:String = "If Mana Less Than";
		public static const VAR1_LABEL:String = "MP Amount:";
		public static const VAR1_RESTRICT:String = "0-9";
		public static const VAR1_DEFAULT:String = "50";
		public static const VAR2_LABEL:String = null;
		public static const VAR2_RESTRICT:String = null;
		public static const VAR2_DEFAULT:String = "";

		public function IsManaLessThanCommand(amount:* = 50) {
			var aStr:String = (amount != null) ? Utils.trim(String(amount)) : "50";
			super(BotCommand.TYPE_IS_MANA_LESS, aStr, "");
		}

		public static function fromJSON(data:Object):IsManaLessThanCommand {
			if (data == null)
				return null;
			var amt:String = data.var1 != null ? String(data.var1) : (data.amount != null ? String(data.amount) : "50");
			return new IsManaLessThanCommand(amt);
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
			var targetMp:int = parseInt(var1);
			if (isNaN(targetMp))
				return false;
			return bot.getMana() < targetMp;
		}

		override public function toString():String {
			return commandLabel + " [" + var1 + "]";
		}
	}
}
