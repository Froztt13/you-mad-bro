package commands.conditions {

	import commands.BotCommand;
	import engine.BotEngine;

	/**
	 * Conditional command to verify if the player does NOT have an active membership / upgrade.
	 */
	public class IsPlayerNotMemberCommand extends BaseConditionalCommand {

		public static const COMMAND_LABEL:String = "If Player Is Not Member";
		public static const VAR1_LABEL:String = null;
		public static const VAR1_RESTRICT:String = null;
		public static const VAR1_DEFAULT:String = "";
		public static const VAR2_LABEL:String = null;
		public static const VAR2_RESTRICT:String = null;
		public static const VAR2_DEFAULT:String = "";

		public function IsPlayerNotMemberCommand() {
			super(BotCommand.TYPE_IS_PLAYER_NOT_MEMBER, "", "");
		}

		public static function fromJSON(data:Object):IsPlayerNotMemberCommand {
			if (data == null)
				return null;
			return new IsPlayerNotMemberCommand();
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
			if (bot == null)
				return false;
			return !bot.isPlayerMember();
		}

		override public function toString():String {
			return commandLabel;
		}
	}
}
