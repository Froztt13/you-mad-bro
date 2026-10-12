package commands {

	import engine.BotEngine;
	import Utils;

	public class BuyItemCommand extends BotCommand {

		public var itemName:String = "";
		public var shopId:int = 0;
		public var qty:int = 1;

		public function BuyItemCommand(itemName:String = "", shopId:* = 0, qty:* = 1) {
			super(BotCommand.TYPE_BUY_ITEM);
			this.itemName = (itemName != null) ? Utils.trim(itemName) : "";
			this.shopId = int(shopId);
			var qVal:int = int(qty);
			this.qty = (qVal > 0) ? qVal : 1;
		}

		override public function toJSON():Object {
			return {
					"type": type,
					"itemName": itemName,
					"shopId": shopId,
					"qty": qty
				};
		}

		public static function fromJSON(data:Object):BuyItemCommand {
			if (data == null)
				return null;
			return new BuyItemCommand(
					String(data.itemName || ""),
					int(data.shopId || 0),
					int(data.qty || 1)
				);
		}

		override public function execute(bot:BotEngine):void {
			var game:Object = bot.getGame();
			if (game == null || game.world == null || itemName == null || itemName.length == 0) {
				bot.advanceStep();
				return;
			}

			try {
				// 1. If shopId specified and not loaded, request shop load
				if (shopId > 0) {
					if (game.world.shopinfo == null || game.world.shopinfo.ShopID != shopId) {
						if (game.world.sendLoadShopRequest != null) {
							game.world.sendLoadShopRequest(shopId);
							bot.log("[Buy] Loading shop [" + shopId + "]...");
							bot.advanceStep(800);
							return;
						}
					}
				}

				// 2. Locate item in current loaded shop (game.world.shopinfo.items)
				if (game.world.shopinfo != null && game.world.shopinfo.items != null) {
					var cleanName:String = Utils.cleanItemName(itemName);
					var targetItem:Object = null;
					for each (var itm:Object in game.world.shopinfo.items) {
						if (itm != null && itm.sName != null && String(itm.sName).toLowerCase() == cleanName) {
							targetItem = itm;
							break;
						}
					}

					if (targetItem != null) {
						if (qty > 1 && game.world.sendBuyItemRequestWithQuantity != null) {
							var buyObj:Object = {
								accept: 1,
								iQty: qty,
								iSel: targetItem
							};
							game.world.sendBuyItemRequestWithQuantity(buyObj);
							bot.log("[Buy] Bought " + qty + "x [" + itemName + "]");
						}
						else if (game.world.sendBuyItemRequest != null) {
							game.world.sendBuyItemRequest(targetItem);
							bot.log("[Buy] Bought [" + itemName + "]");
						}
						else if (game.world.rootClass != null && game.world.rootClass.sfc != null) {
							game.world.rootClass.sfc.sendXtMessage("zm", "buyItem", [targetItem.ShopItemID, targetItem.ItemID, qty], "str");
							bot.log("[Buy] Bought [" + itemName + "]");
						}
					}
					else {
						bot.log("[Buy] Item [" + itemName + "] not found in loaded shop");
					}
				}
				else {
					bot.log("[Buy] Shop info is not loaded yet");
				}
			}
			catch (e:Error) {
				bot.log("[Buy] Error: " + e.message);
			}
			bot.advanceStep(500);
		}

		override public function toString():String {
			var detail:String = "";
			if (qty > 1) {
				detail += " x" + qty;
			}
			if (shopId > 0) {
				detail += " (Shop: " + shopId + ")";
			}
			return "Buy [" + itemName + detail + "]";
		}
	}
}
