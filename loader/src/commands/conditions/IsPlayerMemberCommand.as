package commands.conditions {

	import commands.BotCommand;
	import engine.BotEngine;

	/**
	 * Conditional command to verify if player has active membership (upgrade).
	 * var1: "" (empty/null)
	 * var2: "" (empty/null)
	 */
	public class IsPlayerMemberCommand extends BaseConditionalCommand {

		public static const COMMAND_LABEL:String = "If Player Member";
		public static const VAR1_LABEL:String = null;
		public static const VAR1_RESTRICT:String = null;
		public static const VAR1_DEFAULT:String = "";
		public static const VAR2_LABEL:String = null;
		public static const VAR2_RESTRICT:String = null;
		public static const VAR2_DEFAULT:String = "";

		public function IsPlayerMemberCommand() {
			super(BotCommand.TYPE_IS_PLAYER_MEMBER, "", "");
		}

		public static function fromJSON(data:Object):IsPlayerMemberCommand {
			return new IsPlayerMemberCommand();
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
			return bot.isPlayerMember();
		}

		override public function toString():String {
			return "If " + commandLabel;
		}
	}
}
