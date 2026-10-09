package handler {

	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import engine.BotEngine;
	import SFSEvent;
	import Utils;
	import Config;
	import com.aqw.battery.BatteryOptimizer;

	public class ItemDropsHandler {

		private var game:Object;
		private var botEngine:BotEngine;
		private var _isAttached:Boolean = false;
		private var attachTimer:Timer;

		public function ItemDropsHandler(game:Object = null, botEngine:BotEngine = null) {
			this.game = game;
			this.botEngine = (botEngine != null) ? botEngine : BotEngine.instance;

			attachListener();
			if (!_isAttached) {
				startRetryTimer();
			}
		}

		public function setGame(game:Object):void {
			if (this.game == game)
				return;
			detachListener();
			this.game = game;
			attachListener();
			if (!_isAttached) {
				startRetryTimer();
			}
		}

		public function setBotEngine(botEngine:BotEngine):void {
			this.botEngine = botEngine;
		}

		public function attachListener():void {
			if (_isAttached)
				return;
			if (game != null && "sfc" in game && game.sfc != null) {
				try {
					game.sfc.addEventListener(SFSEvent.onDebugMessage, onPacketReceived, false, 0, true);
					_isAttached = true;
					if (attachTimer != null) {
						attachTimer.stop();
						attachTimer = null;
					}
				}
				catch (e:Error) {
				}
			}
		}

		private function startRetryTimer():void {
			if (attachTimer != null)
				return;
			attachTimer = new Timer(1000, 30);
			attachTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
					attachListener();
				});
			attachTimer.start();
		}

		public function detachListener():void {
			if (attachTimer != null) {
				attachTimer.stop();
				attachTimer = null;
			}
			if (_isAttached && game != null && "sfc" in game && game.sfc != null) {
				try {
					game.sfc.removeEventListener(SFSEvent.onDebugMessage, onPacketReceived);
				}
				catch (e:Error) {
				}
			}
			_isAttached = false;
		}

		public function onPacketReceived(packet:*):void {
			if (packet == null || packet.params == null || packet.params.message == null)
				return;
			var msg:String = packet.params.message;
			var serverMsg:String = Utils.normalizePacket(msg);
			handleServerResponse(serverMsg);
		}

		public function handleServerResponse(serverMsg:String):void {
			var bot:BotEngine = (botEngine != null) ? botEngine : BotEngine.instance;
			if (bot == null)
				return;

			try {
				if (serverMsg.indexOf("{") == 0) {
					var data:Object = JSON.parse(serverMsg);
					if (data && data.b && data.b.o) {
						var obj:Object = data.b.o;
						if (obj.cmd == "dropItem" && obj.items != null) {
							for (var itemId:* in obj.items) {
								var dropInfo:Object = obj.items[itemId];
								var dropName:String = (dropInfo != null && dropInfo.sName != null) ? dropInfo.sName : "";
								if (bot.hasWhitelistItem(dropName)) {
									bot.log("Auto accepting drop: " + dropName + " (ID: " + itemId + ")");
									bot.pickupDrop(parseInt(itemId));
									if (Config.isAndroid && bot.notifyItemDrops) {
										try {
											BatteryOptimizer.sendNotification("Item Obtained!", dropName, 2002);
										}
										catch (eDropNotif:Error) {
										}
									}
								}
							}
						}
					}
				}
			}
			catch (e:Error) {
			}
		}
	}
}
