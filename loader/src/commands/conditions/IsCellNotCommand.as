package commands.conditions {

	import commands.BotCommand;
	import engine.BotEngine;
	import Utils;

	/**
	 * Conditional command to verify if current cell does NOT match the specified cell name.
	 * var1: cell
	 * var2: "" (empty/null)
	 */
	public class IsCellNotCommand extends BaseConditionalCommand {

		public static const COMMAND_LABEL:String = "If Cell Is Not";
		public static const VAR1_LABEL:String = "Cell:";
		public static const VAR1_RESTRICT:String = null;
		public static const VAR1_DEFAULT:String = "Enter";
		public static const VAR2_LABEL:String = null;
		public static const VAR2_RESTRICT:String = null;
		public static const VAR2_DEFAULT:String = "";

		public function IsCellNotCommand(cell:String = "Enter") {
			var cStr:String = (cell != null) ? Utils.trim(cell) : "Enter";
			super(BotCommand.TYPE_IS_CELL_NOT, cStr, "");
		}

		public static function fromJSON(data:Object):IsCellNotCommand {
			if (data == null)
				return null;
			var cName:String = data.var1 != null ? String(data.var1) : (data.cell != null ? String(data.cell) : "Enter");
			return new IsCellNotCommand(cName);
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
			return !bot.isCurrentCell(var1);
		}

		override public function toString():String {
			return commandLabel + " [" + var1 + "]";
		}
	}
}
