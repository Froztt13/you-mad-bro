package commands {

	import flash.utils.setTimeout;
	import engine.BotEngine;

	public class GetMapItemCommand extends BotCommand {

		public var itemId:int;
		public var qty:int;

		public function GetMapItemCommand(itemId:* = 0, qty:* = 1) {
			super(BotCommand.TYPE_GET_MAP_ITEM);
			this.itemId = int(itemId);
			var qVal:int = int(qty);
			this.qty = (qVal > 0) ? qVal : 1;
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"itemId": itemId,
					"qty": qty
				};
		}

		public static function fromJSON(data:Object):GetMapItemCommand {
			if (data == null)
				return null;
			return new GetMapItemCommand(
					int(data.itemId || 0),
					int(data.qty || 1)
				);
		}

		override public function execute(bot:BotEngine):void {
			var game:Object = bot.getGame();
			if (game == null || game.world == null || itemId <= 0) {
				bot.advanceStep();
				return;
			}

			var totalQty:int = (qty > 0) ? qty : 1;
			var count:int = 0;

			var grabOne:Function = function():void {
				if (!bot.isRunning)
					return;

				try {
					if (game.world.getMapItem != null) {
						game.world.getMapItem(itemId);
					}
					else if (game.world.rootClass != null && game.world.rootClass.sfc != null) {
						game.world.rootClass.sfc.sendXtMessage("zm", "getMapItem", [itemId], "str");
					}
					count++;
					if (totalQty > 1) {
						bot.log("Get Map Item [" + itemId + "] (" + count + "/" + totalQty + ")");
					}
					else {
						bot.log("Get Map Item [" + itemId + "]");
					}
				}
				catch (e:Error) {
					bot.log("[MapItem] Error: " + e.message);
				}

				if (count >= totalQty) {
					bot.advanceStep(500);
				}
				else {
					setTimeout(grabOne, 1050);
				}
			};

			grabOne();
		}

		override public function toString():String {
			if (qty > 1) {
				return "Get Map Item [" + itemId + "] (x" + qty + ")";
			}
			return "Get Map Item [" + itemId + "]";
		}
	}
}
