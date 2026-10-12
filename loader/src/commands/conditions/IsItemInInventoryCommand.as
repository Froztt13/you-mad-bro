package commands.conditions {

	import commands.BotCommand;
	import engine.BotEngine;
	import Utils;

	/**
	 * Conditional command to verify if an item is present in inventory (or temp inventory) with required quantity.
	 * var1: itemName
	 * var2: qty
	 */
	public class IsItemInInventoryCommand extends BaseConditionalCommand {

		public static const COMMAND_LABEL:String = "If Item In Inventory";
		public static const VAR1_LABEL:String = "Item Name:";
		public static const VAR1_RESTRICT:String = null;
		public static const VAR1_DEFAULT:String = "";
		public static const VAR2_LABEL:String = "Qty:";
		public static const VAR2_RESTRICT:String = "0-9";
		public static const VAR2_DEFAULT:String = "1";

		public function IsItemInInventoryCommand(itemName:String = "", qty:* = 1) {
			var qStr:String = (qty != null && String(qty).length > 0) ? String(qty) : "1";
			super(BotCommand.TYPE_IS_ITEM_IN_INV, (itemName != null) ? Utils.trim(itemName) : "", qStr);
		}

		public static function fromJSON(data:Object):IsItemInInventoryCommand {
			if (data == null)
				return null;
			var name:String = data.var1 != null ? String(data.var1) : (data.itemName != null ? String(data.itemName) : "");
			var q:String = data.var2 != null ? String(data.var2) : (data.qty != null ? String(data.qty) : "1");
			return new IsItemInInventoryCommand(name, q);
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
			var targetQty:int = parseInt(var2);
			if (isNaN(targetQty) || targetQty <= 0) {
				targetQty = 1;
			}
			return bot.getItemQuantity(var1) >= targetQty;
		}

		override public function toString():String {
			var targetQty:int = parseInt(var2);
			if (isNaN(targetQty) || targetQty <= 0) {
				targetQty = 1;
			}
			return commandLabel + " [" + var1 + " >= " + targetQty + "]";
		}
	}
}
