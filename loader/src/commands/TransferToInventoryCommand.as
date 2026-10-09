package commands {
	import engine.BotEngine;

	public class TransferToInventoryCommand extends BotCommand {
		public var itemName:String = "";

		public function TransferToInventoryCommand(itemName:String = "") {
			super(BotCommand.TYPE_TRANSFER_TO_INVENTORY);
			this.itemName = itemName;
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"itemName": itemName
				};
		}

		public static function fromJSON(data:Object):TransferToInventoryCommand {
			if (data == null)
				return null;
			return new TransferToInventoryCommand(String(data.itemName || ""));
		}

		override public function execute(bot:BotEngine):void {
			var game:Object = bot.getGame();
			try {
				if (game != null && game.world != null && itemName != null && itemName.length > 0) {
					var item:Object = bot.getBankItemByName(itemName);
					if (item != null) {
						game.world.sendBankToInvRequest(item);
						bot.log("Transferred [" + itemName + "] to Inventory");
					}
					else {
						bot.log("Item [" + itemName + "] not found in Bank");
					}
				}
			}
			catch (e:Error) {
			}
			bot.advanceStep(500);
		}

		override public function toString():String {
			return "To Inv [" + itemName + "]";
		}
	}
}
