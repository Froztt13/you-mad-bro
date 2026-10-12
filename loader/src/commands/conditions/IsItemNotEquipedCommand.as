package commands.conditions {

	import commands.BotCommand;
	import engine.BotEngine;
	import Utils;

	/**
	 * Conditional command to verify if an item is NOT currently equipped.
	 * var1: itemName
	 * var2: "" (empty/null)
	 */
	public class IsItemNotEquipedCommand extends BaseConditionalCommand {

		public static const COMMAND_LABEL:String = "If Item Not Equiped";
		public static const VAR1_LABEL:String = "Item Name:";
		public static const VAR1_RESTRICT:String = null;
		public static const VAR1_DEFAULT:String = "";
		public static const VAR2_LABEL:String = null;
		public static const VAR2_RESTRICT:String = null;
		public static const VAR2_DEFAULT:String = "";

		public function IsItemNotEquipedCommand(itemName:String = "") {
			super(BotCommand.TYPE_IS_ITEM_NOT_EQUIPED, (itemName != null) ? Utils.trim(itemName) : "", "");
		}

		public static function fromJSON(data:Object):IsItemNotEquipedCommand {
			if (data == null)
				return null;
			var name:String = data.var1 != null ? String(data.var1) : (data.itemName != null ? String(data.itemName) : "");
			return new IsItemNotEquipedCommand(name);
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
			if (bot == null || var1 == null || var1.length == 0) {
				return false;
			}
			return !bot.isItemEquipped(var1);
		}

		override public function toString():String {
			return commandLabel + " (" + var1 + ")";
		}
	}
}
