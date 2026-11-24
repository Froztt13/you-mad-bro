package commands.conditions {

	import commands.BotCommand;
	import engine.AutoBattle;
	import engine.BotEngine;
	import Utils;

	/**
	 * Conditional command to verify if player aura value is greater than target.
	 * var1: auraName
	 * var2: value
	 */
	public class IsPlayerAuraGreaterThanCommand extends BaseConditionalCommand {

		public static const COMMAND_LABEL:String = "If Player Aura Greater Than";
		public static const VAR1_LABEL:String = "Aura Name:";
		public static const VAR1_RESTRICT:String = null;
		public static const VAR1_DEFAULT:String = "";
		public static const VAR2_LABEL:String = "Value:";
		public static const VAR2_RESTRICT:String = "0-9";
		public static const VAR2_DEFAULT:String = "0";

		public function IsPlayerAuraGreaterThanCommand(auraName:String = "", val:* = 0) {
			var vStr:String = (val != null && String(val).length > 0) ? Utils.trim(String(val)) : "0";
			super(BotCommand.TYPE_IS_PLAYER_AURA_GREATER, (auraName != null) ? Utils.trim(auraName) : "", vStr);
		}

		public static function fromJSON(data:Object):IsPlayerAuraGreaterThanCommand {
			if (data == null)
				return null;
			var name:String = data.var1 != null ? String(data.var1) : "";
			var v:String = data.var2 != null ? String(data.var2) : "0";
			return new IsPlayerAuraGreaterThanCommand(name, v);
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
			var targetVal:int = parseInt(var2);
			if (isNaN(targetVal)) {
				targetVal = 0;
			}
			return AutoBattle.getAurasValue(bot.getGame(), true, var1) > targetVal;
		}

		override public function toString():String {
			return commandLabel + " [" + var1 + " > " + var2 + "]";
		}
	}
}
