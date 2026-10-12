package commands {

	import engine.BotEngine;
	import Utils;

	public class EquipItemCommand extends BotCommand {

		public var itemName:String = "";

		public function EquipItemCommand(itemName:String = "") {
			super(BotCommand.TYPE_EQUIP_ITEM);
			this.itemName = (itemName != null) ? Utils.trim(itemName) : "";
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"itemName": itemName
				};
		}

		public static function fromJSON(data:Object):EquipItemCommand {
			if (data == null)
				return null;
			return new EquipItemCommand(String(data.itemName || ""));
		}

		override public function execute(bot:BotEngine):void {
			var game:Object = bot.getGame();
			try {
				if (game != null && game.world != null && itemName != null && itemName.length > 0) {
					var item:Object = bot.getInventoryItemByName(itemName);
					if (item != null) {
						if (game.world.sendEquipItemRequest != null) {
							game.world.sendEquipItemRequest(item);
						}
						else if (game.world.rootClass != null && game.world.rootClass.sfc != null && item.ItemID != null) {
							game.world.rootClass.sfc.sendXtMessage("zm", "equipItem", [item.ItemID], "str");
						}
						bot.log("Equipped [" + itemName + "]");
					}
					else {
						bot.log("Item [" + itemName + "] not found in Inventory to equip");
					}
				}
			}
			catch (e:Error) {
				bot.log("[Equip] Error: " + e.message);
			}
			bot.advanceStep(500);
		}

		override public function toString():String {
			return "Equip [" + itemName + "]";
		}
	}
}
