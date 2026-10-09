package commands {
	import engine.BotEngine;

	public class TransferToBankCommand extends BotCommand {
		public var itemName:String = "";

		public function TransferToBankCommand(itemName:String = "") {
			super(BotCommand.TYPE_TRANSFER_TO_BANK);
			this.itemName = itemName;
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"itemName": itemName
				};
		}

		public static function fromJSON(data:Object):TransferToBankCommand {
			if (data == null)
				return null;
			return new TransferToBankCommand(String(data.itemName || ""));
		}

		override public function execute(bot:BotEngine):void {
			var game:Object = bot.getGame();
			try {
				if (game != null && game.world != null && itemName != null && itemName.length > 0) {
					var item:Object = bot.getInventoryItemByName(itemName);
					if (item != null) {
						game.world.sendBankFromInvRequest(item);
						bot.log("Transferred [" + itemName + "] to Bank");
					}
					else {
						bot.log("Item [" + itemName + "] not found in Inventory");
					}
				}
			}
			catch (e:Error) {
			}
			bot.advanceStep(500);
		}

		override public function toString():String {
			return "To Bank [" + itemName + "]";
		}
	}
}
