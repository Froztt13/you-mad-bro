package commands {

	import engine.BotEngine;
	import Utils;

	public class SellItemCommand extends BotCommand {

		public var itemName:String = "";

		public function SellItemCommand(itemName:String = "") {
			super(BotCommand.TYPE_SELL_ITEM);
			this.itemName = (itemName != null) ? Utils.trim(itemName) : "";
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"itemName": itemName
				};
		}

		public static function fromJSON(data:Object):SellItemCommand {
			if (data == null)
				return null;
			return new SellItemCommand(String(data.itemName || ""));
		}

		override public function execute(bot:BotEngine):void {
			var game:Object = bot.getGame();
			try {
				if (game != null && game.world != null && itemName != null && itemName.length > 0) {
					var item:Object = bot.getInventoryItemByName(itemName);
					if (item != null) {
						game.world.sendSellItemRequest(item);
						bot.log("Sold [" + itemName + "]");
					}
					else {
						bot.log("Item [" + itemName + "] not found in Inventory to sell");
					}
				}
			}
			catch (e:Error) {
				bot.log("[Sell] Error: " + e.message);
			}
			bot.advanceStep(500);
		}

		override public function toString():String {
			return "Sell [" + itemName + "]";
		}
	}
}
