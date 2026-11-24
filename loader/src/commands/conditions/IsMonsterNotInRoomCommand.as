package commands.conditions {

	import commands.BotCommand;
	import engine.BotEngine;
	import Utils;

	/**
	 * Conditional command to verify if a monster is NOT alive in the current cell.
	 * var1: monsterName (or "*")
	 */
	public class IsMonsterNotInRoomCommand extends BaseConditionalCommand {

		public static const COMMAND_LABEL:String = "If Monster Not In Room";
		public static const VAR1_LABEL:String = "Monster Name:";
		public static const VAR1_RESTRICT:String = null;
		public static const VAR1_DEFAULT:String = "*";
		public static const VAR2_LABEL:String = null;
		public static const VAR2_RESTRICT:String = null;
		public static const VAR2_DEFAULT:String = "";

		public function IsMonsterNotInRoomCommand(monsterName:String = "*") {
			var mStr:String = (monsterName != null && Utils.trim(monsterName).length > 0) ? Utils.trim(monsterName) : "*";
			super(BotCommand.TYPE_IS_MONSTER_NOT_IN_ROOM, mStr, "");
		}

		public static function fromJSON(data:Object):IsMonsterNotInRoomCommand {
			if (data == null)
				return null;
			var name:String = data.var1 != null ? String(data.var1) : (data.monster != null ? String(data.monster) : "*");
			return new IsMonsterNotInRoomCommand(name);
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
			return !bot.isMonsterInRoom(var1);
		}

		override public function toString():String {
			return commandLabel + " [" + var1 + "]";
		}
	}
}
