package commands {

	import engine.BotEngine;

	public class GetMapItemCommand extends BotCommand {

		public var itemId:int;

		public function GetMapItemCommand(itemId:* = 0) {
			super(BotCommand.TYPE_GET_MAP_ITEM);
			this.itemId = int(itemId);
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"itemId": itemId
				};
		}

		public static function fromJSON(data:Object):GetMapItemCommand {
			if (data == null)
				return null;
			return new GetMapItemCommand(int(data.itemId || 0));
		}

		override public function execute(bot:BotEngine):void {
			var game:Object = bot.getGame();
			try {
				if (game != null && game.world != null && itemId > 0) {
					if (game.world.getMapItem != null) {
						game.world.getMapItem(itemId);
					}
					else if (game.world.rootClass != null && game.world.rootClass.sfc != null) {
						game.world.rootClass.sfc.sendXtMessage("zm", "getMapItem", [itemId], "str");
					}
					bot.log("Get Map Item [" + itemId + "]");
				}
			}
			catch (e:Error) {
				bot.log("[MapItem] Error: " + e.message);
			}
			bot.advanceStep(500);
		}

		override public function toString():String {
			return "Get Map Item [" + itemId + "]";
		}
	}
}
