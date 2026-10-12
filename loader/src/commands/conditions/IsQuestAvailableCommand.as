package commands.conditions {

	import commands.BotCommand;
	import engine.BotEngine;
	import Utils;

	/**
	 * Conditional command to verify if a quest is available to accept/complete.
	 * var1: questId
	 * var2: "" (empty/null)
	 */
	public class IsQuestAvailableCommand extends BaseConditionalCommand {

		public static const COMMAND_LABEL:String = "If Quest Available";
		public static const VAR1_LABEL:String = "Quest ID:";
		public static const VAR1_RESTRICT:String = "0-9";
		public static const VAR1_DEFAULT:String = "";
		public static const VAR2_LABEL:String = null;
		public static const VAR2_RESTRICT:String = null;
		public static const VAR2_DEFAULT:String = "";

		public function IsQuestAvailableCommand(questId:* = 0) {
			var qStr:String = (questId != null) ? Utils.trim(String(questId)) : "";
			super(BotCommand.TYPE_IS_QUEST_AVAILABLE, qStr, "");
		}

		public static function fromJSON(data:Object):IsQuestAvailableCommand {
			if (data == null)
				return null;
			var qId:String = data.var1 != null ? String(data.var1) : (data.questId != null ? String(data.questId) : "");
			return new IsQuestAvailableCommand(qId);
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
			if (var1 == null || var1.length == 0)
				return false;
			var qId:int = parseInt(var1);
			if (isNaN(qId) || qId <= 0)
				return false;
			return bot.isQuestAvailable(qId);
		}

		override public function toString():String {
			return commandLabel + " [" + var1 + "]";
		}
	}
}
